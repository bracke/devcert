with GNAT.OS_Lib;

package body Devcert.Processes is
   use type GNAT.OS_Lib.String_Access;

   function Locate (Name : String) return String is
      Found : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Name);
   begin
      if Found = null then
         return "";
      else
         declare
            Result : constant String := Found.all;
         begin
            GNAT.OS_Lib.Free (Found);
            return Result;
         end;
      end if;
   end Locate;
end Devcert.Processes;
