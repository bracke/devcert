with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Alire_Manifests;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

procedure Devcert_Tools is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Kind;

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

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

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
            elsif In_Pin_Block and then Starts_With (Clean, "[[") then
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
         raise Program_Error;
      end if;
   end Require_Success;

   procedure Run_Style_Check is
      State : Check_State;

      procedure Check_File (Path : String; Name : String) is
         File        : File_Type;
         Line_Number : Positive := 1;
      begin
         if Is_Source_File (Name) then
            if Name /= "README.md" and then Name /= Lower (Name) then
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
   begin
      Require_Contains (Project_Root & "/alire.toml", "name = ""devcert""",
                        "runtime manifest crate name");
      Require_Contains (Project_Root & "/alire.toml", "executables = [""devcert""]",
                        "runtime executable name");
      Require_Release_Dependencies
        (Project_Root & "/alire.toml",
         [To_Unbounded_String ("cryptolib"),
          To_Unbounded_String ("i18n"),
          To_Unbounded_String ("terminal_styles")]);
      Require_Workspace_Pin (Project_Root & "/alire.toml", "cryptolib", "../cryptolib");
      Require_Workspace_Pin (Project_Root & "/alire.toml", "i18n", "../i18n");
      Require_Workspace_Pin
        (Project_Root & "/alire.toml", "terminal_styles", "../terminal_styles");

      Require_Contains
        (Project_Root & "/devcert_tools/alire.toml",
         "name = ""devcert_tools""",
         "tooling manifest crate name");
      Require_Release_Dependency
        (Project_Root & "/devcert_tools/alire.toml", "project_tools");
      Require_Workspace_Pin
        (Project_Root & "/devcert_tools/alire.toml",
         "project_tools",
         "../../project_tools");

      Require_Contains
        (Project_Root & "/devcert_tests/alire.toml",
         "name = ""devcert_tests""",
         "test manifest crate name");
      Require_Release_Dependency (Project_Root & "/devcert_tests/alire.toml", "aunit");
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
      Path  : constant String := Project_Root & "/config/messages/en.catalog";

      procedure Require_Id (Id : String) is
      begin
         if not Project_Tools.Files.Line_Contains (Path, Id & "=") then
            Fail (State, Path, "missing message id " & Id);
         end if;
      end Require_Id;
   begin
      Project_Tools.Files.Require_File (Path, "default locale catalog");
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
      State.Errors := Entry_No;
      Require_Success (State, "tree-check");
      Put_Line ("tree-check passed");
   end Run_Tree_Check;

   procedure Run_Documentation_Check is
      procedure Require_Doc (Path : String) is
      begin
         Project_Tools.Release_Checks.Require_File (Checks, Path);
      end Require_Doc;
   begin
      Require_Doc ("README.md");
      Require_Doc ("docs/installation.md");
      Require_Doc ("docs/cli.md");
      Require_Doc ("docs/coding_style.md");
      Require_Doc ("docs/ca_lifecycle.md");
      Require_Doc ("docs/certificate_policies.md");
      Require_Doc ("docs/trust_stores.md");
      Require_Doc ("docs/cryptolib_contract.md");
      Require_Doc ("docs/localization.md");
      Require_Doc ("docs/json_contract.md");
      Require_Doc ("docs/security.md");
      Require_Doc ("docs/release_process.md");
      Require_Doc ("docs/mkcert_parity.md");
      Require_Doc ("docs/final_acceptance.md");
      Put_Line ("documentation passed");
   end Run_Documentation_Check;

   procedure Run_Generated_Artifact_Check is
   begin
      Project_Tools.Release_Checks.Require_Text
        (Checks, "docs/mkcert_parity.md", "<!-- generated:devcert-parity -->");
      Project_Tools.Release_Checks.Require_Text
        (Checks, "docs/final_acceptance.md", "<!-- generated:devcert-acceptance -->");
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
   begin
      Project_Tools.Files.Require_File (Path, "mkcert parity matrix");
      Require_Row ("install local CA");
      Require_Row ("uninstall local CA");
      Require_Row ("issue localhost certificate");
      Require_Row ("sign CSR");
      Require_Row ("PKCS#12 bundle");
      Require_Row ("NSS trust");
      Require_Row ("Java trust");
      Require_Row ("macOS trust");
      Require_Row ("Windows trust");
      if Project_Tools.Files.Line_Contains (Path, "Planned") then
         Fail (State, Path, "parity matrix still contains Planned entries");
      end if;
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
      Put_Line ("dist staged at " & Target);
   end Run_Dist;

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
      Put_Line ("  parity-check");
      Put_Line ("  tooling-tests");
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
   elsif Command = "documentation" then
      Run_Documentation_Check;
   elsif Command = "parity-check" then
      Run_Parity_Check;
   elsif Command = "tooling-tests" then
      Run_Tooling_Tests;
   else
      Put_Line (Standard_Error, "unknown devcert_tools command: " & Command);
      Print_Usage;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
exception
   when Program_Error =>
      null;
   when E : others =>
      Put_Line
        (Standard_Error,
         "devcert_tools failed: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Devcert_Tools;
