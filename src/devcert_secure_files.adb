with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Hostkit.Fs;

package body Devcert_Secure_Files is
   use type Ada.Streams.Stream_Element_Offset;
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

   --  Owner-only is the case with a security invariant behind it, and hostkit applies
   --  it with chmod(2): no PATH to search, and an answer as to whether it took. Every
   --  other mode here widens a path -- a certificate meant to be world-readable, a test
   --  loosening a directory -- which carries no invariant and has no hostkit
   --  equivalent, so it stays a best-effort spawn. Nothing is exposed by failing to
   --  widen; that is exactly the asymmetry this split is for.
   procedure Set_Permissions (Path : String; Mode : String) is
      Owner_Only : constant Boolean := Mode = "600" or else Mode = "700";

      --  Hostkit calls chmod(2) itself: no PATH to search, and an answer as to whether
      --  it took. It declines on a host with no mode bits, which leaves the spawn
      --  below to try and, there, to find no chmod either -- devcert is then no worse
      --  off than before, and CA_Store reports an exposed CA on its own rather than
      --  taking the writing of a mode as evidence that one holds.
      Applied : constant Boolean := Owner_Only and then Hostkit.Fs.Make_Private (Path);

      --  The other modes widen a path -- a certificate meant to be world-readable, a
      --  test loosening a directory. No security invariant rides on those, and nothing
      --  is exposed by failing to widen, so a best-effort spawn is the right weight.
      Chmod   : constant String := (if Applied then "" else Locate ("chmod"));
      Success : Boolean := False;
   begin
      if Chmod /= "" then
         GNAT.OS_Lib.Spawn
           (Chmod, [new String'(Mode), new String'(Path)], Success);
      end if;
   end Set_Permissions;

   procedure Ensure_Directory
     (Path : String;
      Mode : String := "700") is
   begin
      if Path /= "" and then not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Path (Path);
      end if;
      if Path /= "" then
         Set_Permissions (Path, Mode);
      end if;
   end Ensure_Directory;

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

   --  Best-effort expected-mode reading: `stat -c %a` is GNU syntax, so this
   --  answers on Linux and returns "" elsewhere (BSD stat wants -f %Lp, Windows
   --  has no stat at all). Callers must treat "" as "unknown", never as "safe";
   --  the security invariant is Accessible_By_Others, which asks the host.
   function Permissions (Path : String) return String is
      Stat        : constant String := Locate ("stat");
      Output_File : constant String := Path & ".mode";

      function Ask (Flag : String; Format : String) return String is
         Spawned     : Boolean := False;
         Return_Code : Integer := 1;
      begin
         GNAT.OS_Lib.Spawn
           (Stat,
            [new String'(Flag), new String'(Format), new String'(Path)],
            Output_File,
            Spawned,
            Return_Code,
            Err_To_Out => True);
         if Spawned and then Return_Code = 0
           and then Ada.Directories.Exists (Output_File)
         then
            declare
               Result : constant String := Read (Output_File);
            begin
               Ada.Directories.Delete_File (Output_File);
               return Result;
            end;
         end if;

         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         return "";
      end Ask;
   begin
      if Stat = "" or else not Ada.Directories.Exists (Path) then
         return "";
      end if;

      --  `-c %a` is GNU coreutils; BSD stat, as on macOS, rejects it and spells
      --  the same question `-f %Lp`. The command exists on both, so the wrong
      --  form fails as a non-zero exit rather than as a missing tool -- which is
      --  why this read silently answered nothing on macOS until now.
      declare
         GNU : constant String := Ask ("-c", "%a");
      begin
         if GNU /= "" then
            return GNU;
         end if;
      end;
      return Ask ("-f", "%Lp");
   end Permissions;

   function Has_Permissions (Path : String; Mode : String) return Boolean is
      Actual : constant String := Permissions (Path);
   begin
      return Actual = "" or else Actual = Mode;
   end Has_Permissions;

   function Accessible_By_Others (Path : String) return Boolean is
   begin
      return Hostkit.Fs.Accessible_By_Others (Path);
   end Accessible_By_Others;

   function Directory_Accessible_By_Others (Path : String) return Boolean is
   begin
      return Hostkit.Fs.Directory_Accessible_By_Others (Path);
   end Directory_Accessible_By_Others;

   function Temp_Directory return String is
   begin
      return Hostkit.Fs.Temp_Directory;
   end Temp_Directory;

   procedure Atomic_Write
     (Path    : String;
      Content : String;
      Secret  : Boolean := False) is
      File     : Ada.Text_IO.File_Type;
      Temp     : constant String := Path & ".tmp";
      Dir_Name : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      if Dir_Name /= "" and then not Ada.Directories.Exists (Dir_Name) then
         Ensure_Directory (Dir_Name, "700");
      end if;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Temp);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);

      Set_Permissions (Temp, (if Secret then "600" else "644"));

      --  Replacing rename: rename(2) on POSIX, MoveFileEx with
      --  MOVEFILE_REPLACE_EXISTING on Windows. Deleting Path first and renaming
      --  over the gap is not atomic -- an interrupted write left no file at all.
      if not Hostkit.Fs.Replace_File (Temp, Path) then
         raise Ada.IO_Exceptions.Use_Error with "could not replace " & Path;
      end if;
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
   begin
      if Dir_Name /= "" and then not Ada.Directories.Exists (Dir_Name) then
         Ensure_Directory (Dir_Name, "700");
      end if;

      for C of Content loop
         Data (Pos) := Ada.Streams.Stream_Element (Character'Pos (C));
         Pos := Pos + Ada.Streams.Stream_Element_Offset (1);
      end loop;

      Ada.Streams.Stream_IO.Create (File, Ada.Streams.Stream_IO.Out_File, Temp);
      Ada.Streams.Stream_IO.Write (File, Data);
      Ada.Streams.Stream_IO.Close (File);

      Set_Permissions (Temp, (if Secret then "600" else "644"));

      --  Replacing rename: rename(2) on POSIX, MoveFileEx with
      --  MOVEFILE_REPLACE_EXISTING on Windows. Deleting Path first and renaming
      --  over the gap is not atomic -- an interrupted write left no file at all.
      if not Hostkit.Fs.Replace_File (Temp, Path) then
         raise Ada.IO_Exceptions.Use_Error with "could not replace " & Path;
      end if;
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
