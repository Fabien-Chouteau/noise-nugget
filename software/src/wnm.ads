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
with System;

package WNM is

   type Button is (A);

   type Trigger is (None, Always, Percent_25, Percent_50, Percent_75);

   Steps_Per_Beat      : constant := 4;
   Max_Events_Per_Step : constant := 6;

   DAC_Task_Priority       : constant System.Priority := System.Default_Priority + 10;
   Synth_Task_Priority     : constant System.Priority := DAC_Task_Priority - 1;
   Sample_Task_Priority    : constant System.Priority := Synth_Task_Priority - 1;
   Sequencer_Task_Priority : constant System.Priority := Sample_Task_Priority - 1;
   UI_Task_Priority        : constant System.Priority := Sequencer_Task_Priority - 1;
   LED_Task_Priority       : constant System.Priority := UI_Task_Priority - 1;

   UI_Task_Period               : constant Time_Span := Milliseconds (50);
   UI_Task_Stack_Size           : constant := 10 * 1024;
   UI_Task_Secondary_Stack_Size : constant := 5 * 1024;

   Sequencer_Task_Stack_Size           : constant := 10 * 1024;
   Sequencer_Task_Secondary_Stack_Size : constant := 5 * 1024;

   Sample_Taks_Stack_Size       : constant := 10 * 1024;

   LED_Task_Period   : constant Time_Span := Microseconds (1000);

   Long_Press_Time_Span : constant Time_Span := Milliseconds (300);
   --  How much time users have to press a button to get the alternative
   --  function.

   Samples_Per_Buffer          : constant := 512;
   Mono_Buffer_Size_In_Bytes   : constant := Samples_Per_Buffer * 2;
   Stereo_Buffer_Size_In_Bytes : constant := Samples_Per_Buffer * 4;


   Sample_Rec_Filepath : constant String := "/sdcard/sample_rec.raw";
end WNM;
