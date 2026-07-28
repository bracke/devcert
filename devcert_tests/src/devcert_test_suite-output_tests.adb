with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings;
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
        Paths.In_Repository ("config/messages/en.catalog");
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

end Devcert_Test_Suite.Output_Tests;
