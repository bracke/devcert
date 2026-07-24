with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

with GNAT.OS_Lib;

package body Devcert_Secure_Files is
   use type Ada.Streams.Stream_Element_Offset;

   function Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   end Exists;

   function Read (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : String (1 .. Natural (Ada.Directories.Size (Path)));
      Last   : Natural := 0;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Last /= 0 then
               Last := Last + 1;
               Result (Last) := ASCII.LF;
            end if;
            Result (Last + 1 .. Last + Line'Length) := Line;
            Last := Last + Line'Length;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return Result (1 .. Last);
   end Read;

   procedure Atomic_Write
     (Path    : String;
      Content : String;
      Secret  : Boolean := False) is
      File     : Ada.Text_IO.File_Type;
      Temp     : constant String := Path & ".tmp";
      Dir_Name : constant String := Ada.Directories.Containing_Directory (Path);
      Success  : Boolean;
   begin
      if Dir_Name /= "" and then not Ada.Directories.Exists (Dir_Name) then
         Ada.Directories.Create_Path (Dir_Name);
      end if;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Temp);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);

      if Secret then
         GNAT.OS_Lib.Spawn
           ("/bin/chmod", [new String'("600"), new String'(Temp)], Success);
      else
         GNAT.OS_Lib.Spawn
           ("/bin/chmod", [new String'("644"), new String'(Temp)], Success);
      end if;

      Ada.Directories.Rename (Temp, Path);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         if Ada.Directories.Exists (Temp) then
            Ada.Directories.Delete_File (Temp);
         end if;
         raise;
   end Atomic_Write;

   procedure Atomic_Write_Raw
     (Path    : String;
      Content : String;
      Secret  : Boolean := False) is
      File     : Ada.Streams.Stream_IO.File_Type;
      Temp     : constant String := Path & ".tmp";
      Dir_Name : constant String := Ada.Directories.Containing_Directory (Path);
      Data     : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Content'Length));
      Pos      : Ada.Streams.Stream_Element_Offset := Data'First;
      Success  : Boolean;
   begin
      if Dir_Name /= "" and then not Ada.Directories.Exists (Dir_Name) then
         Ada.Directories.Create_Path (Dir_Name);
      end if;

      for C of Content loop
         Data (Pos) := Ada.Streams.Stream_Element (Character'Pos (C));
         Pos := Pos + Ada.Streams.Stream_Element_Offset (1);
      end loop;

      Ada.Streams.Stream_IO.Create (File, Ada.Streams.Stream_IO.Out_File, Temp);
      Ada.Streams.Stream_IO.Write (File, Data);
      Ada.Streams.Stream_IO.Close (File);

      if Secret then
         GNAT.OS_Lib.Spawn
           ("/bin/chmod", [new String'("600"), new String'(Temp)], Success);
      else
         GNAT.OS_Lib.Spawn
           ("/bin/chmod", [new String'("644"), new String'(Temp)], Success);
      end if;

      Ada.Directories.Rename (Temp, Path);
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         if Ada.Directories.Exists (Temp) then
            Ada.Directories.Delete_File (Temp);
         end if;
         raise;
   end Atomic_Write_Raw;
end Devcert_Secure_Files;
