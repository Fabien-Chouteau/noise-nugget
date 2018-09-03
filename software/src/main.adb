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

with Ada.Real_Time; use Ada.Real_Time;

with WNM;               use WNM;
with WNM.Master_Volume;
with WNM.Buttons;
with WNM.LED;
with Quick_Synth;

procedure Main is

begin
   Quick_Synth.Note_Up;
   WNM.Master_Volume.Set (100);
   loop
      WNM.Buttons.Scan;

--        if WNM.Buttons.Is_Pressed (Vp) then
--           WNM.Master_Volume.Change (1);
--        end if;
--
--        if WNM.Buttons.Is_Pressed (Vm) then
--           WNM.Master_Volume.Change (-1);
--        end if;

      if WNM.Buttons.Is_Pressed (A) then
         Quick_Synth.Effects_On;
         WNM.LED.Turn_On;
      else
         Quick_Synth.Effects_Off;
         WNM.LED.Turn_Off;
      end if;

--        if WNM.Buttons.Is_Pressed (C) then
--           Quick_Synth.Note_Up;
--        end if;
--
--        if WNM.Buttons.Is_Pressed (D) then
--           Quick_Synth.Note_Down;
--        end if;

      WNM.Master_Volume.Update;
      delay until Clock + Milliseconds (100);
   end loop;
end Main;
