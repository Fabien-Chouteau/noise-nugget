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

with WNM;                  use WNM;

with Effects;              use Effects;
with Waves;                use Waves;
with Utils;                use Utils;
with Sound_Gen_Interfaces; use Sound_Gen_Interfaces;
with Sequencer;            use Sequencer;

package body Sound_Generator is

   subtype Poly is Natural range 0 .. 4;

   Synth_Sources : array (Poly) of aliased Fixed_Note;
   Notes         : array (Poly) of Note_T;
   Levels        : array (Poly) of Float := (others => 0.0);
   Allocated     : array (Poly) of Boolean := (others => False);
   Triggers_On   : array (Poly) of Boolean := (others => False);
   Triggers_Off  : array (Poly) of Boolean := (others => False);

   ADSR_Trig : array (Poly) of aliased Dummy_Note_Generator
     := (others => (Buffer => (others => (No_Note, No_Signal))));
   ADSRs : constant array (Poly) of not null access ADSR :=
     (Create_ADSR (Attack  => 30, Decay   => 1000, Release => 100, Sustain => 0.1,
                   Source  => ADSR_Trig (0)'Access),
      Create_ADSR (Attack  => 30, Decay   => 1000, Release => 100, Sustain => 0.1,
                   Source  => ADSR_Trig (1)'Access),
      Create_ADSR (Attack  => 30, Decay   => 1000, Release => 100, Sustain => 0.1,
                   Source  => ADSR_Trig (2)'Access),
      Create_ADSR (Attack  => 30, Decay   => 1000, Release => 100, Sustain => 0.1,
                   Source  => ADSR_Trig (3)'Access),
      Create_ADSR (Attack  => 30, Decay   => 1000, Release => 100, Sustain => 0.1,
                   Source  => ADSR_Trig (4)'Access));

   function Create_Voice (Note_Source : access Fixed_Note;
                          Env         : access ADSR)
                          return Generator_Access;
   function Create_Voice (Note_Source : access Fixed_Note;
                          Env         : access ADSR)
                          return Generator_Access
   is (Create_Mixer (Sources => (1 => (Gen => Create_Saw (Create_Pitch_Gen (Rel_Pitch => 0, Source => Note_Source)),
                                       Level => 1.0)),
                     Env => Env
                    )
      );

   Mix : constant access Mixer :=
     Create_Mixer
       (Sources =>
          (
             1 => (Create_Voice (Synth_Sources (0)'Access, ADSRs (0)), Level => 0.0)
           , 2 => (Create_Voice (Synth_Sources (1)'Access, ADSRs (1)), Level => 0.0)
           , 3 => (Create_Voice (Synth_Sources (2)'Access, ADSRs (2)), Level => 0.0)
           , 4 => (Create_Voice (Synth_Sources (3)'Access, ADSRs (3)), Level => 0.0)
           , 5 => (Create_Voice (Synth_Sources (4)'Access, ADSRs (4)), Level => 0.0)
          )
       );


   ----------
   -- Fill --
   ----------

   procedure Fill (Stereo_Input  :     Stereo_Buffer;
                   Stereo_Output : out Stereo_Buffer)
   is
      pragma Unreferenced (Stereo_Input);
   begin

      --  Update synths
      for Index in Poly loop
         if Triggers_On (Index) then
            Triggers_On (Index) := False;
            ADSR_Trig (Index).Buffer (0) := (Notes (Index), On);
         elsif Triggers_Off (Index) then
            Triggers_Off (Index) := False;
            ADSR_Trig (Index).Buffer (0) := (Notes (Index), Off);
         else
            ADSR_Trig (Index).Buffer (0) := (Notes (Index), No_Signal);
         end if;
         Mix.Generators (Index).Level := Levels (Index);
         Synth_Sources (Index).Set_Note (Notes (Index));
      end loop;

      Next_Steps;
      Mix.Next_Samples;

      for I in B_Range_T'Range loop
         Stereo_Output (Integer (I) + 1).L := Sample_To_Int16 (Mix.Buffer (I));
         Stereo_Output (Integer (I) + 1).R := Sample_To_Int16 (Mix.Buffer (I));
      end loop;

      Sample_Nb := Sample_Nb + Generator_Buffer_Length;

   end Fill;

   function To_Note (Data : UInt8) return Note_T
   is ((case Data mod 12 is
           when 0 => C,
           when 1 => C_Sh,
           when 2 => D,
           when 3 => D_Sh,
           when 4 => E,
           when 5 => F,
           when 6 => F_Sh,
           when 7 => G,
           when 8 => G_Sh,
           when 9 => A,
           when 10 => A_Sh,
           when others => B),
       Octave_T ((Integer (Data) / 12) - 1));

   --------
   -- On --
   --------

   procedure On (Data : UInt8) is
   begin
      for Index in Poly loop
         --  Find a free oscillator
         if not Allocated (Index) and then ADSRs (Index).State = Off then
            Allocated (Index) := True;
            Notes (Index) := To_Note (Data);
            Triggers_On (Index) := True;
            Levels (Index) := 0.2;
            return;
         end if;
      end loop;
   end On;

   ---------
   -- Off --
   ---------

   procedure Off (Data : UInt8) is
      Note : constant Note_T := To_Note (Data);
   begin
      for Index in Poly loop
         --  Find an oscillator playing this note
         if Allocated (Index) and then Notes (Index) = Note then

            Allocated (Index) := False;

            --  Kill the oscilator
            Triggers_Off (Index) := True;
         end if;
      end loop;
   end Off;

end Sound_Generator;
