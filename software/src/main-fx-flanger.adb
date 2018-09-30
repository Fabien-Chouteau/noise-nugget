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
with Sound_Generator;

with STM32_SVD.RCC; use STM32_SVD.RCC;
with STM32_SVD.USB_OTG_FS; use STM32_SVD.USB_OTG_FS;
with HAL; use HAL;

with STM32.Device; use STM32.Device;
with STM32.GPIO; use STM32.GPIO;
--  with Ada.Text_IO; use Ada.Text_IO;

procedure Main is

   Fx_On : Boolean := False;
   Wait_Release : Boolean := False;
begin
   Sound_Generator.Off (0);
   WNM.Master_Volume.Set (100);
   loop
      WNM.Buttons.Scan;

      if Wait_Release then

         if not WNM.Buttons.Is_Pressed (A) then
            Wait_Release := False;
         end if;
      elsif WNM.Buttons.Is_Pressed (A) then
         Fx_On := not Fx_On;
         Wait_Release := True;
      end if;

      if Fx_On then
         Sound_Generator.On (0);
         WNM.LED.Turn_On;
      else
         Sound_Generator.Off (0);
         WNM.LED.Turn_Off;
      end if;

      WNM.Master_Volume.Update;
      delay until Clock + Milliseconds (100);
   end loop;
end Main;
