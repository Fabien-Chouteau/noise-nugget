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

--  with Ada.Text_IO; use Ada.Text_IO;
--  with Hex_Dump;

--  with Ada.Real_Time; use Ada.Real_Time;
--
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
with USB;
with USB.Device.MIDI;

with DWC_OTG_FS;

procedure Main is

   package DWC_OTG is new DWC_OTG_FS (16#50000000#);
   use DWC_OTG;

   Fx_On : Boolean := False;
   Wait_Release : Boolean := False;

   UDC   : aliased OTG_USB_Device;
   Dev   : USB.USB_Device;
   Class_MIDI : aliased USB.Device.MIDI.Default_MIDI_Class;

   Desc : aliased constant USB.Device_Descriptor :=
     (
      bLength            => USB.Device_Descriptor'Size / 8,
      bDescriptorType    => 1, -- DT_DEVICE
      bcdUSB             => 16#0200#,
      bDeviceClass       => 0,
      bDeviceSubClass    => 0,
      bDeviceProtocol    => 0,
      bMaxPacketSize0    => 64,
      idVendor           => 16#6666#,
      idProduct          => 16#4242#,
      bcdDevice          => 16#0100#,
      iManufacturer      => 1,
      iProduct           => 2,
      iSerialNumber      => 3,
      bNumConfigurations => 1
     );

   LANG_EN_US : constant USB.USB_String := (ASCII.HT, ASCII.EOT); -- 0x0409

   Strings : aliased constant USB.String_Array :=
     (
      (0, new USB.String_Descriptor'(2 + 2,  3, LANG_EN_US)),
      (1, new USB.String_Descriptor'(2 + 32, 3,
       ('T', ASCII.NUL,
        'h', ASCII.NUL,
        'e', ASCII.NUL,
        ' ', ASCII.NUL,
        'N', ASCII.NUL,
        'o', ASCII.NUL,
        'i', ASCII.NUL,
        's', ASCII.NUL,
        'e', ASCII.NUL,
        ' ', ASCII.NUL,
        'M', ASCII.NUL,
        'a', ASCII.NUL,
        'k', ASCII.NUL,
        'e', ASCII.NUL,
        'r', ASCII.NUL,
        's', ASCII.NUL))),
      (2, new USB.String_Descriptor'(2 + 24, 3,
       ('N', ASCII.NUL,
        'o', ASCII.NUL,
        'i', ASCII.NUL,
        's', ASCII.NUL,
        'e', ASCII.NUL,
        ' ', ASCII.NUL,
        'N', ASCII.NUL,
        'u', ASCII.NUL,
        'g', ASCII.NUL,
        'g', ASCII.NUL,
        'e', ASCII.NUL,
        't', ASCII.NUL))),
      (3, new USB.String_Descriptor'(2 + 8, 3,
       ('v', ASCII.NUL,
        '0', ASCII.NUL,
        '.', ASCII.NUL,
        '1', ASCII.NUL)))
     );


   USB_DESC_TYPE_CONFIGURATION : constant := 2;
--     USB_HID_CONFIG_DESC_SIZ     : constant := 34;
--     USB_DESC_TYPE_STRING        : constant := 3;
   USB_DESC_TYPE_INTERFACE     : constant := 4;
   USB_DESC_TYPE_ENDPOINT      : constant := 5;
