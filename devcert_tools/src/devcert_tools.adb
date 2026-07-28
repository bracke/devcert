with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Vectors;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with CryptoLib.Hashes;

with Project_Tools.Alire_Manifests;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

with Hostkit.Host;

procedure Devcert_Tools is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Kind;
   use type Ada.Streams.Stream_Element_Offset;

   Check_Failed : exception;
   Hex          : constant String := "0123456789abcdef";

   package String_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => String);
   package String_Sorting is new String_Vectors.Generic_Sorting;

   type Check_State is record
      Errors : Natural := 0;
   end record;

   function Root return String is
      Here : constant String := Ada.Directories.Current_Directory;
   begin
      if Ada.Directories.Exists (Here & "/devcert.gpr") then
         return Here;
      elsif Ada.Directories.Exists (Here & "/../devcert.gpr") then
         return Ada.Directories.Full_Name (Here & "/..");
      else
         return Here;
      end if;
   end Root;

   Project_Root : constant String := Root;
   Checks       : constant Project_Tools.Release_Checks.Checker :=
     Project_Tools.Release_Checks.Create (Project_Root);

   procedure Fail (State : in out Check_State; Path : String; Message : String) is
   begin
      State.Errors := State.Errors + 1;
      Put_Line (Standard_Error, Path & ": " & Message);
   end Fail;

   function Lower (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Text);
   end Lower;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Is_Blank_Or_Comment (Text : String) return Boolean is
      Clean : constant String := Trim (Text);
   begin
      return Clean = "" or else Project_Tools.Text.Starts_With (Clean, "#");
   end Is_Blank_Or_Comment;

   function Is_Allowed
     (Name    : String;
      Allowed : Project_Tools.Alire_Manifests.String_List) return Boolean is
   begin
      for Item of Allowed loop
         if Name = To_String (Item) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Allowed;

   function Strip_Pin_Blocks (Content : String) return String is
      Result       : Unbounded_String;
      Position     : Positive := Content'First;
      Line_Start   : Positive;
      Line_End     : Natural;
      In_Pin_Block : Boolean := False;
   begin
      while Position <= Content'Last loop
         Line_Start := Position;
         Line_End := Line_Start - 1;
         while Position <= Content'Last and then Content (Position) /= ASCII.LF loop
            Line_End := Position;
            Position := Position + 1;
         end loop;

         declare
            Line : constant String :=
              (if Line_End >= Line_Start then Content (Line_Start .. Line_End) else "");
            Clean : constant String := Trim (Line);
         begin
            if Clean = "[[pins]]" then
               In_Pin_Block := True;
            elsif In_Pin_Block and then Project_Tools.Text.Starts_With (Clean, "[[") then
               In_Pin_Block := False;
               Append (Result, Line);
               Append (Result, ASCII.LF);
            elsif not In_Pin_Block then
               Append (Result, Line);
               Append (Result, ASCII.LF);
            end if;
         end;

         if Position <= Content'Last and then Content (Position) = ASCII.LF then
            Position := Position + 1;
         end if;
      end loop;
      return To_String (Result);
   end Strip_Pin_Blocks;

   function Hex_Image (Digest : CryptoLib.Hashes.SHA256_Digest) return String is
      Result : String (1 .. Digest'Length * 2);
      Pos    : Positive := Result'First;
   begin
      for B of Digest loop
         Result (Pos) := Hex (Natural (B) / 16 + 1);
         Result (Pos + 1) := Hex (Natural (B) mod 16 + 1);
         Pos := Pos + 2;
      end loop;
      return Result;
   end Hex_Image;

   function SHA256_Hex (Path : String) return String is
      File    : Ada.Streams.Stream_IO.File_Type;
      Context : CryptoLib.Hashes.SHA256_Context;
      Buffer  : Ada.Streams.Stream_Element_Array (1 .. 32_768);
      Last    : Ada.Streams.Stream_Element_Offset;
   begin
      CryptoLib.Hashes.Initialize_SHA256 (Context);
      Ada.Streams.Stream_IO.Open
        (File, Ada.Streams.Stream_IO.In_File, Path);
      while not Ada.Streams.Stream_IO.End_Of_File (File) loop
         Ada.Streams.Stream_IO.Read (File, Buffer, Last);
         if Last >= Buffer'First then
            CryptoLib.Hashes.Update (Context, Buffer (Buffer'First .. Last));
         end if;
      end loop;
      Ada.Streams.Stream_IO.Close (File);
      return Hex_Image (CryptoLib.Hashes.Finalize (Context));
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         raise;
   end SHA256_Hex;

   function Is_Source_File (Name : String) return Boolean is
      L : constant String := Lower (Name);
   begin
      return Project_Tools.Text.Ends_With (L, ".adb")
        or else Project_Tools.Text.Ends_With (L, ".ads")
        or else Project_Tools.Text.Ends_With (L, ".gpr")
        or else Project_Tools.Text.Ends_With (L, ".toml")
        or else Project_Tools.Text.Ends_With (L, ".md")
        or else Project_Tools.Text.Ends_With (L, ".catalog");
   end Is_Source_File;

   function Skip_Directory (Name : String) return Boolean is
   begin
      return Name = "."
        or else Name = ".."
        or else Name = ".agents"
        or else Name = ".codex"
        or else Name = ".git"
        or else Name = "alire"
        or else Name = "bin"
        or else Name = "obj"
        or else Name = "lib"
        or else Name = "dist";
   end Skip_Directory;

   procedure Walk
     (Path  : String;
      Visit : not null access procedure (Path : String; Name : String)) is
      Search  : Ada.Directories.Search_Type;
      Item    : Ada.Directories.Directory_Entry_Type;
      Started : Boolean := False;
   begin
      if not Project_Tools.Files.Directory_Exists (Path) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search,
         Directory => Path,
         Pattern   => "*",
         Filter    =>
           [Ada.Directories.Ordinary_File => True,
            Ada.Directories.Directory     => True,
            Ada.Directories.Special_File  => False]);
      Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         declare
            Name : constant String := Ada.Directories.Simple_Name (Item);
            Full : constant String := Ada.Directories.Full_Name (Item);
         begin
            if Name = "." or else Name = ".." then
               null;
            elsif Ada.Directories.Kind (Item) = Ada.Directories.Directory then
               if not Skip_Directory (Name) then
                  Walk (Full, Visit);
               end if;
            else
               Visit (Full, Name);
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Started := False;
   exception
      when others =>
         if Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
   end Walk;

   procedure Require_Success (State : Check_State; Label : String) is
   begin
      if State.Errors /= 0 then
         Put_Line
           (Standard_Error,
            Label & " failed with" & Natural'Image (State.Errors) & " error(s)");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Check_Failed;
      end if;
   end Require_Success;

   procedure Require_Only_Dependencies
     (State   : in out Check_State;
      Path    : String;
      Allowed : Project_Tools.Alire_Manifests.String_List;
      Label   : String) is
      File           : File_Type;
      In_Dependency  : Boolean := False;
      Dependency_Set : Boolean := False;

      procedure Check_Dependency (Line : String) is
         Clean : constant String := Trim (Line);
         Equal : constant Natural := Ada.Strings.Fixed.Index (Clean, "=");
         Name  : constant String :=
           (if Equal = 0 then Clean else Trim (Clean (Clean'First .. Equal - 1)));
      begin
         if Name /= "gnat_native" and then not Is_Allowed (Name, Allowed) then
            Fail (State, Path, Label & " has forbidden dependency " & Name);
         end if;
      end Check_Dependency;
   begin
      Open (File, In_File, Path);
      while not End_Of_File (File) loop
         declare
            Line  : constant String := Get_Line (File);
            Clean : constant String := Trim (Line);
         begin
            if Clean = "[[depends-on]]" then
               In_Dependency := True;
               Dependency_Set := False;
            elsif Project_Tools.Text.Starts_With (Clean, "[[") then
               In_Dependency := False;
            elsif In_Dependency and then not Dependency_Set
              and then not Is_Blank_Or_Comment (Clean)
            then
               Check_Dependency (Clean);
               Dependency_Set := True;
            end if;
         end;
      end loop;
      Close (File);
   exception
      when E : others =>
         if Is_Open (File) then
            Close (File);
         end if;
         Fail (State, Path, Ada.Exceptions.Exception_Message (E));
   end Require_Only_Dependencies;

   procedure Require_No_Source_Tokens
     (State  : in out Check_State;
      Label  : String;
      Tokens : Project_Tools.Files.Name_List) is

      procedure Check_File (Path : String; Name : String) is
         File        : File_Type;
         Line_Number : Positive := 1;
      begin
         if Is_Source_File (Name) then
            Open (File, In_File, Path);
            while not End_Of_File (File) loop
               declare
                  Line : constant String := Get_Line (File);
               begin
                  for Token of Tokens loop
                     if Project_Tools.Text.Contains (Lower (Line), To_String (Token)) then
                        Fail
                          (State,
                           Path & ":" & Trim (Positive'Image (Line_Number)),
                           Label & " contains forbidden token "
                           & To_String (Token));
                     end if;
                  end loop;
               end;
               Line_Number := Line_Number + 1;
            end loop;
            Close (File);
         end if;
      exception
         when E : others =>
            if Is_Open (File) then
               Close (File);
            end if;
            Fail (State, Path, Ada.Exceptions.Exception_Message (E));
      end Check_File;
   begin
      Walk (Project_Root & "/src", Check_File'Access);
      Walk (Project_Root & "/app", Check_File'Access);
      Walk (Project_Root & "/devcert_tools/src", Check_File'Access);
      Walk (Project_Root & "/devcert_tests/src", Check_File'Access);
   end Require_No_Source_Tokens;

   procedure Run_Style_Check is
      State : Check_State;

      procedure Check_File (Path : String; Name : String) is
         File        : File_Type;
         Line_Number : Positive := 1;
      begin
         if Is_Source_File (Name) then
            if Name /= "README.md"
              and then Name /= "CHANGELOG.md"
              and then Name /= Lower (Name)
            then
               Fail (State, Path, "file names must be lower case");
            end if;

            Open (File, In_File, Path);
            while not End_Of_File (File) loop
               declare
                  Line : constant String := Get_Line (File);
               begin
                  if Ada.Strings.Fixed.Index (Line, Character'Val (9) & "") /= 0 then
                     Fail
                       (State,
                        Path & ":" & Trim (Positive'Image (Line_Number)),
                        "tabs are forbidden; use spaces only");
                  end if;

                  if Line'Length > 100 then
                     Fail
                       (State,
                        Path & ":" & Trim (Positive'Image (Line_Number)),
                        "line exceeds 100 characters");
                  end if;

                  if Line'Length > 0
                    and then (Line (Line'Last) = ' '
                              or else Line (Line'Last) = Character'Val (9))
                  then
                     Fail
                       (State,
                        Path & ":" & Trim (Positive'Image (Line_Number)),
                        "trailing whitespace");
                  end if;
               end;
               Line_Number := Line_Number + 1;
            end loop;
            Close (File);
         end if;
      exception
         when E : others =>
            if Is_Open (File) then
               Close (File);
            end if;
            Fail (State, Path, Ada.Exceptions.Exception_Message (E));
      end Check_File;
   begin
      Walk (Project_Root, Check_File'Access);
      Require_Success (State, "style-check");
      Put_Line ("style-check passed");
   end Run_Style_Check;

   procedure Run_Manifest_Check is
      use Project_Tools.Alire_Manifests;
      use Project_Tools.Files;
      State : Check_State;
   begin
      Require_Contains (Project_Root & "/alire.toml", "name = ""devcert""",
                        "runtime manifest crate name");
      Require_Contains (Project_Root & "/alire.toml", "executables = [""devcert""]",
                        "runtime executable name");
      Require_Release_Dependencies
        (Project_Root & "/alire.toml",
         [To_Unbounded_String ("cryptolib"),
          To_Unbounded_String ("hostkit"),
          To_Unbounded_String ("i18n"),
          To_Unbounded_String ("messages"),
          To_Unbounded_String ("terminal_styles")]);
      Require_Only_Dependencies
        (State,
         Project_Root & "/alire.toml",
         [To_Unbounded_String ("cryptolib"),
          To_Unbounded_String ("hostkit"),
          To_Unbounded_String ("i18n"),
          To_Unbounded_String ("messages"),
          To_Unbounded_String ("terminal_styles")],
         "runtime manifest");
      Require_Workspace_Pin (Project_Root & "/alire.toml", "cryptolib", "../cryptolib");
      Require_Workspace_Pin (Project_Root & "/alire.toml", "hostkit", "../hostkit");
      Require_Workspace_Pin (Project_Root & "/alire.toml", "i18n", "../i18n");
      Require_Workspace_Pin (Project_Root & "/alire.toml", "messages", "../messages");
      Require_Workspace_Pin
        (Project_Root & "/alire.toml", "terminal_styles", "../terminal_styles");

      Require_Contains
        (Project_Root & "/devcert_tools/alire.toml",
         "name = ""devcert_tools""",
         "tooling manifest crate name");
      Require_Release_Dependency
        (Project_Root & "/devcert_tools/alire.toml", "project_tools");
      Require_Release_Dependency
        (Project_Root & "/devcert_tools/alire.toml", "cryptolib");
      Require_Release_Dependency
        (Project_Root & "/devcert_tools/alire.toml", "hostkit");
      Require_Only_Dependencies
        (State,
         Project_Root & "/devcert_tools/alire.toml",
         [To_Unbounded_String ("project_tools"),
          To_Unbounded_String ("cryptolib"),
          To_Unbounded_String ("hostkit")],
         "tooling manifest");
      Require_Workspace_Pin
        (Project_Root & "/devcert_tools/alire.toml",
         "project_tools",
         "../../project_tools");
      Require_Workspace_Pin
        (Project_Root & "/devcert_tools/alire.toml",
         "cryptolib",
         "../../cryptolib");
      Require_Workspace_Pin
        (Project_Root & "/devcert_tools/alire.toml",
         "hostkit",
         "../../hostkit");

      Require_Contains
        (Project_Root & "/devcert_tests/alire.toml",
         "name = ""devcert_tests""",
         "test manifest crate name");
      Require_Release_Dependency (Project_Root & "/devcert_tests/alire.toml", "aunit");
      Require_Release_Dependency (Project_Root & "/devcert_tests/alire.toml", "devcert");
      Require_Only_Dependencies
        (State,
         Project_Root & "/devcert_tests/alire.toml",
         [To_Unbounded_String ("aunit"),
          To_Unbounded_String ("devcert")],
         "test manifest");
      Require_Workspace_Pin
        (Project_Root & "/devcert_tests/alire.toml", "devcert", "..");
      Require_Success (State, "manifest-check");
      Put_Line ("manifest-check passed");
   end Run_Manifest_Check;

   procedure Sanitize_Release_Manifest (Path : String) is
      use Project_Tools.Files;
   begin
      if File_Exists (Path) then
         Write_Text_File (Path, Strip_Pin_Blocks (Read_Raw_File (Path)));
      end if;
   end Sanitize_Release_Manifest;

   procedure Run_Release_Artifact_Manifest_Check (Target : String) is
      State : Check_State;

      procedure Check_File (Relative_Path : String) is
         Path : constant String := Target & "/" & Relative_Path;
      begin
         if Project_Tools.Files.File_Contains (Path, "[[pins]]") then
            Fail (State, Path, "release artifact manifest contains pins");
         end if;
         if Project_Tools.Files.File_Contains (Path, "path =") then
            Fail (State, Path, "release artifact manifest contains local path pin");
         end if;
         if Project_Tools.Files.File_Contains (Path, "../") then
            Fail (State, Path, "release artifact manifest contains parent path");
         end if;
      end Check_File;
   begin
      Check_File ("alire.toml");
      Check_File ("devcert_tools/alire.toml");
      Check_File ("devcert_tests/alire.toml");
      Require_Success (State, "release artifact manifest check");
   end Run_Release_Artifact_Manifest_Check;

   function Relative_To (Root : String; Path : String) return String is
      Prefix : constant String := Root & "/";
   begin
      if Project_Tools.Text.Starts_With (Path, Prefix) then
         return Path (Path'First + Prefix'Length .. Path'Last);
      else
         return Path;
      end if;
   end Relative_To;

   procedure Write_Release_Checksums (Target : String) is
      Files : String_Vectors.Vector;

      procedure Add_File (Path : String; Name : String) is
         pragma Unreferenced (Name);
         Relative : constant String := Relative_To (Target, Path);
      begin
         if Relative /= "SHA256SUMS" then
            Files.Append (Relative);
         end if;
      end Add_File;

      Output : Unbounded_String;
   begin
      Walk (Target, Add_File'Access);
      String_Sorting.Sort (Files);

      for Relative of Files loop
         Append
           (Output,
            SHA256_Hex (Target & "/" & Relative) & "  " & Relative & ASCII.LF);
      end loop;

      Project_Tools.Files.Write_Text_File
        (Target & "/SHA256SUMS", To_String (Output));
   end Write_Release_Checksums;

   procedure Run_Release_Checksum_Check (Target : String) is
      State : Check_State;
      Path  : constant String := Target & "/SHA256SUMS";
   begin
      if not Project_Tools.Files.File_Exists (Path) then
         Fail (State, Path, "release checksum manifest is missing");
      elsif not Project_Tools.Files.Line_Contains (Path, "  alire.toml") then
         Fail (State, Path, "release checksum manifest does not cover alire.toml");
      elsif Project_Tools.Files.Line_Contains (Path, "  SHA256SUMS") then
         Fail (State, Path, "release checksum manifest must not cover itself");
      end if;
      Require_Success (State, "release checksum check");
   end Run_Release_Checksum_Check;

   procedure Run_Tooling_Tests is
      State : Check_State;
      Temp  : constant String := "/tmp/devcert-tools-selftest";

      procedure Assert_True (Condition : Boolean; Message : String) is
      begin
         if not Condition then
            Fail (State, "tooling-tests", Message);
         end if;
      end Assert_True;

      Clean_Manifest : constant String :=
        "name = ""sample""" & ASCII.LF
        & ASCII.LF
        & "[[depends-on]]" & ASCII.LF
        & "cryptolib = ""*""" & ASCII.LF
        & ASCII.LF;
      Pinned_Manifest : constant String :=
        Clean_Manifest
        & "[[pins]]" & ASCII.LF
        & "cryptolib = { path = ""../cryptolib"" }" & ASCII.LF
        & ASCII.LF
        & "[[actions]]" & ASCII.LF
        & "type = ""test""" & ASCII.LF;
      Stripped : constant String := Strip_Pin_Blocks (Pinned_Manifest);
   begin
      Assert_True
        (not Project_Tools.Text.Contains (Stripped, "[[pins]]"),
         "pin block stripping removes pin header");
      Assert_True
        (not Project_Tools.Text.Contains (Stripped, "path ="),
         "pin block stripping removes local path entries");
      Assert_True
        (Project_Tools.Text.Contains (Stripped, "[[actions]]"),
         "pin block stripping preserves following manifest sections");

      if Project_Tools.Files.Directory_Exists (Temp) then
         Project_Tools.Files.Delete_Tree (Temp);
      end if;
      Ada.Directories.Create_Path (Temp & "/devcert_tools");
      Ada.Directories.Create_Path (Temp & "/devcert_tests");
      Project_Tools.Files.Write_Text_File (Temp & "/alire.toml", Clean_Manifest);
      Project_Tools.Files.Write_Text_File
        (Temp & "/devcert_tools/alire.toml", Clean_Manifest);
      Project_Tools.Files.Write_Text_File
        (Temp & "/devcert_tests/alire.toml", Clean_Manifest);
      Run_Release_Artifact_Manifest_Check (Temp);
      Project_Tools.Files.Delete_Tree (Temp);

      Require_Success (State, "tooling-tests");
      Put_Line ("tooling-tests passed");
   exception
      when others =>
         if Project_Tools.Files.Directory_Exists (Temp) then
            Project_Tools.Files.Delete_Tree (Temp);
         end if;
         raise;
   end Run_Tooling_Tests;

   procedure Run_Catalog_Check is
      State : Check_State;
      Source_Path : constant String := Project_Root & "/config/messages/en.catalog";
      Ship_Path   : constant String := Project_Root & "/share/devcert/messages.catalog";

      procedure Validate_Catalog (Path : String) is
         File                   : File_Type;
         Line_Number            : Positive := 1;
         Seen                   : Unbounded_String;
         Default_Locale_Count   : Natural := 0;

         procedure Fail_Line (Message : String) is
         begin
            Fail
              (State,
               Path & ":" & Trim (Positive'Image (Line_Number)),
               Message);
         end Fail_Line;

         procedure Check_Braces (Value : String) is
            Depth : Natural := 0;
         begin
            for Ch of Value loop
               if Ch = '{' then
                  Depth := Depth + 1;
               elsif Ch = '}' then
                  if Depth = 0 then
                     Fail_Line ("malformed message parameter braces");
                     return;
                  end if;
                  Depth := Depth - 1;
               end if;
            end loop;
            if Depth /= 0 then
               Fail_Line ("malformed message parameter braces");
            end if;
         end Check_Braces;
      begin
         Project_Tools.Files.Require_File (Path, "messages catalog");
         Open (File, In_File, Path);
         while not End_Of_File (File) loop
            declare
               Line  : constant String := Get_Line (File);
               Clean : constant String := Trim (Line);
               Equal : constant Natural := Ada.Strings.Fixed.Index (Clean, "=");
            begin
               if not Is_Blank_Or_Comment (Clean) then
                  if Equal = 0 then
                     Fail_Line ("malformed catalog entry");
                  else
                     declare
                        Key   : constant String :=
                          Trim (Clean (Clean'First .. Equal - 1));
                        Value : constant String :=
                          Trim (Clean (Equal + 1 .. Clean'Last));
                        Mark  : constant String := ASCII.LF & Key & ASCII.LF;
                     begin
                        if Key = "" or else Value = "" then
                           Fail_Line ("catalog keys and values must be non-empty");
                        end if;
                        if Project_Tools.Text.Contains (To_String (Seen), Mark) then
                           Fail_Line ("duplicate message id " & Key);
                        end if;
                        Append (Seen, Mark);
                        if Key = "default_locale" then
                           Default_Locale_Count := Default_Locale_Count + 1;
                        elsif not Project_Tools.Text.Starts_With (Key, "en.") then
                           Fail_Line ("message id must be locale-qualified");
                        end if;
                        Check_Braces (Value);
                     end;
                  end if;
               end if;
            end;
            Line_Number := Line_Number + 1;
         end loop;
         Close (File);

         if Default_Locale_Count = 0 then
            Fail (State, Path, "missing default_locale");
         elsif Default_Locale_Count > 1 then
            Fail (State, Path, "duplicate default_locale");
         end if;
      exception
         when E : others =>
            if Is_Open (File) then
               Close (File);
            end if;
            Fail (State, Path, Ada.Exceptions.Exception_Message (E));
      end Validate_Catalog;

      procedure Require_Id (Id : String) is
      begin
         if not Project_Tools.Files.Line_Contains (Source_Path, "en." & Id & " =") then
            Fail (State, Source_Path, "missing message id " & Id);
         end if;
         if not Project_Tools.Files.Line_Contains (Ship_Path, "en." & Id & " =") then
            Fail (State, Ship_Path, "missing message id " & Id);
         end if;
      end Require_Id;
   begin
      Validate_Catalog (Source_Path);
      Validate_Catalog (Ship_Path);
      Require_Id ("app.name");
      Require_Id ("cli.usage");
      Require_Id ("error.unknown_command");
      Require_Id ("json.schema");
      Require_Id ("release.passed");
      Require_Success (State, "catalog-check");
      Put_Line ("catalog-check passed");
   end Run_Catalog_Check;

   procedure Run_Tree_Check is
      use Project_Tools.Files;
      State    : Check_State;
      Entry_No : Natural := 0;

      procedure Check_Repository_File (Path : String; Name : String) is
         L : constant String := Lower (Name);
      begin
         if Name = "Makefile"
           or else Project_Tools.Text.Ends_With (L, ".sh")
           or else Project_Tools.Text.Ends_With (L, ".py")
           or else Project_Tools.Text.Ends_With (L, ".js")
           or else Project_Tools.Text.Ends_With (L, ".pl")
           or else Project_Tools.Text.Ends_With (L, ".rb")
         then
            Fail (State, Path, "project tooling must be implemented in Ada");
         end if;
      end Check_Repository_File;

      procedure Check_Dir (Relative_Path : String) is
      begin
         Project_Tools.Tree_Checks.Check_No_Forbidden_Tree_Artifacts
           (Entry_No,
            Project_Root & "/" & Relative_Path,
            [To_Unbounded_String ("certs"),
             To_Unbounded_String ("private"),
             To_Unbounded_String (".pytest_cache"),
             To_Unbounded_String ("node_modules")],
            [To_Unbounded_String (".key"),
             To_Unbounded_String (".p12"),
             To_Unbounded_String (".pfx"),
             To_Unbounded_String ("~"),
             To_Unbounded_String (".tmp"),
             To_Unbounded_String (".o"),
             To_Unbounded_String (".ali")],
            "devcert repository");
      end Check_Dir;
   begin
      Check_Dir ("src");
      Check_Dir ("app");
      Check_Dir ("config");
      Check_Dir ("docs");
      Check_Dir ("devcert_tools/src");
      Check_Dir ("devcert_tests/src");
      Walk (Project_Root, Check_Repository_File'Access);
      Require_No_Source_Tokens
        (State,
         "source quality gate",
         [To_Unbounded_String ("to" & "do"),
          To_Unbounded_String ("fix" & "me"),
          To_Unbounded_String ("st" & "ub"),
          To_Unbounded_String ("place" & "holder"),
          To_Unbounded_String ("not " & "implemented")]);
      State.Errors := State.Errors + Entry_No;
      Require_Success (State, "tree-check");
      Put_Line ("tree-check passed");
   end Run_Tree_Check;

   --  Every declared test must be in the suite. Splitting the tests by area
   --  made this worth checking: a test type can be written, compiled and never
   --  run, and nothing about the build says so -- the suite simply reports a
   --  smaller number than anyone counts.
   procedure Run_Test_Registration_Check is
      State : Check_State;
      Suite : constant String :=
        Project_Tools.Files.Read_Raw_File
          (Project_Root & "/devcert_tests/src/devcert_test_suite.adb");

      procedure Check_Spec (Path : String; Name : String) is
         Text  : constant String :=
           (if Project_Tools.Text.Ends_With (Lower (Name), "_tests.ads")
            then Project_Tools.Files.Read_Raw_File (Path) else "");
         First : Natural := Text'First;
         Last  : Natural;
      begin
         while First < Text'Last loop
            declare
               Start : constant Natural :=
                 Project_Tools.Text.Index_From (Text, "   type ", First);
            begin
               exit when Start = 0;
               Last := Project_Tools.Text.Index_From (Text, " is", Start);
               exit when Last = 0;

               declare
                  Item : constant String := Trim (Text (Start + 7 .. Last - 1));
               begin
                  if Project_Tools.Text.Ends_With (Item, "_Test")
                    and then not Project_Tools.Text.Contains
                                   (Suite, "." & Item & ")")
                  then
                     Fail
                       (State, Path,
                        "test " & Item & " is declared but never added to the suite");
                  end if;
               end;
               First := Last + 1;
            end;
         end loop;
      end Check_Spec;
   begin
      Walk (Project_Root & "/devcert_tests/src", Check_Spec'Access);
      Require_Success (State, "test-registration-check");
      Put_Line ("test-registration-check passed");
   end Run_Test_Registration_Check;

   procedure Run_Documentation_Check is
      procedure Require_Doc (Path : String) is
      begin
         Project_Tools.Release_Checks.Require_File (Checks, Path);
      end Require_Doc;
   begin
      Require_Doc ("README.md");
      Require_Doc ("CHANGELOG.md");
      Require_Doc ("docs/installation.md");
      Require_Doc ("docs/cli.md");
      Require_Doc ("docs/coding_style.md");
      Require_Doc ("docs/ca_lifecycle.md");
      Require_Doc ("docs/certificate_policies.md");
      Require_Doc ("docs/trust_stores.md");
      Require_Doc ("docs/cryptolib_contract.md");
      Require_Doc ("docs/output.md");
      Require_Doc ("docs/localization.md");
      Require_Doc ("docs/json_contract.md");
      Require_Doc ("docs/security.md");
      Require_Doc ("docs/testing.md");
      Require_Doc ("docs/release_process.md");
      Require_Doc ("docs/mkcert_parity.md");
      Require_Doc ("docs/platform_validation.md");
      Require_Doc ("docs/platform_evidence.md");
      Require_Doc ("docs/final_acceptance.md");
      Put_Line ("documentation passed");
   end Run_Documentation_Check;

   procedure Run_Generated_Artifact_Check is
      State : Check_State;
   begin
      Project_Tools.Release_Checks.Require_Text
        (Checks, "docs/mkcert_parity.md", "<!-- generated:devcert-parity -->");
      Project_Tools.Release_Checks.Require_Text
        (Checks, "docs/final_acceptance.md", "<!-- generated:devcert-acceptance -->");
      if Project_Tools.Files.Read_Raw_File
          (Project_Root & "/config/messages/en.catalog")
        /= Project_Tools.Files.Read_Raw_File
          (Project_Root & "/share/devcert/messages.catalog")
      then
         Fail
           (State,
            Project_Root & "/share/devcert/messages.catalog",
            "shipped messages catalog is not current");
      end if;
      Require_Success (State, "generated-artifact-check");
      Put_Line ("generated-artifact-check passed");
   end Run_Generated_Artifact_Check;

   procedure Run_Parity_Check is
      State : Check_State;
      Path  : constant String := Project_Root & "/docs/mkcert_parity.md";

      procedure Require_Row (Item : String) is
      begin
         if not Project_Tools.Files.Line_Contains (Path, "| " & Item & " |") then
            Fail (State, Path, "missing parity row for " & Item);
         end if;
      end Require_Row;

      --  Which column a cell is in decides whether it may say Partial. A
      --  feature is implemented or it is not, and a half-claim there is what
      --  this check exists to catch. Host validation is different: a run
      --  against a real trust store can establish some of what it set out to
      --  and leave the rest, and calling that Pending would say no run
      --  happened. The evidence file names what is missing.
      function Column_Of (Header : String; Title : String) return Natural is
         Index  : Natural := 0;
         Cursor : Positive := Header'First;
      begin
         while Cursor <= Header'Last loop
            if Header (Cursor) = '|' then
               Index := Index + 1;
               declare
                  Next : Natural := 0;
               begin
                  for Scan in Cursor + 1 .. Header'Last loop
                     if Header (Scan) = '|' then
                        Next := Scan;
                        exit;
                     end if;
                  end loop;

                  exit when Next = 0;

                  if Project_Tools.Text.Contains
                       (Header (Cursor + 1 .. Next - 1), Title)
                  then
                     return Index;
                  end if;

                  Cursor := Next;
               end;
            else
               Cursor := Cursor + 1;
            end if;
         end loop;

         return 0;
      end Column_Of;

      procedure Reject_Cell (Value : String; Except_In : String := "") is
         Text     : constant String :=
           Ada.Strings.Unbounded.To_String
             (Project_Tools.Text.Read_Text_File (Path));
         Allowed  : Natural := 0;
         Line_Start : Positive := Text'First;
      begin
         for Cursor in Text'Range loop
            if Text (Cursor) = ASCII.LF or else Cursor = Text'Last then
               declare
                  Last : constant Natural :=
                    (if Text (Cursor) = ASCII.LF then Cursor - 1 else Cursor);
                  Line : constant String := Text (Line_Start .. Last);
                  Column : Natural := 0;
                  Start  : Natural := 0;
               begin
                  if Except_In /= "" and then Project_Tools.Text.Contains
                       (Line, "| " & Except_In & " |")
                  then
                     Allowed := Column_Of (Line, Except_In);
                  end if;

                  --  Walk the row's cells so the column each one sits in is
                  --  known, rather than only that the value appears somewhere.
                  for Scan in Line'Range loop
                     if Line (Scan) = '|' then
                        if Start /= 0 then
                           Column := Column + 1;

                           if Project_Tools.Text.Contains
                                (Line (Start .. Scan - 1), " " & Value & " ")
                             and then Column /= Allowed
                           then
                              Fail
                                (State,
                                 Path,
                                 "parity matrix contains incomplete cell "
                                 & Value);
                           end if;
                        end if;

                        Start := Scan;
                     end if;
                  end loop;
               end;

               Line_Start := Cursor + 1;
            end if;
         end loop;
      end Reject_Cell;

      procedure Require_Text (Item : String) is
      begin
         if not Project_Tools.Files.Line_Contains (Path, Item) then
            Fail (State, Path, "parity matrix is missing " & Item);
         end if;
      end Require_Text;
   begin
      Project_Tools.Files.Require_File (Path, "mkcert parity matrix");
      Require_Row ("CA root resolution");
      Require_Row ("CA creation");
      Require_Row ("CAROOT reporting");
      Require_Row ("install local CA");
      Require_Row ("uninstall local CA");
      Require_Row ("issue localhost certificate");
      Require_Row ("issue DNS SAN certificate");
      Require_Row ("issue IP SAN certificate");
      Require_Row ("custom certificate output paths");
      Require_Row ("client certificate profile");
      Require_Row ("S/MIME certificate profile");
      Require_Row ("sign CSR");
      Require_Row ("PKCS#12 bundle");
      Require_Row ("Linux system trust");
      Require_Row ("NSS trust");
      --  Firefox reads its own per-profile database, never the shared one, so
      --  covering it is a claim of its own rather than a detail of NSS.
      Require_Row ("Firefox trust");
      Require_Row ("Java trust");
      Require_Row ("macOS trust");
      Require_Row ("Windows trust");
      Require_Row ("fingerprint-authoritative removal");
      Require_Row ("JSON output");
      Require_Row ("localized human output");
      Reject_Cell ("Partial", Except_In => "Host validation");
      Reject_Cell ("No");

      --  Suite coverage and a run on a real host are different claims, and the
      --  matrix said "Tested" for both until a platform that had never executed
      --  the adapter at all was reading as tested. The column cannot be dropped
      --  back into one without failing here, and what it records lives in the
      --  evidence file.
      Require_Text ("| Host validation |");
      Require_Text ("platform_evidence.md");
      Require_Success (State, "parity-check");
      Put_Line ("parity-check passed");
   end Run_Parity_Check;

   procedure Run_Release_Check is
      Alr : constant String := Project_Tools.Processes.Locate_Command ("alr");
   begin
      Project_Tools.Processes.Require_Command
        ("alr", "alr is required for the devcert release checklist");
      Run_Style_Check;
      Run_Manifest_Check;
      Run_Catalog_Check;
      Run_Tree_Check;
      Run_Documentation_Check;
      Run_Test_Registration_Check;
      Run_Generated_Artifact_Check;
      Run_Parity_Check;
      Project_Tools.Release_Checks.Run
        ("runtime build", Project_Root, Alr, [new String'("build")]);
      Project_Tools.Release_Checks.Run
        ("tooling build", Project_Root & "/devcert_tools", Alr, [new String'("build")]);
      Project_Tools.Release_Checks.Run
        ("test build", Project_Root & "/devcert_tests", Alr, [new String'("build")]);
      Project_Tools.Processes.Run
        ("runtime tests",
         Project_Root,
         Project_Root & "/devcert_tests/bin/devcert_tests",
         [1 .. 0 => <>]);
      Project_Tools.Processes.Run
        ("tooling tests",
         Project_Root,
         Project_Root & "/devcert_tools/bin/devcert_tools",
         [new String'("tooling-tests")]);
      Put_Line ("release-check passed");
   end Run_Release_Check;

   procedure Run_Dist is
      Target : constant String := Project_Root & "/dist/devcert-0.1.0-dev";
   begin
      Run_Release_Check;
      Project_Tools.Files.Delete_Tree (Target);
      Project_Tools.Files.Copy_Release_Source_Tree
        (Project_Root,
         Target,
         [To_Unbounded_String (".git"),
          To_Unbounded_String ("alire"),
          To_Unbounded_String ("bin"),
          To_Unbounded_String ("obj"),
          To_Unbounded_String ("lib"),
          To_Unbounded_String ("dist")],
         [To_Unbounded_String ("alire.lock")]);
      Sanitize_Release_Manifest (Target & "/alire.toml");
      Sanitize_Release_Manifest (Target & "/devcert_tools/alire.toml");
      Sanitize_Release_Manifest (Target & "/devcert_tests/alire.toml");
      Run_Release_Artifact_Manifest_Check (Target);
      Write_Release_Checksums (Target);
      Run_Release_Checksum_Check (Target);
      Put_Line ("dist staged at " & Target);
   end Run_Dist;

   --  One system-store check, told which host it belongs to. The host must be
   --  that host: the system store is whatever the machine underfoot has, so
   --  running the macOS check on Linux would mutate the Linux store and report
   --  it as a macOS result. Hostkit answers from the body the build chose, so
   --  no environment variable can talk it into the wrong one.
   procedure Run_System_Platform_Check
     (Target : String;
      Host   : Hostkit.Host.Kind)
   is
      use type Hostkit.Host.Kind;

      State       : Check_State;
      --  Windows names it devcert.exe. Asked of the file system rather than of
      --  the host, because a tree carried to another machine keeps the name it
      --  was built with.
      Devcert_Bin : constant String :=
        (if Project_Tools.Files.File_Exists (Project_Root & "/bin/devcert.exe")
         then Project_Root & "/bin/devcert.exe"
         else Project_Root & "/bin/devcert");
      CA_Root     : constant String :=
        Project_Tools.Files.Temp_Dir & "/devcert-platform-" & Target;
      Install_Status   : Integer;
      Doctor_Status    : Integer;
      Uninstall_Status : Integer;
   begin
      if not Ada.Environment_Variables.Exists
        ("DEVCERT_RUN_PLATFORM_TRUST_TESTS")
        or else Ada.Environment_Variables.Value
          ("DEVCERT_RUN_PLATFORM_TRUST_TESTS") /= "1"
      then
         Fail
           (State,
            "platform-check",
            "set DEVCERT_RUN_PLATFORM_TRUST_TESTS=1 to mutate host trust");
         Require_Success (State, "platform-check");
      end if;

      if Hostkit.Host.Current /= Host then
         Fail
           (State,
            "platform-check",
            Target & " must be run on that host, not on this one");
         Require_Success (State, "platform-check");
      end if;

      Project_Tools.Files.Require_File
        (Devcert_Bin,
         "build bin/devcert before running platform trust checks");

      if Project_Tools.Files.Directory_Exists (CA_Root) then
         Project_Tools.Files.Delete_Tree (CA_Root);
      end if;

      Put_Line ("platform-check " & Target & " using CA root " & CA_Root);

      Install_Status :=
        Project_Tools.Processes.Run_Status
          (Target & " trust install",
           Project_Root,
           Devcert_Bin,
           [new String'("--ca-root"),
            new String'(CA_Root),
            new String'("install"),
            new String'("--trust-store"),
            new String'("system")]);

      Doctor_Status :=
        Project_Tools.Processes.Run_Status
          (Target & " trust doctor",
           Project_Root,
           Devcert_Bin,
           [new String'("--ca-root"),
            new String'(CA_Root),
            new String'("doctor")]);

      Uninstall_Status :=
        Project_Tools.Processes.Run_Status
          (Target & " trust uninstall",
           Project_Root,
           Devcert_Bin,
           [new String'("--ca-root"),
            new String'(CA_Root),
            new String'("uninstall"),
            new String'("--trust-store"),
            new String'("system")]);

      if Install_Status /= 0 then
         Fail (State, "platform-check", Target & " install failed");
      end if;
      if Doctor_Status /= 0 then
         Fail (State, "platform-check", Target & " CA validation failed");
      end if;
      if Uninstall_Status /= 0 then
         Fail (State, "platform-check", Target & " uninstall failed");
      end if;

      if Project_Tools.Files.Directory_Exists (CA_Root) then
         Project_Tools.Files.Delete_Tree (CA_Root);
      end if;

      Require_Success (State, "platform-check");
      Put_Line ("platform-check " & Target & " passed");
   exception
      when others =>
         if Project_Tools.Files.Directory_Exists (CA_Root) then
            Project_Tools.Files.Delete_Tree (CA_Root);
         end if;
         raise;
   end Run_System_Platform_Check;

   procedure Run_Platform_Check is
      Target : constant String :=
        (if Ada.Command_Line.Argument_Count >= 2
         then Ada.Command_Line.Argument (2)
         else "");
   begin
      if Target = "linux-system" then
         Run_System_Platform_Check ("linux-system", Hostkit.Host.Linux);
      elsif Target = "macos-system" then
         Run_System_Platform_Check ("macos-system", Hostkit.Host.MacOS);
      elsif Target = "windows-system" then
         Run_System_Platform_Check ("windows-system", Hostkit.Host.Windows);
      else
         Put_Line
           (Standard_Error,
            "usage: devcert_tools platform-check "
            & "linux-system|macos-system|windows-system");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   end Run_Platform_Check;

   procedure Print_Usage is
   begin
      Put_Line ("usage: devcert_tools <command>");
      Put_Line ("commands:");
      Put_Line ("  style-check");
      Put_Line ("  release-check");
      Put_Line ("  manifest-check");
      Put_Line ("  catalog-check");
      Put_Line ("  tree-check");
      Put_Line ("  generated-artifact-check");
      Put_Line ("  dist");
      Put_Line ("  documentation");
      Put_Line ("  test-registration-check");
      Put_Line ("  parity-check");
      Put_Line ("  tooling-tests");
      Put_Line ("  platform-check linux-system|macos-system|windows-system");
   end Print_Usage;

   Command : constant String :=
     (if Ada.Command_Line.Argument_Count = 0 then "" else Ada.Command_Line.Argument (1));
begin
   if Command = "" or else Command = "--help" then
      Print_Usage;
   elsif Command = "style-check" then
      Run_Style_Check;
   elsif Command = "release-check" then
      Run_Release_Check;
   elsif Command = "manifest-check" then
      Run_Manifest_Check;
   elsif Command = "catalog-check" then
      Run_Catalog_Check;
   elsif Command = "tree-check" then
      Run_Tree_Check;
   elsif Command = "generated-artifact-check" then
      Run_Generated_Artifact_Check;
   elsif Command = "dist" then
      Run_Dist;
   elsif Command = "test-registration-check" then
      Run_Test_Registration_Check;
   elsif Command = "documentation" then
      Run_Documentation_Check;
   elsif Command = "parity-check" then
      Run_Parity_Check;
   elsif Command = "tooling-tests" then
      Run_Tooling_Tests;
   elsif Command = "platform-check" then
      Run_Platform_Check;
   else
      Put_Line (Standard_Error, "unknown devcert_tools command: " & Command);
      Print_Usage;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
exception
   when Check_Failed =>
      null;
   when E : others =>
      Put_Line
        (Standard_Error,
         "devcert_tools failed: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Devcert_Tools;
