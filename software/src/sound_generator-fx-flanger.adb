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

with HAL; use HAL;

package body Sound_Generator is

   type Buffer_Index is mod 256;

   Buffers : array (Buffer_Index) of Stereo_Sample;

   Head : Buffer_Index := Buffer_Index'First;

   FX_On : Boolean := False;

   LFO : Buffer_Index := 0;
   LFO_Going_Up : Boolean := True;
   Frame_Cnt : UInt32 := 0;

   ----------
   -- Fill --
   ----------

   procedure Fill (Stereo_Input  :     Stereo_Buffer;
                   Stereo_Output : out Stereo_Buffer)
   is


   begin

      if FX_On then
         for Index in Stereo_Buffer'Range loop

            Buffers (Head) := Stereo_Input (Index);
            Head := Head + 1;

            Stereo_Output (Index).L := Stereo_Input (Index).L + Buffers (Head + LFO).L;
            Stereo_Output (Index).R := Stereo_Input (Index).R + Buffers (Head + LFO).R;


            --  Quick and dirty triangle LFO
            if Frame_Cnt mod (44100 / UInt32 (Buffer_Index'Last)) = 0 then

               if LFO_Going_Up then
                  LFO := LFO + 1;
                  if LFO = Buffer_Index'Last then
                     LFO_Going_Up := False;
                  end if;
               else
                  LFO := LFO - 1;
                  if LFO = Buffer_Index'First then
                     LFO_Going_Up := False;
                  end if;

               end if;

            end if;
            Frame_Cnt := Frame_Cnt + 1;

         end loop;

      else
         Stereo_Output := Stereo_Input;
      end if;

   end Fill;

   --------
   -- On --
   --------

   procedure On is
   begin
      FX_On := True;
   end On;

   ---------
   -- Off --
   ---------

   procedure Off is
   begin
      FX_On := False;
   end Off;

end Sound_Generator;
