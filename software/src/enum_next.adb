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

package body Enum_Next is

   ----------
   -- Next --
   ----------

   function Next (Elt : T) return T is
   begin
      if Elt = T'Last then
         return T'First;
      else
         return T'Succ (Elt);
      end if;
   end Next;

   ----------
   -- Prev --
   ----------

   function Prev (Elt : T) return T is
   begin
      if Elt = T'First then
         return T'Last;
      else
         return T'Pred (Elt);
      end if;
   end Prev;

end Enum_Next;
