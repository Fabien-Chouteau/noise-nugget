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

with STM32.GPIO;   use STM32.GPIO;
with STM32.Device; use STM32.Device;
with HAL;          use HAL;

package body WNM.LED is

   Point : GPIO_Point renames PA15;

   procedure Start;

   -----------
   -- Start --
   -----------

   procedure Start is
      Config : constant GPIO_Port_Configuration := (Mode        => Mode_Out,
                                                    Output_Type => Push_Pull,
                                                    Resistors   => Floating,
                                                    Speed       => Speed_Low);
   begin

      Enable_Clock (Point);
      Point.Configure_IO (Config);
      Turn_Off;
   end Start;

   -------------
   -- Turn_On --
   -------------

   procedure Turn_On is
   begin
      Point.Clear;
   end Turn_On;

   --------------
   -- Turn_Off --
   --------------

   procedure Turn_Off is
   begin
      Point.Set;
   end Turn_Off;

   ------------
   -- Toggle --
   ------------

   procedure Toggle is
   begin
      Point.Toggle;
   end Toggle;

begin
   Start;
end WNM.LED;
