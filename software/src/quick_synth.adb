-------------------------------------------------------------------------------
--                                                                           --
--                              Wee Noise Maker                              --
--                                                                           --
--                  Copyright (C) 2016-2017 Fabien Chouteau                  --
--                                                                           --
--    Wee Noise Maker is free software: you can redistribute it and/or       --
--    modify it under the terms of the GNU General Public License as         --
--    published by the Free Software Foundation, either version 3 of the     --
--    License, or (at your option) any later version.                        --
--                                                                           --
--    Wee Noise Maker is distributed in the hope that it will be useful,     --
--    but WITHOUT ANY WARRANTY; without even the implied warranty of         --
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU       --
--    General Public License for more details.                               --
--                                                                           --
--    You should have received a copy of the GNU General Public License      --
--    along with We Noise Maker. If not, see <http://www.gnu.org/licenses/>. --
--                                                                           --
-------------------------------------------------------------------------------

with HAL.Audio;                  use HAL.Audio;
with HAL;                        use HAL;
with Managed_Buffers;            use Managed_Buffers;
with WNM;                        use WNM;
--  with WNM.Buffer_Allocation;      use WNM.Buffer_Allocation;
with Hex_Dump;
with Semihosting;

with Command; use Command;
with Effects; use Effects;
with Waves; use Waves;
with Utils; use Utils;
with Sound_Gen_Interfaces; use Sound_Gen_Interfaces;
with BLIT; use BLIT;

package body Quick_Synth is

   procedure Copy (Src : not null Any_Managed_Buffer;
                   Dst : out Mono_Buffer)
     with Unreferenced;
   procedure Copy_Stereo_To_Mono (Src : Stereo_Buffer;
                                  Dst : not null Any_Managed_Buffer)
     with Unreferenced;
   procedure Audio_Hex_Dump (Info : String;
                             Buffer : HAL.Audio.Audio_Buffer);
   pragma Unreferenced (Audio_Hex_Dump);

   Current_Note : Note_T := (C, 4);

   function Sample_To_Int16 is new Sample_To_Int (Mono_Sample);
   function Int16_To_Sample is new Int_To_Sample (Mono_Sample);

   type Static_Gen is new Generator with null record;

   overriding
   procedure Next_Samples (Self : in out Static_Gen) is null;

   overriding
   procedure Reset (Self : in out Static_Gen) is null;

   overriding
   function Children
     (Self : in out Static_Gen) return Generator_Array is
     (Generator_Arrays.Empty_Array);

   From_DAC_L : aliased Static_Gen;
   From_DAC_R : aliased Static_Gen;

