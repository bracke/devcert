with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with GNAT.OS_Lib;
with Devcert_Test_Suite.Paths;
with Devcert_Exit_Codes;
with Devcert_JSON;
with Devcert_Messages;
with Devcert_Secure_Files;
with Devcert;
with Devcert.Locale;

package body Devcert_Test_Suite.Output_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;

   overriding function Name (Item : Json_Escape_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON escaping");
   end Name;
   overriding procedure Run_Test (Item : in out Json_Escape_Test) is
      pragma Unreferenced (Item);
   begin
      Assert
        (Devcert_JSON.Escape ("a""b\c") = "a\""b\\c",
         "quotes and backslashes are escaped deterministically");
   end Run_Test;

   overriding function Name
     (Item : Json_Control_Escape_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON control escaping");
   end Name;
   overriding procedure Run_Test (Item : in out Json_Control_Escape_Test) is
      pragma Unreferenced (Item);
      Control : constant String := "a" & ASCII.LF & ASCII.CR & ASCII.HT
        & Character'Val (1) & "z";
   begin
      Assert
        (Devcert_JSON.Escape (Control) = "a\n\r\t?z",
         "JSON escapes line controls and masks unsupported controls");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_JSON.Status ("doctor", "line" & ASCII.LF & "two")),
            "\n") /= 0,
         "JSON envelopes escape embedded newlines");
   end Run_Test;

   overriding function Name (Item : Json_Envelope_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON envelopes");
   end Name;
   overriding procedure Run_Test (Item : in out Json_Envelope_Test) is
      pragma Unreferenced (Item);

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String :=
           Paths.Scratch ("devcert-aunit-envelope.out");
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           (Paths.Devcert_Executable, Args, Output_File, Spawned, Exit_Code,
            Err_To_Out => True);
         Output_Text :=
           (if Ada.Directories.Exists (Output_File)
            then To_Unbounded_String (Devcert_Secure_Files.Read (Output_File))
            else Null_Unbounded_String);
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         if not Spawned then
            Exit_Code := -1;
         end if;
      end Run_Devcert;

      Root   : constant String := Paths.Scratch ("devcert-aunit-envelope-root");
      Code   : Integer := 0;
      Output : Unbounded_String;

      --  The contract says every command answers in this envelope. It was only
      --  ever checked for two of them.
      procedure Assert_Envelope (Command : String) is
      begin
         Run_Devcert
           ([new String'("--ca-root"),
             new String'(Root),
             new String'("--json"),
             new String'(Command)],
            Code,
            Output);
         Assert
           (Index
              (Output,
               "{""schema_version"":1,""status"":""success"",""command"":"""
               & Command & """")
            /= 0,
            Command & " answers in the stable JSON envelope");
      end Assert_Envelope;
   begin
      Assert
        (Devcert_JSON.Status ("ca", "created") =
         "{""schema_version"":1,""status"":""success"",""command"":""ca"","
         & """message"":""created""}",
         "status envelope is deterministic");
      Assert
        (Devcert_JSON.Error ("issue", "bad name") =
         "{""schema_version"":1,""status"":""error"",""command"":""issue"","
         & """error"":""bad name""}",
         "error envelope is deterministic");

      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Assert_Envelope ("caroot");
      Assert_Envelope ("cert");
      Assert_Envelope ("inspect");
      Assert_Envelope ("doctor");
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Assert
        (Devcert_JSON.Artifact ("inspect", "fingerprint", "aa:bb") =
         "{""schema_version"":1,""status"":""success"",""command"":""inspect"","
         & """fingerprint"":""aa:bb""}",
         "artifact envelope is deterministic");
   end Run_Test;

   overriding function Name
     (Item : Localization_Message_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("devcert localization policy");
   end Name;
   overriding procedure Run_Test (Item : in out Localization_Message_Test) is
      pragma Unreferenced (Item);

      procedure Assert_Catalog_Contains
        (Path : String;
         Id   : String)
      is
         Catalog : constant String := Devcert_Secure_Files.Read (Path);
      begin
         Assert
           (Index (To_Unbounded_String (Catalog), "en." & Id & " =") /= 0,
            Path & " is missing devcert message id " & Id);
      end Assert_Catalog_Contains;

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String := Paths.Scratch ("devcert-aunit-locale.out");
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           (Paths.Devcert_Executable,
            Args,
            Output_File,
            Spawned,
            Exit_Code,
            Err_To_Out => True);
         Output_Text :=
           (if Ada.Directories.Exists (Output_File)
            then To_Unbounded_String (Devcert_Secure_Files.Read (Output_File))
            else Null_Unbounded_String);
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         if not Spawned then
            Exit_Code := -1;
         end if;
      end Run_Devcert;

      Source_Catalog  : constant String :=
        Paths.In_Repository ("config/messages/messages.catalog");
      Bundled_Catalog : constant String :=
        Paths.In_Repository ("share/devcert/messages.catalog");
      Env_Catalog     : constant String := Paths.Scratch ("devcert-aunit-env.catalog");
      CLI_Catalog     : constant String := Paths.Scratch ("devcert-aunit-cli.catalog");
      Bad_Catalog     : constant String := Paths.Scratch ("devcert-aunit-bad.catalog");
      Code            : Integer := 0;
      Output          : Unbounded_String;
   begin
      Ada.Environment_Variables.Set ("LANG", "de_DE.UTF-8");
      Ada.Environment_Variables.Set ("LC_MESSAGES", "fr_FR.UTF-8");
      Ada.Environment_Variables.Set ("LC_ALL", "C");
      Ada.Environment_Variables.Set ("DEVCERT_LOCALE", "en_GB");
      Assert
        (Devcert.Locale.Current = "en_GB",
         "DEVCERT_LOCALE overrides platform locale variables");

      Ada.Environment_Variables.Clear ("DEVCERT_LOCALE");
      Assert
        (Devcert.Locale.Current = "C",
         "LC_ALL overrides LC_MESSAGES and LANG");

      Ada.Environment_Variables.Clear ("LC_ALL");
      Assert
        (Devcert.Locale.Current = "fr_FR.UTF-8",
         "LC_MESSAGES overrides LANG");

      Ada.Environment_Variables.Clear ("LC_MESSAGES");
      Assert
        (Devcert.Locale.Current = "de_DE.UTF-8",
         "LANG is used when devcert and LC overrides are absent");

      --  And put it back. This test moves the process into another locale to
      --  prove the precedence, and everything after it renders text: left in
      --  German, the assertions below would be comparing a translation with the
      --  English they were written against.
      Ada.Environment_Variables.Clear ("LANG");
      Ada.Environment_Variables.Set ("DEVCERT_LOCALE", "en");

      Assert_Catalog_Contains (Source_Catalog, "app.name");
      Assert_Catalog_Contains (Bundled_Catalog, "app.name");
      Assert_Catalog_Contains (Source_Catalog, "cli.usage");
      Assert_Catalog_Contains (Bundled_Catalog, "cli.usage");
      Assert_Catalog_Contains (Source_Catalog, "cli.commands");
      Assert_Catalog_Contains (Bundled_Catalog, "cli.commands");
      Assert_Catalog_Contains (Source_Catalog, "cli.global_options");
      Assert_Catalog_Contains (Bundled_Catalog, "cli.global_options");
      Assert_Catalog_Contains
        (Source_Catalog, "cli.global_options_paths");
      Assert_Catalog_Contains
        (Bundled_Catalog, "cli.global_options_paths");
      Assert_Catalog_Contains (Source_Catalog, "error.devcert");
      Assert_Catalog_Contains (Bundled_Catalog, "error.devcert");
      Assert_Catalog_Contains
        (Source_Catalog, "error.missing_value");
      Assert_Catalog_Contains
        (Bundled_Catalog, "error.missing_value");
      Assert_Catalog_Contains
        (Source_Catalog, "error.duplicate_option");
      Assert_Catalog_Contains
        (Bundled_Catalog, "error.duplicate_option");
      Assert_Catalog_Contains (Source_Catalog, "error.invalid_color");
      Assert_Catalog_Contains (Bundled_Catalog, "error.invalid_color");
      Assert_Catalog_Contains (Source_Catalog, "error.unknown_option");
      Assert_Catalog_Contains (Bundled_Catalog, "error.unknown_option");
      Assert_Catalog_Contains (Source_Catalog, "error.unknown_command");
      Assert_Catalog_Contains (Bundled_Catalog, "error.unknown_command");
      Assert_Catalog_Contains
        (Source_Catalog, "error.invalid_certificate_request");
      Assert_Catalog_Contains
        (Bundled_Catalog, "error.invalid_certificate_request");
      Assert_Catalog_Contains (Source_Catalog, "error.ca_unusable");
      Assert_Catalog_Contains (Bundled_Catalog, "error.ca_unusable");
      Assert_Catalog_Contains (Source_Catalog, "error.invalid_identity");
      Assert_Catalog_Contains (Bundled_Catalog, "error.invalid_identity");
      Assert_Catalog_Contains
        (Source_Catalog, "error.mixed_identity_modes");
      Assert_Catalog_Contains
        (Bundled_Catalog, "error.mixed_identity_modes");
      Assert_Catalog_Contains (Source_Catalog, "error.csr_combination");
      Assert_Catalog_Contains (Bundled_Catalog, "error.csr_combination");
      Assert_Catalog_Contains (Source_Catalog, "cert.issued");
      Assert_Catalog_Contains (Bundled_Catalog, "cert.issued");
      Assert_Catalog_Contains (Source_Catalog, "cert.p12_written");
      Assert_Catalog_Contains (Bundled_Catalog, "cert.p12_written");
      Assert_Catalog_Contains (Source_Catalog, "inspect.ca");
      Assert_Catalog_Contains (Bundled_Catalog, "inspect.ca");
      Assert_Catalog_Contains (Source_Catalog, "doctor.ca_complete");
      Assert_Catalog_Contains (Bundled_Catalog, "doctor.ca_complete");

      Assert
        (Devcert_Messages.Text ("cli.usage") =
         "usage: devcert [global-options] <command> [command-options] [arguments]",
         "devcert renders CLI usage through its catalog wrapper");
      Assert
        (Devcert_Messages.Text ("cert.issued", "localhost") =
         "certificate issued for localhost",
         "devcert command messages accept stable value parameters");
      Assert
        (Devcert_Messages.Text ("missing.example") = "missing.example",
         "missing devcert message ids remain stable diagnostics");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_JSON.Status ("doctor", Devcert_Messages.Text ("app.name"))),
            """schema_version"":1,""status"":""success"",""command"":""doctor""")
         /= 0,
         "JSON contract field names are not localized");

      Devcert_Secure_Files.Atomic_Write
        (Env_Catalog,
         "default_locale = en" & ASCII.LF
         & "en.app.name = ""env-devcert""" & ASCII.LF
         & "en.cli.usage = ""env usage""" & ASCII.LF
         & "en.cli.commands = ""env commands""" & ASCII.LF
         & "en.cli.global_options = ""env options""" & ASCII.LF
         & "en.cli.global_options_paths = ""env paths""" & ASCII.LF);
      Devcert_Secure_Files.Atomic_Write
        (CLI_Catalog,
         "default_locale = en" & ASCII.LF
         & "en.app.name = ""cli-devcert""" & ASCII.LF
         & "en.cli.usage = ""cli usage""" & ASCII.LF
         & "en.cli.commands = ""cli commands""" & ASCII.LF
         & "en.cli.global_options = ""cli options""" & ASCII.LF
         & "en.cli.global_options_paths = ""cli paths""" & ASCII.LF);

      Ada.Environment_Variables.Set ("DEVCERT_CATALOG", Env_Catalog);
      Run_Devcert ([new String'("--plain"), new String'("help")], Code, Output);
      Assert (Code = Devcert_Exit_Codes.Success, "environment catalog help succeeds");
      Assert
        (Index (Output, "env-devcert") /= 0,
         "DEVCERT_CATALOG controls devcert catalog resolution");

      Run_Devcert
        ([new String'("--catalog"),
          new String'(CLI_Catalog),
          new String'("--plain"),
          new String'("help")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "CLI catalog help succeeds");
      Assert
        (Index (Output, "cli-devcert") /= 0,
         "--catalog overrides DEVCERT_CATALOG");
      Assert
        (Index (Output, "env-devcert") = 0,
         "environment catalog does not leak through CLI override");

      Devcert_Secure_Files.Atomic_Write
        (Bad_Catalog, "this is not a valid message catalog" & ASCII.LF);
      Run_Devcert
        ([new String'("--catalog"),
          new String'(Bad_Catalog),
          new String'("--plain"),
          new String'("help")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Success,
         "malformed catalog still permits emergency diagnostics");
      Assert
        (Index (Output, "app.name") /= 0
         and then Index (Output, "cli.usage") /= 0,
         "malformed catalog falls back to stable message identifiers");

      Ada.Environment_Variables.Clear ("DEVCERT_CATALOG");
      Ada.Environment_Variables.Clear ("LANG");
   end Run_Test;

   overriding function Name
     (Item : Security_Output_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("security output invariants");
   end Name;
   overriding procedure Run_Test (Item : in out Security_Output_Test) is
      pragma Unreferenced (Item);
      Secret : constant String := "BEGIN PRIVATE KEY";
   begin
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_JSON.Status ("cert", "certificate issued for localhost")),
            Secret) = 0,
         "status JSON does not contain private-key marker");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_JSON.Error ("cert", "invalid certificate request")),
            Secret) = 0,
         "error JSON does not contain private-key marker");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_JSON.Artifact ("cert", "path", Paths.Scratch ("cert.pem"))),
            Secret) = 0,
         "artifact JSON does not contain private-key marker");
   end Run_Test;

   overriding function Name (Item : Translation_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("translations render as the bytes they were written in");
   end Name;

   --  Two things this locks, both found the hard way.
   --
   --  The catalog carries a locale for every European language, and each
   --  locale must keep the {value} argument the English carries: a translation
   --  that dropped it would print a message with the filename missing from it,
   --  and nothing else would fail.
   --
   --  And the text has to survive being printed. Alire builds with -gnatW8,
   --  which tells the binder to encode every byte above 127 on the way out --
   --  so UTF-8 text came out doubled, and every accented language was mojibake.
   --  That was true of an accented path or an internationalized domain name
   --  long before there was anything to translate.
   overriding procedure Run_Test (Item : in out Translation_Test) is
      pragma Unreferenced (Item);

      Catalog : constant String :=
        Paths.In_Repository ("config/messages/messages.catalog");

      Doubled : constant String :=
        Character'Val (16#C3#) & Character'Val (16#83#)
        & Character'Val (16#C2#);

      File    : Ada.Text_IO.File_Type;
      Locales : Natural := 0;
      With_Value   : Natural := 0;

      function Names_The_Value (Line : String) return Boolean is
        (Ada.Strings.Fixed.Index (Line, "{value}") /= 0);

      function Key_Of (Line : String) return String is
         Dot   : constant Natural := Ada.Strings.Fixed.Index (Line, ".");
         Space : constant Natural := Ada.Strings.Fixed.Index (Line, " = ");
      begin
         if Dot = 0 or else Space = 0 or else Space < Dot then
            return "";
         end if;
         return Line (Dot + 1 .. Space - 1);
      end Key_Of;

      function Locale_Of (Line : String) return String is
         Dot : constant Natural := Ada.Strings.Fixed.Index (Line, ".");
      begin
         return (if Dot = 0 then "" else Line (Line'First .. Dot - 1));
      end Locale_Of;

      English : Unbounded_String;
   begin
      --  Every English line, so a translation can be checked against its own.
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Catalog);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Line'Length > 3 and then Line (Line'First .. Line'First + 2) = "en." then
               Append (English, Line & ASCII.LF);
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Catalog);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line   : constant String := Ada.Text_IO.Get_Line (File);
            Locale : constant String := Locale_Of (Line);
            Key    : constant String := Key_Of (Line);
         begin
            if Key /= "" and then Locale /= "" and then Locale /= "en"
              and then Locale /= "default_locale"
            then
               Locales := Locales + 1;
               declare
                  Own : constant Natural :=
                    Index (English, "en." & Key & " = ");
                  Stop : Natural;
               begin
                  Assert (Own /= 0, "translated key " & Key & " exists in English");
                  Stop := Index (English, "" & ASCII.LF, Own);
                  declare
                     Source : constant String :=
                       Slice (English, Own, Stop - 1);
                  begin
                     if Names_The_Value (Source) then
                        With_Value := With_Value + 1;
                        Assert
                          (Names_The_Value (Line),
                           Locale & "." & Key & " keeps its {value} argument");
                     end if;
                  end;
               end;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      Assert (Locales > 500, "the catalog carries the translations");
      Assert (With_Value > 100, "and the {value} rule was exercised");

      --  Printed, not merely stored: a doubled UTF-8 lead byte is what the
      --  binder encoding did to every accented character.
      declare
         Code    : Integer := 0;
         Spawned : Boolean := False;
         Output  : Unbounded_String;
         Log     : constant String := Paths.Scratch ("devcert-aunit-i18n.out");
      begin
         Ada.Environment_Variables.Set ("DEVCERT_LOCALE", "de");
         GNAT.OS_Lib.Spawn
           (Paths.Devcert_Executable,
            [new String'("--plain"),
             new String'("--color=definitely-not-a-color")],
            Log,
            Spawned,
            Code,
            Err_To_Out => True);
         Ada.Environment_Variables.Set ("DEVCERT_LOCALE", "en");
         Output :=
           (if Ada.Directories.Exists (Log)
            then To_Unbounded_String (Devcert_Secure_Files.Read (Log))
            else Null_Unbounded_String);
         if Ada.Directories.Exists (Log) then
            Ada.Directories.Delete_File (Log);
         end if;
         Assert (Spawned, "devcert runs for the translation check");

         Assert
           (Index (Output, Doubled) = 0,
            "an accented message is printed as the UTF-8 it was written in");
         Assert
           (Index (Output, "--color") /= 0,
            "and it is the message about --color that was printed");
      end;
   end Run_Test;

end Devcert_Test_Suite.Output_Tests;
