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

with WNM;
with Interfaces;         use Interfaces;

package Quick_Synth is

   type Mono_Sample is new Integer_16 with Size => 16;
   type Stereo_Sample is record
      L, R : Mono_Sample;
   end record with Pack, Size => 32;

   type Mono_Buffer is array (1 .. WNM.Samples_Per_Buffer) of Mono_Sample
     with Pack, Size => WNM.Mono_Buffer_Size_In_Bytes * 8;

   type Stereo_Buffer is array (1 .. WNM.Samples_Per_Buffer) of Stereo_Sample
     with Pack, Size => WNM.Stereo_Buffer_Size_In_Bytes * 8;

   procedure Fill (Stereo_Input  :     Stereo_Buffer;
                   Stereo_Output : out Stereo_Buffer);

   procedure Note_Up;

   procedure Note_Down;

   procedure Effects_On;
   procedure Effects_Off;

end Quick_Synth;
