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

package body WNM.Buttons is

   Key_To_Address : constant array (Button) of not null access GPIO_Point :=
     (A  => PA0'Access);
--        B  => PC13'Access,
--        C  => PC14'Access,
--        D  => PC15'Access,
--        Vp => PA1'Access,
--        Vm => PC5'Access);

   Wakeup : GPIO_Point renames PA0;

   Key_State : array (Button) of Raw_Button_State := (others => Up);

   procedure Initialize;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Config_In  : GPIO_Port_Configuration :=
        (Mode      => Mode_In,
         Resistors => Pull_Up);
   begin

      for Pt of Key_To_Address loop
         Enable_Clock (Pt.all);
         Pt.Configure_IO (Config_In);
      end loop;

      Enable_Clock (Wakeup);
      Config_In.Resistors := Floating;
      Wakeup.Configure_IO (Config_In);
   end Initialize;

   ----------
   -- Scan --
   ----------

   procedure Scan is
   begin
      Key_State (A) := (if Wakeup.Set then Down else Up);
   end Scan;

   -----------
   -- State --
   -----------

   function State (B : Button) return Raw_Button_State
   is (Key_State (B));

   ----------------
   -- Is_Pressed --
   ----------------

   function Is_Pressed (B : Button) return Boolean
   is (Key_State (B) = Down);

begin
   Initialize;
end WNM.Buttons;
