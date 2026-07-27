with Ada.Command_Line;
with Ada.Directories;

with GNAT.OS_Lib;

with Devcert_Secure_Files;

package body Devcert_Test_Suite.Paths is
   use type GNAT.OS_Lib.String_Access;

   --  Path of the running executable. A bare program name is resolved through
   --  PATH, mirroring the runtime's own executable lookup.
   function Executable_Path return String is
      Name : constant String := Ada.Command_Line.Command_Name;
      Cut  : Natural := 0;
   begin
      for Index in reverse Name'Range loop
         if Name (Index) = '/' or else Name (Index) = '\' then
            Cut := Index;
            exit;
         end if;
      end loop;

      if Cut /= 0 then
         return Name;
      end if;

      declare
         Found : GNAT.OS_Lib.String_Access :=
           GNAT.OS_Lib.Locate_Exec_On_Path (Name);
      begin
         if Found = null then
            return Name;
         end if;

         declare
            Result : constant String := Found.all;
         begin
            GNAT.OS_Lib.Free (Found);
            return Result;
         end;
      end;
   end Executable_Path;

   --  The suite is built as <root>/devcert_tests/bin/devcert_tests, so the
   --  repository root is two directories above the executable's directory.
   function Resolve_Root return String is
      Executable : constant String :=
        Ada.Directories.Full_Name (Executable_Path);
      Bin        : constant String :=
        Ada.Directories.Containing_Directory (Executable);
      Crate      : constant String :=
        Ada.Directories.Containing_Directory (Bin);
   begin
      return Ada.Directories.Containing_Directory (Crate);
   end Resolve_Root;

   Root : constant String := Resolve_Root;

   function Repository_Root return String is
   begin
      return Root;
   end Repository_Root;

   function In_Repository (Relative : String) return String is
   begin
      return Root & "/" & Relative;
   end In_Repository;

   function Devcert_Executable return String is
   begin
      return In_Repository ("bin/devcert");
   end Devcert_Executable;

   function Scratch (Name : String) return String is
   begin
      return Devcert_Secure_Files.Temp_Directory & "/" & Name;
   end Scratch;
end Devcert_Test_Suite.Paths;