--     HID_DESCRIPTOR_TYPE         : constant := 16#21#;
--     HID_REPORT_DESC             : constant := 16#22#;
--     USB_HID_DESC_SIZ            : constant := 9;
--     HID_MOUSE_REPORT_DESC_SIZE  : constant := 74;
--     HID_EPIN_ADDR               : constant := 16#81#;
--     HID_EPIN_SIZE               : constant := 16#04#;
--     HID_FS_BINTERVAL            : constant := 16#0A#;

   USB_CFG_MAX_BUS_POWER : constant := 2;

   Config_MIDI : aliased constant UInt8_Array :=
     (
      --  USB configuration descriptor */
      9, --  sizeof(usbDescrConfig): length of descriptor in bytes */
      USB_DESC_TYPE_CONFIGURATION, --  descriptor type */
      101, 0, --  total length of data returned (including inlined descriptors) */
      2, --  number of interfaces in this configuration */
      1, --  index of this configuration */
      0, --  configuration name string index */
      Shift_Left (1, 7), --  attributes */
      USB_CFG_MAX_BUS_POWER / 2, --  max USB current in 2mA units */

      --  B.3 AudioControl Interface Descriptors
      --  The AudioControl interface describes the device structure (audio function topology)
      --  and is used to manipulate the Audio Controls. This device has no audio function
      --  incorporated. However, the AudioControl interface is mandatory and therefore both
      --  the standard AC interface descriptor and the classspecific AC interface descriptor
      --  must be present. The class-specific AC interface descriptor only contains the header
      --  descriptor.

      --  B.3.1 Standard AC Interface Descriptor
      --  The AudioControl interface has no dedicated endpoints associated with it. It uses the
      --  default pipe (endpoint 0) for all communication purposes. Class-specific AudioControl
      --  Requests are sent using the default pipe. There is no Status Interrupt endpoint provided.
      --  descriptor follows inline: */
      9, --  sizeof(usbDescrInterface): length of descriptor in bytes */
      USB_DESC_TYPE_INTERFACE, --  descriptor type */
      0, --  index of this interface */
      0, --  alternate setting for this interface */
      0, --  endpoints excl 0: number of endpoint descriptors to follow */
      1, --  */
      1, --  */
      0, --  */
      0, --  string index for interface */

      --  B.3.2 Class-specific AC Interface Descriptor
      --  The Class-specific AC interface descriptor is always headed by a Header descriptor
      --  that contains general information about the AudioControl interface. It contains all
      --  the pointers needed to describe the Audio Interface Collection, associated with the
      --  described audio function. Only the Header descriptor is present in this device
      --  because it does not contain any audio functionality as such.
      --  descriptor follows inline: */
      9, --  sizeof(usbDescrCDC_HeaderFn): length of descriptor in bytes */
      36, --  descriptor type */
      1, --  header functional descriptor */
      0, 0, --  bcdADC */
      9, 0, --  wTotalLength */
      1, --  */
      1, --  */

      --  B.4 MIDIStreaming Interface Descriptors

      --  B.4.1 Standard MS Interface Descriptor
      --  descriptor follows inline: */
      9, --  length of descriptor in bytes */
      USB_DESC_TYPE_INTERFACE, --  descriptor type */
      1, --  index of this interface */
      0, --  alternate setting for this interface */
      2, --  endpoints excl 0: number of endpoint descriptors to follow */
      1, --  AUDIO */
      3, --  MS */
      0, --  unused */
      0, --  string index for interface */

      --  B.4.2 Class-specific MS Interface Descriptor
      --  descriptor follows inline: */
      7, --  length of descriptor in bytes */
      36, --  descriptor type */
      1, --  header functional descriptor */
      0, 1, --  bcdADC */
      65, 0, --  wTotalLength */

      --  B.4.3 MIDI IN Jack Descriptor
      --  descriptor follows inline: */
      6, --  bLength */
      36, --  descriptor type */
      2, --  MIDI_IN_JACK desc subtype */
      1, --  EMBEDDED bJackType */
      1, --  bJackID */
      0, --  iJack */

      --  descriptor follows inline: */
      6, --  bLength */
      36, --  descriptor type */
      2, --  MIDI_IN_JACK desc subtype */
      2, --  EXTERNAL bJackType */
      2, --  bJackID */
      0, --  iJack */

      --  B.4.4 MIDI OUT Jack Descriptor
      --  descriptor follows inline: */
      9, --  length of descriptor in bytes */
      36, --  descriptor type */
      3, --  MIDI_OUT_JACK descriptor */
      1, --  EMBEDDED bJackType */
      3, --  bJackID */
      1, --  No of input pins */
      2, --  BaSourceID */
      1, --  BaSourcePin */
      0, --  iJack */

      --  descriptor follows inline: */
      9, --  bLength of descriptor in bytes */
      36, --  bDescriptorType */
      3, --  MIDI_OUT_JACK bDescriptorSubtype */
      2, --  EXTERNAL bJackType */
      4, --  bJackID */
      1, --  bNrInputPins */
      1, --  baSourceID (0) */
      1, --  baSourcePin (0) */
      0, --  iJack */

      --  B.5 Bulk OUT Endpoint Descriptors

      --  B.5.1 Standard Bulk OUT Endpoint Descriptor
      --  descriptor follows inline: */
      9, --  bLenght */
      USB_DESC_TYPE_ENDPOINT, --  bDescriptorType = endpoint */
      1, --  bEndpointAddress OUT endpoint number 1 */
      3, --  bmAttributes: 2:Bulk, 3:Interrupt endpoint */
      8, 0, --  wMaxPacketSize */
      10, --  bInterval in ms */
      0, --  bRefresh */
      0, --  bSyncAddress */

      --  B.5.2 Class-specific MS Bulk OUT Endpoint Descriptor
      --  descriptor follows inline: */
      5, --  bLength of descriptor in bytes */
      37, --  bDescriptorType */
      1, --  bDescriptorSubtype */
      1, --  bNumEmbMIDIJack  */
      1, --  baAssocJackID (0) */

      --  B.6 Bulk IN Endpoint Descriptors

      --  B.6.1 Standard Bulk IN Endpoint Descriptor
      --  descriptor follows inline: */
      9, --  bLenght */
      USB_DESC_TYPE_ENDPOINT, --  bDescriptorType = endpoint */
      16#81#, --  bEndpointAddress IN endpoint number 1 */
      3, --  bmAttributes: 2: Bulk, 3: Interrupt endpoint */
      8, 0, --  wMaxPacketSize */
      10, --  bInterval in ms */
      0, --  bRefresh */
      0, --  bSyncAddress */

      --  B.6.2 Class-specific MS Bulk IN Endpoint Descriptor
      --  descriptor follows inline: */
      5, --  bLength of descriptor in bytes */
      37, --  bDescriptorType */
      1, --  bDescriptorSubtype */
      1 --  bNumEmbMIDIJack (0) */
     );
