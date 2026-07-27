with Ada.Command_Line;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

with Tarlib.Entries;
with Tarlib.Errors;
with Tarlib.Files;
with Tarlib.Writers;

with Zlib;

--  Package a built devcert into one <prefix>.tar.gz, for carrying to a host
--  that has to be validated by hand -- a Mac, where the keychain adapter can
--  only be exercised in person.
--
--  The archive is a tree rather than a bare executable because devcert reads
--  its catalog and locale data from Exe/../share, and because devcert_tools
--  finds the project root by looking for devcert.gpr beside it. Unpack and the
--  platform check runs where it lands.
--
--  tar comes from tarlib and the gzip wrapper from zlib: repository tooling is
--  Ada here, and tarlib carries the executable bit through, which an archive
--  assembled by the CI runner's own upload step would drop.
procedure Package_Artifact is
   use type Ada.Streams.Stream_Element_Offset;
   use type Tarlib.Errors.Status_Code;
   use type Zlib.Status_Code;

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "package_artifact: " & Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Fail;

   Prefix   : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Command_Line.Argument (1) else "");
   Output   : constant String :=
     (if Ada.Command_Line.Argument_Count >= 2
      then Ada.Command_Line.Argument (2) else "");
   Tar_Path : constant String := Output & ".tar";
begin
   if Prefix = "" or else Output = "" then
      Fail ("usage: package_artifact <prefix> <output.tar.gz>");
      return;
   end if;

   declare
      Sink    : aliased Tarlib.Files.File_Output_Sink;
      Archive : Tarlib.Writers.Writer;
      Result  : Tarlib.Errors.Status;

      --  Every member the unpacked tree needs, and nothing that would make it
      --  a source release: this is the built thing, not the repository.
      procedure Add (Path : String; Required : Boolean) is
      begin
         if not Ada.Directories.Exists (Path) then
            if Required then
               Fail (Path & " is missing; build before packaging");
            end if;
            return;
         end if;

         Tarlib.Files.Add_Tree (Archive, Path, Prefix & "/" & Path, Result);
         if Result.Code /= Tarlib.Errors.Success then
            Fail ("could not add " & Path & ": " & Result.Code'Image);
         end if;
      end Add;

      --  tarlib writes deterministic metadata -- every file 0644 -- which is
      --  right for a reproducible archive and wrong for the one thing here that
      --  has to run on arrival. These entries carry an explicit mode instead.
      procedure Emit_Executable (Path : String) is
         Chunk : constant := 64 * 1024;
         File  : Ada.Streams.Stream_IO.File_Type;
         Meta  : Tarlib.Entries.Metadata;
         Data  : Ada.Streams.Stream_Element_Array (1 .. Chunk);
         Last  : Ada.Streams.Stream_Element_Offset;
      begin
         Meta.Mode := 8#0755#;
         Tarlib.Writers.Begin_Entry
           (Archive,
            Prefix & "/" & Path,
            Tarlib.Entries.Regular_File,
            Tarlib.Byte_Count (Ada.Directories.Size (Path)),
            Meta,
            Result);
         if Result.Code /= Tarlib.Errors.Success then
            Fail ("could not begin " & Path & ": " & Result.Code'Image);
            return;
         end if;

         Ada.Streams.Stream_IO.Open
           (File, Ada.Streams.Stream_IO.In_File, Path);
         while not Ada.Streams.Stream_IO.End_Of_File (File) loop
            Ada.Streams.Stream_IO.Read (File, Data, Last);
            exit when Last < Data'First;
            Tarlib.Writers.Write (Archive, Data (Data'First .. Last), Result);
            exit when Result.Code /= Tarlib.Errors.Success;
         end loop;
         Ada.Streams.Stream_IO.Close (File);

         if Result.Code /= Tarlib.Errors.Success then
            Fail ("could not write " & Path & ": " & Result.Code'Image);
            return;
         end if;

         Tarlib.Writers.End_Entry (Archive, Result);
         if Result.Code /= Tarlib.Errors.Success then
            Fail ("could not end " & Path & ": " & Result.Code'Image);
         end if;
      end Emit_Executable;

      --  Windows names the same build devcert.exe, and the archive keeps
      --  whichever name the host produced rather than renaming it to look
      --  uniform, which would leave an unrunnable file on unpacking.
      procedure Add_Executable (Path : String; Required : Boolean) is
         Windows_Path : constant String := Path & ".exe";
      begin
         if Ada.Directories.Exists (Path) then
            Emit_Executable (Path);
         elsif Ada.Directories.Exists (Windows_Path) then
            Emit_Executable (Windows_Path);
         elsif Required then
            Fail (Path & " is missing; build before packaging");
         end if;
      end Add_Executable;
   begin
      Tarlib.Files.Create_Write (Sink, Tar_Path, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Fail ("could not create " & Tar_Path & ": " & Result.Code'Image);
         return;
      end if;

      Tarlib.Writers.Initialize (Archive, Sink, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Fail ("could not initialize the archive: " & Result.Code'Image);
         return;
      end if;

      Add ("devcert.gpr", Required => True);
      Add ("share", Required => True);
      Add ("LICENSE", Required => True);
      Add_Executable ("bin/devcert", Required => True);
      --  Only present when the tooling crate has been built; the platform
      --  check needs it, an ordinary user of the binary does not.
      Add_Executable ("devcert_tools/bin/devcert_tools", Required => False);

      Tarlib.Writers.Finish (Archive, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Fail ("could not finish the archive: " & Result.Code'Image);
      end if;

      Tarlib.Files.Close (Sink, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Fail ("could not close " & Tar_Path & ": " & Result.Code'Image);
         return;
      end if;
   end;

   declare
      Status : Zlib.Status_Code;
   begin
      --  Streaming, not the whole-file GZip_File: the bundled locale data alone
      --  makes this archive ~80 MB, and reading that in one piece overflowed
      --  the stack.
      Zlib.GZip_File_Streaming (Tar_Path, Output, Status => Status);
      if Status /= Zlib.Ok then
         Fail ("could not compress " & Tar_Path & ": " & Status'Image);
         return;
      end if;
   end;

   Ada.Directories.Delete_File (Tar_Path);
   Ada.Text_IO.Put_Line
     ("package_artifact wrote " & Output
      & " (" & Ada.Directories.Size (Output)'Image & " bytes)");
end Package_Artifact;
