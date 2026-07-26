with Ada.Directories;
with Ada.Text_IO;

package body Devcert.Locks is
   function Acquire (Path : String) return Lock_Result is
      File : Ada.Text_IO.File_Type;
   begin
      if Ada.Directories.Exists (Path) then
         return Already_Held;
      end if;

      declare
         Parent : constant String := Ada.Directories.Containing_Directory (Path);
      begin
         if Parent /= "" and then not Ada.Directories.Exists (Parent) then
            Ada.Directories.Create_Path (Parent);
         end if;
      end;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (File, "devcert lock");
      Ada.Text_IO.Close (File);
      return Acquired;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Already_Held;
   end Acquire;

   procedure Release (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Release;
end Devcert.Locks;
