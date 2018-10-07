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

   Sample_Size : constant Integer;
   pragma Import (Asm, Sample_Size, "_sample_size");

   Sample_Data : constant array (0 .. 128 * 1024) of Mono_Sample;
   pragma Import (Asm, Sample_Data, "_sample");

   type Sampler_Generator is new Generator with record
      Allocated : Boolean := False;
      Index     : Float := Float (Sample_Size);
      Pitch     : Float := 1.0;
   end record;

   overriding
   procedure Next_Samples (Self : in out Sampler_Generator);

   overriding
   procedure Reset (Self : in out Sampler_Generator);

   overriding
   function Children (Self : in out Sampler_Generator) return Generator_Array
   is (1 .. 0 => <>);

   subtype Poly is Natural range 0 .. 6;

   Samplers      : array (Poly) of aliased Sampler_Generator;
   Notes         : array (Poly) of Note_T;
   Levels        : array (Poly) of Float := (others => 0.0);
   Triggers_On   : array (Poly) of Boolean := (others => False);
   Triggers_Off  : array (Poly) of Boolean := (others => False);

   ADSR_Trig : array (Poly) of aliased Dummy_Note_Generator
     := (others => (Buffer => (others => (No_Note, No_Signal))));
   ADSRs : constant array (Poly) of not null access ADSR :=
     (Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (0)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (1)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (2)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (3)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (4)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (5)'Access),
      Create_ADSR (Attack  => 0, Decay   => 500, Release => 3000, Sustain => 0.3,
                   Source  => ADSR_Trig (6)'Access));

   function Create_Voice (Note_Source : Generator_Access;
                          Env         : access ADSR)
                          return Generator_Access;
   function Create_Voice (Note_Source : Generator_Access;
                          Env         : access ADSR)
                          return Generator_Access
   is (Create_Mixer (Sources => (1 => (Gen => Note_Source,
                                       Level => 1.0)),
                     Env => Env
                    )
      );

   Mix : constant access Mixer :=
     Create_Mixer
       (Sources =>
          (
             1 => (Create_Voice (Samplers (0)'Access, ADSRs (0)), Level => 0.0)
           , 2 => (Create_Voice (Samplers (1)'Access, ADSRs (1)), Level => 0.0)
           , 3 => (Create_Voice (Samplers (2)'Access, ADSRs (2)), Level => 0.0)
           , 4 => (Create_Voice (Samplers (3)'Access, ADSRs (3)), Level => 0.0)
           , 5 => (Create_Voice (Samplers (4)'Access, ADSRs (4)), Level => 0.0)
           , 6 => (Create_Voice (Samplers (5)'Access, ADSRs (5)), Level => 0.0)
           , 7 => (Create_Voice (Samplers (6)'Access, ADSRs (6)), Level => 0.0)
          )
       );

   overriding
   procedure Next_Samples (Self : in out Sampler_Generator) is
   begin
      if Integer (Self.Index) < Sample_Size then
         for Elt of Self.Buffer loop
            if Integer (Self.Index) in 0 .. Sample_Size - 1 then
               Elt := Float (Int16_To_Sample (Sample_Data (Integer (Self.Index))));
            else
               Elt := Float (Int16_To_Sample (Sample_Data (0)));
            end if;
            Self.Index := Self.Index + Self.Pitch;
         end loop;

         if Integer (Self.Index) > Sample_Size - 1 then
            Self.Allocated := False;
            Self.Index := Float (Sample_Size);
         end if;
      else
         for Elt of Self.Buffer loop
            Elt := 0.0;
         end loop;
      end if;
   end Next_Samples;

   overriding
   procedure Reset (Self : in out Sampler_Generator) is
   begin
      Self.Index := Float (Sample_Size);
      Self.Pitch := 1.0;
   end Reset;

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
      Octave : constant Float := (case (Integer (Data) / 12) is
                                     when 0      => 0.0625,
                                     when 1      => 0.125,
                                     when 2      => 0.25,
                                     when 3      => 0.5,
                                     when 4      => 1.0,
                                     when 5      => 2.0,
                                     when 6      => 4.0,
                                     when 7      => 8.0,
                                     when 8      => 16.0,
                                     when 9      => 32.0,
                                     when others => 64.0);
      Note : constant Float := (case Data mod 12 is
                                   when 0      => 1.0,
                                   when 1      => 1.059463,
                                   when 2      => 1.122462,
                                   when 3      => 1.189207,
                                   when 4      => 1.259921,
                                   when 5      => 1.334840,
                                   when 6      => 1.414214,
                                   when 7      => 1.498307,
                                   when 8      => 1.587401,
                                   when 9      => 1.681793,
                                   when 10     => 1.781797,
                                   when others => 1.887749);
   begin
      for Index in Poly loop
         --  Find a free oscillator
         if not Samplers (Index).Allocated then
            Samplers (Index).Allocated := True;
            Samplers (Index).Index := 0.0;
            Samplers (Index).Pitch := Octave * Note;

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
         if Samplers (Index).Allocated and then Notes (Index) = Note then

            Samplers (Index).Allocated := False;

            --  Kill the oscilator
            Triggers_Off (Index) := True;
         end if;
      end loop;
   end Off;

end Sound_Generator;
