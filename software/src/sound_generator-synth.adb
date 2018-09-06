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

with WNM;                        use WNM;

with Command; use Command;
with Effects; use Effects;
with Waves; use Waves;
with Utils; use Utils;
with Sound_Gen_Interfaces; use Sound_Gen_Interfaces;
with BLIT; use BLIT;

package body Sound_Generator is

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

   Main : constant access Disto :=
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

   ----------------------------------------------------------------------------

   ----------
   -- Fill --
   ----------

   procedure Fill (Stereo_Input  :     Stereo_Buffer;
                   Stereo_Output : out Stereo_Buffer)
   is
      pragma Unreferenced (Stereo_Input);
   begin

      Next_Steps;
      Main.Next_Samples;

      for I in B_Range_T'Range loop
         Stereo_Output (Integer (I) + 1).L := Sample_To_Int16 (Main.Buffer (I));
         Stereo_Output (Integer (I) + 1).R := Sample_To_Int16 (Main.Buffer (I));
      end loop;

      Sample_Nb := Sample_Nb + Generator_Buffer_Length;

   end Fill;

   --------
   -- On --
   --------

   procedure On is
   begin
      null;
   end On;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      null;
   end Off;

end Sound_Generator;