begin

   Enable_Clock (PA11);
   Enable_Clock (PA12);
   Enable_Clock (PA9);

   Configure_IO (PA9,
                 (Mode      => Mode_In,
                  Resistors => Floating));

   Configure_IO (PA11 & PA12,
                 (Mode     => Mode_AF,
                  Resistors => Floating,
                  AF_Output_Type => Push_Pull,
                  AF_Speed => Speed_Very_High,
                  AF => GPIO_AF_OTG_FS_10));


   RCC_Periph.AHB2ENR.OTGFSEN := True;

   Dev.Initalize (UDC'Unchecked_Access,
                  Class_MIDI'Unchecked_Access,
                  Desc'Unchecked_Access,
                  Config_MIDI'Unchecked_Access,
                  Strings'Unchecked_Access);

   Dev.Start;

   WNM.Master_Volume.Set (70);
   WNM.Master_Volume.Update;
   loop
      Dev.Poll;
      while Class_MIDI.Ready loop
         declare
            Data : constant UInt8_Array := Class_MIDI.Last;
         begin
--              Hex_Dump.Hex_Dump (Data, Ada.Text_IO.Put_Line'Access);

            if Data (2) = 16#90# and then Data (4) /= 0 then
               Sound_Generator.On (Data (3));
            elsif Data (2) = 16#80#
              or else
                (Data (2) = 16#90# and then Data (4) = 0)
            then
               Sound_Generator.Off (Data (3));
            end if;
         end;
      end loop;

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
--           Sound_Generator.On;
         WNM.LED.Turn_On;
      else
--           Sound_Generator.Off;
         WNM.LED.Turn_Off;
      end if;

--      WNM.Master_Volume.Update;
--        delay until Clock + Milliseconds (100);
   end loop;
end Main;