--     Note_Gen : aliased Fixed_Note;

   ----------------------------------------------------------------------------
   BPM : constant := 200;
   SNL : constant Sample_Period := 4000;

   S1 : constant Sequencer_Note := ((C, 4), SNL);
   S2 : constant Sequencer_Note := ((F, 4), SNL);
   S3 : constant Sequencer_Note := ((D_Sh, 4), SNL);
   S4 : constant Sequencer_Note := ((A_Sh, 4), SNL);
   S5 : constant Sequencer_Note := ((G, 4), SNL);
   S6 : constant Sequencer_Note := ((D_Sh, 4), SNL);

   Synth_Seq : constant access Simple_Sequencer :=
     Create_Sequencer
       (8, BPM, 4,
        Notes =>
          (S1, S1, S1, S1, S1, S2, S2, S2,
           S3, S3, S3, S3, S3, S4, S4, S4,
           S1, S1, S1, S1, S1, S2, S2, S2,
           S5, S5, S5, S5, S5, S6, S6, S6));

   Synth_Source : constant Note_Generator_Access :=
     Note_Generator_Access (Synth_Seq);

   Synth : constant access Disto :=
     --  We distort the output signal of the synthetizer with a soft clipper
     Create_Dist
       (Clip_Level => 1.00001,
        Coeff      => 1.5,

        --  The oscillators of the synth are fed to an LP filter
        Source     => Create_LP
          (

           --  We use an ADSR enveloppe to modulate the Cut frequency of the
           --  filter. Using it as the modulator of a Fixed generator allows us
           --  to have a cut frequency that varies between 1700 hz and 200 hz.
           Cut_Freq =>
             Fixed
               (Freq      => 200.0,
                Modulator => new Attenuator'
                  (Level  => 1500.0,
                   Source => Create_ADSR (10, 150, 200, 0.005, Synth_Source),
                   others => <>)),

           --  Q is the resonance of the filter, very high values will give a
           --  resonant sound.
           Q => 0.2,

           --  This is the mixer, receiving the sound of 4 differently tuned
           --  oscillators, 1 sine and 3 saws
           Source =>
             Create_Mixer
               (Sources =>
                    (4 => (Create_Sine
                           (Create_Pitch_Gen
                              (Rel_Pitch => -30, Source => Synth_Source)),
                           Level => 0.6),
                     3 => (BLIT.Create_Saw
                           (Create_Pitch_Gen
                              (Rel_Pitch => -24, Source => Synth_Source)),
                           Level => 0.3),
                     2 => (BLIT.Create_Saw
                           (Create_Pitch_Gen
                              (Rel_Pitch => -12, Source => Synth_Source)),
                           Level => 0.3),
                     1 => (BLIT.Create_Saw
                           (Create_Pitch_Gen
                              (Rel_Pitch => -17, Source => Synth_Source)),
                           Level => 0.5)))));

   Input_Mono : constant access Mixer := Create_Mixer
     ((2 => (From_DAC_R'Access, 0.5),
       1 => (From_DAC_L'Access, 0.5)));

   Input_Disto : constant access Disto := Create_Dist (Source     => Input_Mono,
                                                       Clip_Level => 1.0,
                                                       Coeff      => 3.0);
   Main : constant access Mixer :=
     Create_Mixer ((2 => (Input_Disto,
                          Level => 0.0),
                    1 => (Synth, 1.0)));
   ----------------------------------------------------------------------------

   -------------
   -- Note_Up --
   -------------

   procedure Note_Up is
   begin
      if Current_Note.Octave < Octave_T'Last
        and then
          Current_Note.Scale_Degree < Scale_Degree_T'Last
      then
         if Current_Note.Scale_Degree = Scale_Degree_T'First then
            Current_Note.Octave := Current_Note.Octave + 1;
            Current_Note.Scale_Degree := Scale_Degree_T'First;
         else
            Current_Note.Scale_Degree := Scale_Degree_T'Succ (Current_Note.Scale_Degree);
         end if;

--           Note_Gen.Set_Note (Current_Note);
      end if;
   end Note_Up;

   ---------------
   -- Note_Down --
   ---------------

   procedure Note_Down is
   begin
      if Current_Note.Octave > Octave_T'First
        and then
          Current_Note.Scale_Degree > Scale_Degree_T'First
      then
         if Current_Note.Scale_Degree = Scale_Degree_T'First then
            Current_Note.Octave := Current_Note.Octave - 1;
            Current_Note.Scale_Degree := Scale_Degree_T'Last;
         else
            Current_Note.Scale_Degree := Scale_Degree_T'Pred (Current_Note.Scale_Degree);
         end if;

--           Note_Gen.Set_Note (Current_Note);
      end if;
   end Note_Down;

   --------------------
   -- Audio_Hex_Dump --
   --------------------

   procedure Audio_Hex_Dump (Info : String;
                             Buffer : HAL.Audio.Audio_Buffer)
   is
      Data : HAL.UInt8_Array (1 .. Buffer'Length / 2)
        with Address => Buffer'Address;
   begin
      Semihosting.Log_Line (Info);
      Hex_Dump.Hex_Dump (Data,
                         Put_Line  => Semihosting.Log_Line'Access,
                         Base_Addr => 0);
   end Audio_Hex_Dump;

   ----------
   -- Copy --
   ----------

   procedure Copy (Src : not null Any_Managed_Buffer;
                   Dst : out Mono_Buffer)
   is
      Data : Mono_Buffer with Address => Src.Buffer_Address;
   begin

      if Src.Buffer_Length /= Mono_Buffer_Size_In_Bytes then
         raise Program_Error with "WTF!?!";
      end if;

      Dst := Data;
   end Copy;

   -------------------------
   -- Copy_Stereo_To_Mono --
   -------------------------

   procedure Copy_Stereo_To_Mono (Src : Stereo_Buffer;
                                  Dst : not null Any_Managed_Buffer)
   is
      Data : Mono_Buffer with Address => Dst.Buffer_Address;
      Tmp  : Integer_32;
   begin

      if Dst.Buffer_Length /= Mono_Buffer_Size_In_Bytes then
         raise Program_Error with "WTF!?!";
      end if;

      for Index in Data'Range loop
         Tmp := Integer_32 (Src (Index).L) + Integer_32 (Src (Index).R);
         Tmp := Tmp / 2;

         if Tmp > Integer_32 (Mono_Sample'Last) then
            Data (Index) := Mono_Sample'Last;
         elsif Tmp < Integer_32 (Integer_16'First) then
            Data (Index) := Mono_Sample'First;
         else
            Data (Index) := Mono_Sample (Tmp);
         end if;
      end loop;
   end Copy_Stereo_To_Mono;

   ----------
   -- Fill --
   ----------

   procedure Fill (Stereo_Input  :     Stereo_Buffer;
                   Stereo_Output : out Stereo_Buffer)
   is

--        procedure Mix (Mono_Samples : Mono_Buffer;
--                       ST           : Stream_Track);
--
--        ---------
--        -- Mix --
--        ---------
--
--        procedure Mix (Mono_Samples : Mono_Buffer;
--                       ST           : Stream_Track)
--        is
--           Val         : Integer_32;
--
--           Sample, Left, Right : Float;
--
--           Volume       : Float := 1.0;
--           Pan          : Float := 1.0;
--        begin
--  --           Audio_Hex_Dump ("Stereo_Output before mix:", Stereo_Output);
--
--           for Index in Mono_Samples'Range loop
--
--              Sample := Float (Mono_Samples (Index));
--              Sample := Sample * Volume;
--
--              Right := Sample * (1.0 - Pan);
--              Left  := Sample * (1.0 + Pan);
--
--              Val := Integer_32 (Stereo_Output (Index).L) + Integer_32 (Left);
--              if Val > Integer_32 (Mono_Sample'Last) then
--                 Stereo_Output (Index).L := Mono_Sample'Last;
--              elsif Val < Integer_32 (Integer_16'First) then
--                 Stereo_Output (Index).L := Mono_Sample'First;
--              else
--                 Stereo_Output (Index).L := Mono_Sample (Val);
--              end if;
--
--              Val := Integer_32 (Stereo_Output (Index).R) + Integer_32 (Right);
--              if Val > Integer_32 (Mono_Sample'Last) then
--                 Stereo_Output (Index).R := Mono_Sample'Last;
--              elsif Val < Integer_32 (Integer_16'First) then
--                 Stereo_Output (Index).R := Mono_Sample'First;
--              else
--                 Stereo_Output (Index).R := Mono_Sample (Val);
--              end if;
--           end loop;
--  --           Audio_Hex_Dump ("Stereo_Output after mix:", Stereo_Output);
--        end Mix;
--        On_Track : Stream_Track;

--        Mono_Tmp : Mono_Buffer;
--        Buf      : Any_Managed_Buffer;

   begin
      for I in B_Range_T'Range loop
         From_DAC_R.Buffer (I) := Int16_To_Sample (Stereo_Input (Integer (I) + 1).R);
         From_DAC_L.Buffer (I) := Int16_To_Sample (Stereo_Input (Integer (I) + 1).L);
      end loop;

      Next_Steps;
      Main.Next_Samples;

      for I in B_Range_T'Range loop
         Stereo_Output (Integer (I) + 1).L := Sample_To_Int16 (Main.Buffer (I));
         Stereo_Output (Integer (I) + 1).R := Sample_To_Int16 (Main.Buffer (I));
      end loop;

      Sample_Nb := Sample_Nb + Generator_Buffer_Length;

   end Fill;

   ----------------
   -- Effects_On --
   ----------------

   procedure Effects_On is
   begin
      Input_Disto.Clip_Level := 1.00001;
   end Effects_On;

   -----------------
   -- Effects_Off --
   -----------------

   procedure Effects_Off is
   begin
      Input_Disto.Clip_Level := 1.0;
   end Effects_Off;

--     ------------------------------------------------------------------------
--        BPM   : Natural := 15;
--     Notes : constant Notes_Array :=
--       To_Seq_Notes ((C, G, F, G, C, G, F, A, C, G, F, G, C, G, F, G), 400, 4);
--
--     Volume     : Float   := 0.9;
--     Decay      : Integer := 800;
--     Seq        : access Simple_Sequencer;
--     Sine_Gen   : access Mixer;
--     Main       : constant access Mixer := Create_Mixer (No_Generators);
--
--     function Simple_Synth
--       (S    : Note_Generator_Access; Tune : Integer := 0; Decay : Integer)
--        return access Mixer;
--
--     function Simple_Synth
--       (S    : Note_Generator_Access; Tune : Integer := 0; Decay : Integer)
--        return access Mixer
--     is
--       (Create_Mixer
--          ((0 => (Create_Sine (Create_Pitch_Gen (Tune, S)), 0.5)),
--           Env => Create_ADSR (5, 50, Decay, 0.5, S)));
--  begin
--     for I in -3 .. 1 loop
--        Seq      := Create_Sequencer (16, BPM, 1, Notes);
--        Sine_Gen := Simple_Synth (Note_Generator_Access (Seq), I * 12, Decay);
--        Main.Add_Generator (Sine_Gen, Volume);
--        BPM    := BPM * 2;
--        Volume := Volume / 1.8;
--        Decay  := Decay / 2;
--     end loop;
--  ---------------------------------------------------------------------------
end Quick_Synth;
