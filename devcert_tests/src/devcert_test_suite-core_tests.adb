with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Devcert_Core;
with Devcert_Crypto;
with Devcert_Exit_Codes;
with Devcert_JSON;
with Devcert_Messages;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert_Trust_Stores;
with Devcert;
with Devcert.CA_Store;
with Devcert.Clock;
with Devcert.Certificate_Policies;
with Devcert.Certificate_Requests;
with Devcert.Context;
with Devcert.Errors;
with Devcert.Identities;
with Devcert.Locks;
with Devcert.Locale;
with Devcert.Processes;
with Devcert.Results;
with Devcert.Trust_Stores.Java;
with Devcert.Trust_Stores.NSS;
with Devcert.Trust_Stores.System;
with Devcert.Trust_Stores.System.Linux;
with Devcert.Trust_Stores.System.MacOS;
with Devcert.Trust_Stores.System.Windows;
with Devcert.Version;

package body Devcert_Test_Suite.Core_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type Devcert_Crypto.Operation_Status;
   use type Devcert_Trust_Stores.Trust_State;
   use type Devcert_Trust_Stores.Trust_Store_Kind;
   use type Devcert_Trust_Stores.Trust_Target;
   use type Devcert.CA_Store.CA_State;
   use type Devcert.Certificate_Requests.Certificate_Mode;
   use type Devcert.Certificate_Requests.Request_Status;
   use type Devcert.Errors.Error_Kind;
   use type Devcert.Identities.Identity_Kind;
   use type Devcert.Locks.Lock_Result;

   procedure Reset_Temp_Home (Name : String) is
      Path : constant String := "/tmp/devcert-aunit-" & Name;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
      Ada.Environment_Variables.Set ("DEVCERT_HOME", Path & "-legacy");
      Ada.Environment_Variables.Set ("DEVCERT_CAROOT", Path);
   end Reset_Temp_Home;

   overriding function Name (Item : Version_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("runtime version");
   end Name;

   overriding procedure Run_Test (Item : in out Version_Test) is
      pragma Unreferenced (Item);
   begin
      Assert (Devcert_Core.Version = "0.1.0-dev", "unexpected devcert version");
   end Run_Test;

   overriding function Name (Item : Json_Schema_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON schema version");
   end Name;

   overriding procedure Run_Test (Item : in out Json_Schema_Test) is
      pragma Unreferenced (Item);
   begin
      Assert
        (Devcert_Core.Json_Schema_Version = "1",
         "unexpected JSON schema version");
   end Run_Test;

   overriding function Name (Item : Exit_Code_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("stable exit codes");
   end Name;

   overriding procedure Run_Test (Item : in out Exit_Code_Test) is
      pragma Unreferenced (Item);
      function Code (Value : Integer) return Integer is
      begin
         return Value;
      end Code;
   begin
      Assert (Code (Devcert_Exit_Codes.Success) = 0, "success exit code is stable");
      Assert
        (Code (Devcert_Exit_Codes.General_Failure) = 1,
         "general failure code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Usage_Error) = 2,
         "usage error code is stable");
      Assert
        (Code (Devcert_Exit_Codes.CA_State_Error) = 3,
         "CA state code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Certificate_Error) = 4,
         "certificate code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Cryptographic_Error) = 5,
         "crypto code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Trust_Store_Error) = 6,
         "trust-store code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Permission_Error) = 7,
         "permission code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Partial_Success) = 8,
         "partial success code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Unsupported_Feature) = 9,
         "unsupported code is stable");
      Assert
        (Code (Devcert_Exit_Codes.Localization_Error) = 10,
         "localization code is stable");
   end Run_Test;

   overriding function Name
     (Item : Architecture_Surface_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("architecture package surface");
   end Name;

   overriding procedure Run_Test (Item : in out Architecture_Surface_Test) is
      pragma Unreferenced (Item);
      Context : Devcert.Context.Runtime_Context;
      Request : constant Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Policies.Default_Request;
      Result  : constant Devcert.Results.Result := Devcert.Results.Ok;

      function Same_Target
        (Left  : Devcert_Trust_Stores.Trust_Target;
         Right : Devcert_Trust_Stores.Trust_Target) return Boolean is
      begin
         return Left = Right;
      end Same_Target;

      function Same_Text (Left : String; Right : String) return Boolean is
      begin
         return Left = Right;
      end Same_Text;
   begin
      Assert
        (Same_Text (Devcert.Name, "devcert"),
         "root package owns project identity");
      Assert
        (Same_Text (Devcert.Version.Image, Devcert_Core.Version),
         "version facade is wired");
      Assert
        (Devcert.CA_Store.Root = Devcert_State.Base_Directory,
         "CA store facade uses state root");
      Assert
        (Request.Mode = Devcert.Certificate_Requests.Server,
         "default certificate request is server mode");
      Assert
        (Devcert.Identities.Is_Valid_DNS ("localhost"),
         "identity layer accepts localhost DNS");
      Assert
        (Devcert.Locale.Current'Length > 0,
         "locale layer reports a locale");
      Assert
        (Result.Error = Devcert.Errors.None,
         "result layer carries stable error kind");
      Assert
        (Devcert.Processes.Locate ("definitely-not-devcert-tool") = "",
         "process layer reports missing executables deterministically");
      Assert
        (Devcert.Locks.Acquire ("/tmp/devcert-aunit-architecture.lock")
         = Devcert.Locks.Acquired,
         "lock layer exposes writer serialization primitive");
      Devcert.Locks.Release ("/tmp/devcert-aunit-architecture.lock");
      Assert
        (Devcert_Trust_Stores.Name (Devcert.Trust_Stores.System.Default_Target)
         /= "",
         "system trust facade reports a named target");
      Assert
        (Same_Target
           (Devcert.Trust_Stores.System.Linux.Target, Devcert_Trust_Stores.Linux),
         "Linux trust facade is wired");
      Assert
        (Same_Target
           (Devcert.Trust_Stores.System.MacOS.Target, Devcert_Trust_Stores.MacOS),
         "macOS trust facade is wired");
      Assert
        (Same_Target
           (Devcert.Trust_Stores.System.Windows.Target,
            Devcert_Trust_Stores.Windows),
         "Windows trust facade is wired");
      Assert
        (Same_Target (Devcert.Trust_Stores.NSS.Target, Devcert_Trust_Stores.NSS),
         "NSS trust facade is wired");
      Assert
        (Same_Target
           (Devcert.Trust_Stores.Java.Target, Devcert_Trust_Stores.Java),
         "Java trust facade is wired");
      Assert (not Context.JSON_Output, "default context is human output");
   end Run_Test;

   overriding function Name (Item : CLI_Contract_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("CLI contract and no-mutation errors");
   end Name;

   overriding procedure Run_Test (Item : in out CLI_Contract_Test) is
      pragma Unreferenced (Item);

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String := "/tmp/devcert-aunit-cli.out";
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           ("./bin/devcert",
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

      Unknown_Root : constant String := "/tmp/devcert-aunit-cli-unknown";
      Option_Root  : constant String := "/tmp/devcert-aunit-cli-option";
      Env_Root     : constant String := "/tmp/devcert-aunit-cli-env-root";
      Env_Override : constant String := "/tmp/devcert-aunit-cli-env-override";
      CLI_Root     : constant String := "/tmp/devcert-aunit-cli-override-root";
      Dup_Root     : constant String := "/tmp/devcert-aunit-cli-duplicate";
      Trust_Root   : constant String := "/tmp/devcert-aunit-cli-trust-root";
      Trust_Dir    : constant String := "/tmp/devcert-aunit-cli-trust-dir";
      Bad_Env_Root : constant String := "/tmp/devcert-aunit-cli-bad-env";
      Profile_Root : constant String := "/tmp/devcert-aunit-cli-profile";
      CSR_Root     : constant String := "/tmp/devcert-aunit-cli-csr";
      Password_Root : constant String := "/tmp/devcert-aunit-cli-password";
      CSR_Path     : constant String := "/tmp/devcert-aunit-cli.csr";
      Password_Path : constant String := "/tmp/devcert-aunit-cli.password";
      Code         : Integer := 0;
      Output       : Unbounded_String;
   begin
      if Ada.Directories.Exists (Unknown_Root) then
         Ada.Directories.Delete_Tree (Unknown_Root);
      end if;
      if Ada.Directories.Exists (Option_Root) then
         Ada.Directories.Delete_Tree (Option_Root);
      end if;
      if Ada.Directories.Exists (Env_Root) then
         Ada.Directories.Delete_Tree (Env_Root);
      end if;
      if Ada.Directories.Exists (CLI_Root) then
         Ada.Directories.Delete_Tree (CLI_Root);
      end if;
      if Ada.Directories.Exists (Env_Override) then
         Ada.Directories.Delete_Tree (Env_Override);
      end if;
      if Ada.Directories.Exists (Dup_Root) then
         Ada.Directories.Delete_Tree (Dup_Root);
      end if;
      if Ada.Directories.Exists (Trust_Root) then
         Ada.Directories.Delete_Tree (Trust_Root);
      end if;
      if Ada.Directories.Exists (Trust_Dir) then
         Ada.Directories.Delete_Tree (Trust_Dir);
      end if;
      if Ada.Directories.Exists (Bad_Env_Root) then
         Ada.Directories.Delete_Tree (Bad_Env_Root);
      end if;
      if Ada.Directories.Exists (Profile_Root) then
         Ada.Directories.Delete_Tree (Profile_Root);
      end if;
      if Ada.Directories.Exists (CSR_Root) then
         Ada.Directories.Delete_Tree (CSR_Root);
      end if;
      if Ada.Directories.Exists (Password_Root) then
         Ada.Directories.Delete_Tree (Password_Root);
      end if;
      if Ada.Directories.Exists (CSR_Path) then
         Ada.Directories.Delete_File (CSR_Path);
      end if;
      if Ada.Directories.Exists (Password_Path) then
         Ada.Directories.Delete_File (Password_Path);
      end if;

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Unknown_Root),
          new String'("--plain"),
          new String'("definitely-not-a-command")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Usage_Error, "unknown command is usage");
      Assert
        (Index (Output, "unknown command") /= 0,
         "unknown command emits deterministic diagnostic");
      Assert
        (not Ada.Directories.Exists (Unknown_Root),
         "unknown command does not create CA root");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Option_Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("--definitely-bad")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "unknown cert option is usage");
      Assert
        (Index (Output, "unknown cert option --definitely-bad") /= 0,
         "unknown cert option emits deterministic diagnostic");
      Assert
        (not Ada.Directories.Exists (Option_Root),
         "unknown cert option does not create CA root");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Profile_Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("localhost"),
          new String'("--client")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "profile option after identity is usage");
      Assert
        (Index (Output, "profile option must precede identities") /= 0,
         "profile ordering diagnostic is deterministic");
      Assert
        (not Ada.Directories.Exists (Profile_Root),
         "profile ordering error does not create CA root");

      Devcert_Secure_Files.Atomic_Write
        (CSR_Path, "-----BEGIN CERTIFICATE REQUEST-----" & ASCII.LF);
      Run_Devcert
        ([new String'("--ca-root"),
          new String'(CSR_Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("--csr"),
          new String'(CSR_Path),
          new String'("--pkcs12")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "CSR with PKCS#12 is usage");
      Assert
        (Index (Output, "--csr cannot be combined") /= 0,
         "CSR combination diagnostic is deterministic");
      Assert
        (not Ada.Directories.Exists (CSR_Root),
         "CSR combination error does not create CA root");

      Devcert_Secure_Files.Atomic_Write (Password_Path, "secret");
      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Password_Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("--pkcs12"),
          new String'("--p12-password-file"),
          new String'(Password_Path),
          new String'("--p12-password-stdin")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "duplicate PKCS#12 password source is usage");
      Assert
        (Index (Output, "duplicate PKCS#12 password option") /= 0,
         "duplicate PKCS#12 password diagnostic is deterministic");
      Assert
        (not Ada.Directories.Exists (Password_Root),
         "duplicate PKCS#12 password error does not create CA root");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Dup_Root),
          new String'("--plain"),
          new String'("--plain"),
          new String'("version")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "duplicate global singleton option is usage");
      Assert
        (Index (Output, "duplicate option --plain") /= 0,
         "duplicate global option diagnostic is deterministic");
      Assert
        (not Ada.Directories.Exists (Dup_Root),
         "duplicate global option does not create CA root");

      Ada.Environment_Variables.Set ("DEVCERT_CAROOT", Env_Root);
      Run_Devcert
        ([new String'("--plain"), new String'("cert"), new String'("localhost")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "DEVCERT_CAROOT cert succeeds");
      Assert
        (Ada.Directories.Exists (Env_Root & "/rootCA.pem"),
         "DEVCERT_CAROOT controls CA root when --ca-root is absent");

      Ada.Environment_Variables.Set ("DEVCERT_CAROOT", Env_Override);
      Run_Devcert
        ([new String'("--ca-root"),
          new String'(CLI_Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("localhost")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "--ca-root cert succeeds");
      Assert
        (Ada.Directories.Exists (CLI_Root & "/rootCA.pem"),
         "--ca-root overrides DEVCERT_CAROOT");
      Assert
        (not Ada.Directories.Exists (Env_Override),
         "--ca-root prevents mutation of DEVCERT_CAROOT directory");
      Ada.Environment_Variables.Clear ("DEVCERT_CAROOT");

      Ada.Environment_Variables.Set ("DEVCERT_TRUST_STORES", "definitely-bad");
      Ada.Environment_Variables.Set ("DEVCERT_LINUX_TRUST_DIR", Trust_Dir);
      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Trust_Root),
          new String'("--plain"),
          new String'("install"),
          new String'("--trust-store"),
          new String'("system")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Success,
         "--trust-store overrides invalid DEVCERT_TRUST_STORES");
      Assert
        (Ada.Directories.Exists (Trust_Dir),
         "trust-store CLI override reaches isolated Linux backend");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Bad_Env_Root),
          new String'("--plain"),
          new String'("install")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Usage_Error,
         "invalid DEVCERT_TRUST_STORES is rejected when no CLI override exists");
      Assert
        (Index (Output, "unknown trust store: definitely-bad") /= 0,
         "invalid trust-store environment diagnostic is deterministic");
      Assert
        (not Ada.Directories.Exists (Bad_Env_Root),
         "invalid trust-store environment does not create CA root");
      Ada.Environment_Variables.Clear ("DEVCERT_TRUST_STORES");
      Ada.Environment_Variables.Clear ("DEVCERT_LINUX_TRUST_DIR");
   end Run_Test;

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

   overriding function Name (Item : Output_Mode_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("output mode routing");
   end Name;

   overriding procedure Run_Test (Item : in out Output_Mode_Test) is
      pragma Unreferenced (Item);

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String := "/tmp/devcert-aunit-output.out";
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           ("./bin/devcert",
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

      Code   : Integer := 0;
      Output : Unbounded_String;
   begin
      Run_Devcert
        ([new String'("--json"), new String'("version")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "JSON version command succeeds");
      Assert
        (Index
           (Output,
            "{""schema_version"":1,""status"":""success"",""command"":""version""")
         /= 0,
         "JSON mode uses stable devcert envelope fields");
      Assert
        (Index (Output, Character'Val (16#1B#) & "[") = 0,
         "JSON output contains no ANSI escapes");

      Run_Devcert
        ([new String'("--plain"), new String'("version")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "plain version command succeeds");
      Assert
        (Index (Output, Devcert_Core.Version) /= 0,
         "plain artifact output contains the version value");
      Assert
        (Index (Output, Character'Val (16#1B#) & "[") = 0,
         "plain output contains no ANSI escapes");

      Run_Devcert
        ([new String'("--color=always"), new String'("version")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Success,
         "forced terminal color version command succeeds");
      Assert
        (Index (Output, "[*] " & Devcert_Core.Version) /= 0,
         "--color=always routes through terminal styling");

      Run_Devcert
        ([new String'("--color=never"), new String'("version")],
         Code,
         Output);
      Assert
        (Code = Devcert_Exit_Codes.Success,
         "color-never version command succeeds");
      Assert
        (Index (Output, "[*]") = 0,
         "--color=never routes through plain output");

      Ada.Environment_Variables.Set ("NO_COLOR", "1");
      Run_Devcert ([new String'("version")], Code, Output);
      Ada.Environment_Variables.Clear ("NO_COLOR");
      Assert (Code = Devcert_Exit_Codes.Success, "NO_COLOR version command succeeds");
      Assert
        (Index (Output, Character'Val (16#1B#) & "[") = 0,
         "NO_COLOR selects unstyled output in auto color mode");
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
         Output_File : constant String := "/tmp/devcert-aunit-locale.out";
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           ("./bin/devcert",
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

      Env_Catalog : constant String := "/tmp/devcert-aunit-env.catalog";
      CLI_Catalog : constant String := "/tmp/devcert-aunit-cli.catalog";
      Bad_Catalog : constant String := "/tmp/devcert-aunit-bad.catalog";
      Code        : Integer := 0;
      Output      : Unbounded_String;
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

      Assert_Catalog_Contains ("config/messages/en.catalog", "app.name");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "app.name");
      Assert_Catalog_Contains ("config/messages/en.catalog", "cli.usage");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "cli.usage");
      Assert_Catalog_Contains ("config/messages/en.catalog", "cli.commands");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "cli.commands");
      Assert_Catalog_Contains ("config/messages/en.catalog", "cli.global_options");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "cli.global_options");
      Assert_Catalog_Contains
        ("config/messages/en.catalog", "cli.global_options_paths");
      Assert_Catalog_Contains
        ("share/devcert/messages.catalog", "cli.global_options_paths");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.devcert");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.devcert");
      Assert_Catalog_Contains
        ("config/messages/en.catalog", "error.missing_value");
      Assert_Catalog_Contains
        ("share/devcert/messages.catalog", "error.missing_value");
      Assert_Catalog_Contains
        ("config/messages/en.catalog", "error.duplicate_option");
      Assert_Catalog_Contains
        ("share/devcert/messages.catalog", "error.duplicate_option");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.invalid_color");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.invalid_color");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.unknown_option");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.unknown_option");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.unknown_command");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.unknown_command");
      Assert_Catalog_Contains
        ("config/messages/en.catalog", "error.invalid_certificate_request");
      Assert_Catalog_Contains
        ("share/devcert/messages.catalog", "error.invalid_certificate_request");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.ca_unusable");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.ca_unusable");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.invalid_identity");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.invalid_identity");
      Assert_Catalog_Contains
        ("config/messages/en.catalog", "error.mixed_identity_modes");
      Assert_Catalog_Contains
        ("share/devcert/messages.catalog", "error.mixed_identity_modes");
      Assert_Catalog_Contains ("config/messages/en.catalog", "error.csr_combination");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "error.csr_combination");
      Assert_Catalog_Contains ("config/messages/en.catalog", "cert.issued");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "cert.issued");
      Assert_Catalog_Contains ("config/messages/en.catalog", "cert.p12_written");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "cert.p12_written");
      Assert_Catalog_Contains ("config/messages/en.catalog", "inspect.ca");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "inspect.ca");
      Assert_Catalog_Contains ("config/messages/en.catalog", "doctor.ca_complete");
      Assert_Catalog_Contains ("share/devcert/messages.catalog", "doctor.ca_complete");

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

   overriding function Name (Item : Fingerprint_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("cryptolib SHA-256 fingerprint");
   end Name;

   overriding procedure Run_Test (Item : in out Fingerprint_Test) is
      pragma Unreferenced (Item);
   begin
      Assert
        (Devcert_Crypto.SHA256_Fingerprint ("") =
         "e3:b0:c4:42:98:fc:1c:14:9a:fb:f4:c8:99:6f:b9:24:"
         & "27:ae:41:e4:64:9b:93:4c:a4:95:99:1b:78:52:b8:55",
         "empty input SHA-256 fingerprint must match the standard digest");
   end Run_Test;

   overriding function Name (Item : State_Path_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("state paths");
   end Name;

   overriding procedure Run_Test (Item : in out State_Path_Test) is
      pragma Unreferenced (Item);
   begin
      Reset_Temp_Home ("state");
      Assert
        (Devcert_State.Base_Directory = "/tmp/devcert-aunit-state",
         "DEVCERT_CAROOT controls the base directory");
      Assert
        (Devcert_State.CA_Certificate_Path =
         "/tmp/devcert-aunit-state/rootCA.pem",
         "CA certificate path is stable");
      Assert
        (Devcert_State.CA_Metadata_Path =
         "/tmp/devcert-aunit-state/ca-metadata.txt",
         "CA metadata path is stable");
      Assert
        (Devcert_State.Leaf_Private_Key_Path ("localhost") =
         "/tmp/devcert-aunit-state/issued/localhost-key.pem",
         "leaf key path is stable");
   end Run_Test;

   overriding function Name (Item : Clock_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("clock abstraction");
   end Name;

   overriding procedure Run_Test (Item : in out Clock_Test) is
      pragma Unreferenced (Item);
   begin
      Devcert.Clock.Set_Test_Time ("2024-02-29 10:11:12");
      Assert
        (Devcert.Clock.Now = "2024-02-29 10:11:12",
         "fake clock returns deterministic time");
      Devcert.Clock.Reset_Test_Time;
      Assert
        (Devcert.Clock.Now'Length >= 19,
         "production clock returns formatted time");
   end Run_Test;

   overriding function Name (Item : Lock_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("lock serialization");
   end Name;

   overriding procedure Run_Test (Item : in out Lock_Test) is
      pragma Unreferenced (Item);
      Path : constant String := "/tmp/devcert-aunit-locks/create.lock";
   begin
      if Ada.Directories.Exists ("/tmp/devcert-aunit-locks") then
         Ada.Directories.Delete_Tree ("/tmp/devcert-aunit-locks");
      end if;
      Assert
        (Devcert.Locks.Acquire (Path) = Devcert.Locks.Acquired,
         "first writer acquires lock");
      Assert
        (Devcert.Locks.Acquire (Path) = Devcert.Locks.Already_Held,
         "second writer observes held lock");
      Devcert.Locks.Release (Path);
      Assert
        (Devcert.Locks.Acquire (Path) = Devcert.Locks.Acquired,
         "released lock can be acquired again");
      Devcert.Locks.Release (Path);
   end Run_Test;

   overriding function Name (Item : CA_Lifecycle_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("CA lifecycle state evaluation");
   end Name;

   overriding procedure Run_Test (Item : in out CA_Lifecycle_Test) is
      pragma Unreferenced (Item);
      Created : Devcert.CA_Store.CA_State;
   begin
      Reset_Temp_Home ("ca-lifecycle");
      Devcert.Clock.Set_Test_Time ("2024-02-29 10:11:12");
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Missing,
         "empty CA root is missing");

      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Certificate_Path, "not a certificate");
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Incomplete,
         "partial CA root is incomplete");

      Ada.Directories.Delete_Tree ("/tmp/devcert-aunit-ca-lifecycle");
      Reset_Temp_Home ("ca-lifecycle");
      Created := Devcert.CA_Store.Ensure;
      Assert
        (Created = Devcert.CA_Store.Complete,
         "ensure creates a complete local CA");
      Assert
        (Devcert_Secure_Files.Exists (Devcert_State.CA_Metadata_Path),
         "CA creation writes metadata");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_Secure_Files.Read (Devcert_State.CA_Metadata_Path)),
            "created-at=2024-02-29 10:11:12") /= 0,
         "CA metadata uses deterministic clock");
      Assert
        (Devcert_Secure_Files.Exists (Devcert_State.Issued_Directory),
         "CA creation writes issued directory");
      Assert
        (Devcert_Secure_Files.Has_Permissions
           (Devcert_State.Base_Directory, "700"),
         "CA root has secure permissions");
      Assert
        (Devcert_Secure_Files.Has_Permissions
           (Devcert_State.CA_Private_Key_Path, "600"),
         "CA private key has secure permissions");
      Assert
        (Devcert_Secure_Files.Has_Permissions
           (Devcert_State.CA_Certificate_Path, "644"),
         "CA certificate has public-read permissions");

      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Metadata_Path,
         "format-version=1" & ASCII.LF
         & "managed-by=devcert" & ASCII.LF
         & "created-at=unknown" & ASCII.LF
         & "key-algorithm=Ed25519" & ASCII.LF
         & "certificate-fingerprint=bad" & ASCII.LF,
         Secret => True);
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Invalid_Metadata,
         "metadata fingerprint mismatch is rejected");
      Created := Devcert.CA_Store.Ensure;
      Assert
        (Created = Devcert.CA_Store.Invalid_Metadata,
         "ensure does not replace an invalid existing CA");
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Metadata_Path,
         "managed-by=devcert" & ASCII.LF
         & "created-at=unknown" & ASCII.LF
         & "key-algorithm=Ed25519" & ASCII.LF
         & "certificate-fingerprint="
         & Devcert_Crypto.SHA256_Fingerprint
           (Devcert_Secure_Files.Read (Devcert_State.CA_Certificate_Path))
         & ASCII.LF,
         Secret => True);
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Invalid_Metadata,
         "metadata without format version is rejected");
      Devcert_Secure_Files.Ensure_Directory (Devcert_State.Base_Directory, "755");
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Unsafe_Permissions,
         "unsafe CA root permissions are rejected");
      Devcert.Clock.Reset_Test_Time;
   end Run_Test;

   overriding function Name
     (Item : CA_Invalid_Material_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("CA invalid material states");
   end Name;

   overriding procedure Run_Test (Item : in out CA_Invalid_Material_Test) is
      pragma Unreferenced (Item);
      First_Cert  : Unbounded_String;
      First_Key   : Unbounded_String;
      Second_Cert : Unbounded_String;
      Second_Key  : Unbounded_String;

      procedure Write_CA
        (Certificate : String;
         Private_Key : String) is
      begin
         Devcert_Secure_Files.Ensure_Directory (Devcert_State.Base_Directory, "700");
         Devcert_Secure_Files.Ensure_Directory
           (Devcert_State.Issued_Directory, "700");
         Devcert_Secure_Files.Atomic_Write
           (Devcert_State.CA_Certificate_Path, Certificate);
         Devcert_Secure_Files.Atomic_Write
           (Devcert_State.CA_Private_Key_Path, Private_Key, Secret => True);
         Devcert_Secure_Files.Atomic_Write
           (Devcert_State.CA_Metadata_Path,
            "format-version=1" & ASCII.LF
            & "managed-by=devcert" & ASCII.LF
            & "created-at=test" & ASCII.LF
            & "key-algorithm=Ed25519" & ASCII.LF
            & "certificate-fingerprint="
            & Devcert_Crypto.SHA256_Fingerprint
              (Devcert_Secure_Files.Read (Devcert_State.CA_Certificate_Path))
            & ASCII.LF,
            Secret => True);
      end Write_CA;
   begin
      Reset_Temp_Home ("invalid-cert");
      Write_CA
        ("not a certificate",
         "-----BEGIN PRIVATE KEY-----" & ASCII.LF
         & "x" & ASCII.LF
         & "-----END PRIVATE KEY-----" & ASCII.LF);
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Invalid_Certificate,
         "CA evaluator rejects invalid certificate material");

      Reset_Temp_Home ("invalid-key");
      Write_CA
        ("-----BEGIN CERTIFICATE-----" & ASCII.LF
         & "x" & ASCII.LF
         & "-----END CERTIFICATE-----" & ASCII.LF,
         "not a private key");
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Invalid_Private_Key,
         "CA evaluator rejects invalid private-key material");

      Reset_Temp_Home ("mismatched-ca-key");
      Assert
        (Devcert_Crypto.Create_CA (First_Cert, First_Key) = Devcert_Crypto.Ok,
         "first CA material is generated for mismatch test");
      Assert
        (Devcert_Crypto.Create_CA (Second_Cert, Second_Key) = Devcert_Crypto.Ok,
         "second CA material is generated for mismatch test");
      Assert
        (Devcert_Crypto.Private_Key_Matches_Certificate
           (To_String (First_Cert), To_String (Second_Key))
         = Devcert_Crypto.Invalid_Request,
         "crypto adapter rejects certificate/private-key mismatch");
      Write_CA (To_String (First_Cert), To_String (Second_Key));
      declare
         State : constant Devcert.CA_Store.CA_State := Devcert.CA_Store.Evaluate;
      begin
         Assert
           (State = Devcert.CA_Store.Certificate_Key_Mismatch,
            "CA evaluator rejects certificate/private-key mismatch; got "
            & Devcert.CA_Store.State_Image (State));
      end;
   end Run_Test;

   overriding function Name (Item : Secure_File_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("secure file writes");
   end Name;

   overriding procedure Run_Test (Item : in out Secure_File_Test) is
      pragma Unreferenced (Item);
      Path : constant String := "/tmp/devcert-aunit-files/nested/value.txt";
      Raw_Path : constant String := "/tmp/devcert-aunit-files/nested/value.der";
   begin
      Reset_Temp_Home ("files");
      if Ada.Directories.Exists ("/tmp/devcert-aunit-files") then
         Ada.Directories.Delete_Tree ("/tmp/devcert-aunit-files");
      end if;
      Devcert_Secure_Files.Atomic_Write (Path, "alpha" & ASCII.LF, Secret => True);
      Assert (Devcert_Secure_Files.Exists (Path), "atomic write creates file");
      Assert (not Devcert_Secure_Files.Exists (Path & ".tmp"), "temp file is renamed");
      Assert
        (Devcert_Secure_Files.Read (Path) = "alpha",
         "secure read returns text without adding data");
      Assert
        (Devcert_Secure_Files.Has_Permissions (Path, "600"),
         "secret atomic write applies private permissions");

      Devcert_Secure_Files.Atomic_Write (Path, "beta", Secret => False);
      Assert
        (Devcert_Secure_Files.Read (Path) = "beta",
         "atomic overwrite replaces complete file content");
      Assert
        (Devcert_Secure_Files.Has_Permissions (Path, "644"),
         "public atomic write applies public certificate permissions");
      Assert
        (not Devcert_Secure_Files.Exists (Path & ".tmp"),
         "atomic overwrite leaves no temporary file");

      Devcert_Secure_Files.Atomic_Write_Raw
        (Raw_Path, Character'Val (16#30#) & Character'Val (16#03#) & "abc");
      Assert
        (Devcert_Secure_Files.Exists (Raw_Path),
         "raw atomic write creates artifact file");
      Assert
        (not Devcert_Secure_Files.Exists (Raw_Path & ".tmp"),
         "raw atomic write leaves no temporary file");
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
              (Devcert_JSON.Artifact ("cert", "path", "/tmp/cert.pem")),
            Secret) = 0,
         "artifact JSON does not contain private-key marker");
   end Run_Test;

   overriding function Name
     (Item : Certificate_Boundary_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("cryptolib certificate boundary");
   end Name;

   overriding procedure Run_Test (Item : in out Certificate_Boundary_Test) is
      pragma Unreferenced (Item);
      Cert : Unbounded_String;
      Key  : Unbounded_String;
   begin
      Assert
        (Devcert_Crypto.Create_CA (Cert, Key) = Devcert_Crypto.Ok,
         "CA creation succeeds through devcert crypto boundary");
      Assert
        (Index (Cert, "BEGIN CERTIFICATE") /= 0,
         "CA certificate is PEM encoded");
      Assert
        (Index (Key, "BEGIN PRIVATE KEY") /= 0,
         "CA private key is PKCS#8 PEM");
   end Run_Test;

   overriding function Name
     (Item : Identity_Validation_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("identity validation");
   end Name;

   overriding procedure Run_Test (Item : in out Identity_Validation_Test) is
      pragma Unreferenced (Item);
      Kind : Devcert.Identities.Identity_Kind;
   begin
      Assert
        (Devcert.Identities.Normalize (" Example.TEST ") = "example.test",
         "identities normalize to trimmed lowercase text");
      Assert
        (Devcert.Identities.Classify ("localhost", Kind)
         and then Kind = Devcert.Identities.DNS,
         "localhost is a DNS identity");
      Assert
        (Devcert.Identities.Classify ("*.example.test", Kind)
         and then Kind = Devcert.Identities.DNS,
         "single-label wildcard is accepted");
      Assert
        (not Devcert.Identities.Is_Valid_DNS ("*"),
         "bare wildcard is rejected");
      Assert
        (not Devcert.Identities.Is_Valid_DNS ("bad..example"),
         "empty DNS labels are rejected");
      Assert
        (Devcert.Identities.Classify ("127.0.0.1", Kind)
         and then Kind = Devcert.Identities.IPv4,
         "IPv4 identities are classified");
      Assert
        (not Devcert.Identities.Is_Valid_IPv4 ("127.0.0.999"),
         "out-of-range IPv4 identities are rejected");
      Assert
        (Devcert.Identities.Classify ("::1", Kind)
         and then Kind = Devcert.Identities.IPv6,
         "IPv6 identities are classified");
      Assert
        (Devcert.Identities.Classify ("user@example.test", Kind)
         and then Kind = Devcert.Identities.Email,
         "email identities are classified");
      Assert
        (not Devcert.Identities.Is_Valid_Email ("user@"),
         "malformed email identities are rejected");
   end Run_Test;

   overriding function Name
     (Item : Certificate_Request_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("certificate request policy");
   end Name;

   overriding procedure Run_Test (Item : in out Certificate_Request_Test) is
      pragma Unreferenced (Item);
      Server_Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty;
      Email_Request  : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty (Devcert.Certificate_Requests.Email);
   begin
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Server_Request, "LOCALHOST") = Devcert.Certificate_Requests.Valid,
         "server DNS identity is accepted");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Server_Request, "localhost") = Devcert.Certificate_Requests.Valid,
         "duplicate server identity is ignored after normalization");
      Assert
        (Server_Request.Count = 1,
         "duplicate identities do not increase request cardinality");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Server_Request, "127.0.0.1") = Devcert.Certificate_Requests.Valid,
         "server IPv4 identity is accepted");
      Assert
        (Devcert.Certificate_Requests.Common_Name (Server_Request) = "localhost",
         "first identity is the informational common name");
      Assert
        (Devcert.Certificate_Requests.Output_Name (Server_Request) = "localhost",
         "output name is deterministic");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Server_Request, "user@example.test")
         = Devcert.Certificate_Requests.Mixed_Identity_Modes,
         "server and email identities cannot be mixed");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Email_Request, "user@example.test") = Devcert.Certificate_Requests.Valid,
         "email request accepts email identity");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Email_Request, "localhost")
         = Devcert.Certificate_Requests.Mixed_Identity_Modes,
         "email request rejects server identity");
   end Run_Test;

   overriding function Name
     (Item : Certificate_Request_Limit_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("certificate request limits");
   end Name;

   overriding procedure Run_Test
     (Item : in out Certificate_Request_Limit_Test)
   is
      pragma Unreferenced (Item);
      Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty;
      Email_Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty (Devcert.Certificate_Requests.Email);
   begin
      for I in 1 .. Devcert.Certificate_Requests.Max_Identities loop
         Assert
           (Devcert.Certificate_Requests.Add_Identity
              (Request,
               "host"
               & Ada.Strings.Fixed.Trim (Integer'Image (I), Ada.Strings.Both)
               & ".example.test")
            = Devcert.Certificate_Requests.Valid,
            "identity within request limit is accepted");
      end loop;
      Assert
        (Request.Count = Devcert.Certificate_Requests.Max_Identities,
         "request reaches maximum identity count");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Request, "overflow.example.test")
         = Devcert.Certificate_Requests.Too_Many_Identities,
         "request rejects identities beyond maximum count");

      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Email_Request, "User+tag@example.test")
         = Devcert.Certificate_Requests.Valid,
         "email request accepts tagged mailbox identity");
      Assert
        (Devcert.Certificate_Requests.Output_Name (Email_Request)
         = "user_tag_example.test",
         "email output name is filesystem-safe and deterministic");
   end Run_Test;

   overriding function Name
     (Item : Certificate_Profile_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("certificate profile boundary");
   end Name;

   overriding procedure Run_Test (Item : in out Certificate_Profile_Test) is
      pragma Unreferenced (Item);
      CA_Cert : Unbounded_String;
      CA_Key  : Unbounded_String;
      Leaf    : Unbounded_String;
      Key     : Unbounded_String;
      Bundle  : Unbounded_String;
      Client_Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty (Devcert.Certificate_Requests.Client);
      Email_Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty (Devcert.Certificate_Requests.Email);
      IP_Request : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty;
   begin
      Reset_Temp_Home ("cert-profile");
      Assert
        (Devcert.Certificate_Requests.Mode_Image
           (Devcert.Certificate_Requests.Server) = "server",
         "server profile image is stable");
      Assert
        (Devcert.Certificate_Requests.Mode_Image
           (Devcert.Certificate_Requests.Client) = "client",
         "client profile image is stable");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Client_Request, "localhost") = Devcert.Certificate_Requests.Valid,
         "client profile request accepts identity policy");

      Assert
        (Devcert_Crypto.Create_CA (CA_Cert, CA_Key) = Devcert_Crypto.Ok,
         "CA creation succeeds for profile tests");
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Certificate_Path, To_String (CA_Cert));
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Private_Key_Path, To_String (CA_Key), Secret => True);

      Assert
        (Devcert_Crypto.Issue_Certificate (Client_Request, Leaf, Key)
         = Devcert_Crypto.Ok,
         "client profile is issued through cryptolib");
      Assert
        (Length (Leaf) > 0 and then Length (Key) > 0,
         "client profile returns certificate and key material");

      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (Email_Request, "user@example.test") = Devcert.Certificate_Requests.Valid,
         "email profile request accepts email identity policy");
      Assert
        (Devcert_Crypto.Issue_Certificate (Email_Request, Leaf, Key)
         = Devcert_Crypto.Ok,
         "S/MIME profile is issued through cryptolib");
      Assert
        (Length (Leaf) > 0 and then Length (Key) > 0,
         "S/MIME profile returns certificate and key material");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (IP_Request, "127.0.0.1") = Devcert.Certificate_Requests.Valid,
         "IP profile request accepts IPv4 identity policy");
      Assert
        (Devcert.Certificate_Requests.Add_Identity
           (IP_Request, "::1") = Devcert.Certificate_Requests.Valid,
         "IP profile request accepts IPv6 identity policy");
      Assert
        (Devcert_Crypto.Issue_Certificate (IP_Request, Leaf, Key)
         = Devcert_Crypto.Ok,
         "IP SAN profile is issued through cryptolib");
      Assert
        (Devcert_Crypto.Sign_CSR ("not a csr", Leaf)
         = Devcert_Crypto.Invalid_Request,
         "malformed CSR is mapped to invalid certificate request");

      Assert
        (Devcert_Crypto.Issue_Certificate ("localhost", Leaf, Key)
         = Devcert_Crypto.Ok,
         "server profile remains supported through cryptolib");
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.Leaf_Certificate_Path ("localhost"), To_String (Leaf));
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.Leaf_Private_Key_Path ("localhost"),
         To_String (Key),
         Secret => True);
      Assert
        (Devcert_Crypto.Generate_PKCS12 ("localhost", "secret", Bundle)
         = Devcert_Crypto.Ok,
         "PKCS#12 password is delegated to cryptolib");
      Assert
        (Length (Bundle) > 0 and then Element (Bundle, 1) = Character'Val (16#30#),
         "passworded PKCS#12 output is DER");
   end Run_Test;

   overriding function Name
     (Item : Certificate_File_Workflow_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("certificate file workflow");
   end Name;

   overriding procedure Run_Test
     (Item : in out Certificate_File_Workflow_Test)
   is
      pragma Unreferenced (Item);
      CA_Cert : Unbounded_String;
      CA_Key  : Unbounded_String;
      Leaf    : Unbounded_String;
      Key     : Unbounded_String;
      Bundle  : Unbounded_String;
   begin
      Reset_Temp_Home ("cert-workflow");
      Assert
        (Devcert_Crypto.Create_CA (CA_Cert, CA_Key) = Devcert_Crypto.Ok,
         "CA creation succeeds");
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Certificate_Path, To_String (CA_Cert));
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Private_Key_Path, To_String (CA_Key), Secret => True);

      Assert
        (Devcert_Crypto.Issue_Certificate ("localhost", Leaf, Key)
         = Devcert_Crypto.Ok,
         "leaf certificate can be issued from stored CA");
      Assert (Index (Leaf, "BEGIN CERTIFICATE") /= 0, "leaf cert is PEM");
      Assert (Index (Key, "BEGIN PRIVATE KEY") /= 0, "leaf key is PEM");

      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.Leaf_Certificate_Path ("localhost"), To_String (Leaf));
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.Leaf_Private_Key_Path ("localhost"),
         To_String (Key),
         Secret => True);
      Assert
        (Devcert_Crypto.Generate_PKCS12 ("localhost", Bundle) = Devcert_Crypto.Ok,
         "PKCS#12 can be generated from stored leaf artifacts");
      Assert
        (Length (Bundle) > 0 and then Element (Bundle, 1) = Character'Val (16#30#),
         "PKCS#12 output is DER");
   end Run_Test;

   overriding function Name
     (Item : Certificate_Custom_PKCS12_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("custom certificate PKCS12 workflow");
   end Name;

   overriding procedure Run_Test
     (Item : in out Certificate_Custom_PKCS12_Test)
   is
      pragma Unreferenced (Item);
      CA_Cert : Unbounded_String;
      CA_Key  : Unbounded_String;
      Leaf    : Unbounded_String;
      Key     : Unbounded_String;
      Bundle  : Unbounded_String;
   begin
      Reset_Temp_Home ("cert-custom-p12");
      Assert
        (Devcert_Crypto.Create_CA (CA_Cert, CA_Key) = Devcert_Crypto.Ok,
         "CA creation succeeds for custom PKCS#12 test");
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Certificate_Path, To_String (CA_Cert));
      Devcert_Secure_Files.Atomic_Write
        (Devcert_State.CA_Private_Key_Path, To_String (CA_Key), Secret => True);

      Assert
        (Devcert_Crypto.Issue_Certificate ("localhost", Leaf, Key)
         = Devcert_Crypto.Ok,
         "leaf certificate can be issued for custom PKCS#12 test");
      Assert
        (Devcert_Crypto.Generate_PKCS12
           (To_String (Leaf), To_String (Key), "localhost", "secret", Bundle)
         = Devcert_Crypto.Ok,
         "PKCS#12 can be generated from in-memory custom artifacts");
      Assert
        (Length (Bundle) > 0 and then Element (Bundle, 1) = Character'Val (16#30#),
         "custom-artifact PKCS#12 output is DER");
   end Run_Test;

   overriding function Name
     (Item : Integration_Workflow_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("install cert inspect doctor uninstall workflow");
   end Name;

   overriding procedure Run_Test
     (Item : in out Integration_Workflow_Test)
   is
      pragma Unreferenced (Item);

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String := "/tmp/devcert-aunit-workflow.out";
      begin
         if Ada.Directories.Exists (Output_File) then
            Ada.Directories.Delete_File (Output_File);
         end if;
         GNAT.OS_Lib.Spawn
           ("./bin/devcert",
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

      Root      : constant String := "/tmp/devcert-aunit-workflow-root";
      Trust_Dir : constant String := "/tmp/devcert-aunit-workflow-trust";
      Code      : Integer := 0;
      Output    : Unbounded_String;
   begin
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      if Ada.Directories.Exists (Trust_Dir) then
         Ada.Directories.Delete_Tree (Trust_Dir);
      end if;
      Ada.Environment_Variables.Set ("DEVCERT_LINUX_TRUST_DIR", Trust_Dir);

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("install"),
          new String'("--trust-store"),
          new String'("system")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "install workflow succeeds");
      Assert
        (Ada.Directories.Exists (Root & "/rootCA.pem"),
         "install creates the root certificate");
      Assert
        (Ada.Directories.Exists (Trust_Dir),
         "install writes to isolated trust directory");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("cert"),
          new String'("localhost"),
          new String'("127.0.0.1")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "cert workflow succeeds");
      Assert
        (Ada.Directories.Exists (Root & "/issued/localhost.pem"),
         "cert workflow writes issued certificate");
      Assert
        (Ada.Directories.Exists (Root & "/issued/localhost-key.pem"),
         "cert workflow writes issued private key");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("inspect")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "inspect workflow succeeds");
      Assert
        (Index (Output, "fingerprint=") /= 0,
         "inspect reports CA fingerprint");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("doctor")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "doctor workflow succeeds");
      Assert
        (Index (Output, "doctor: ca complete") /= 0,
         "doctor reports complete CA");

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("uninstall"),
          new String'("--trust-store"),
          new String'("system")],
         Code,
         Output);
      Assert (Code = Devcert_Exit_Codes.Success, "uninstall workflow succeeds");
      Assert
        (Index (Output, "removed linux trust anchor") /= 0,
         "uninstall reports isolated trust anchor removal");

      Ada.Environment_Variables.Clear ("DEVCERT_LINUX_TRUST_DIR");
      Ada.Directories.Delete_Tree (Root);
      Ada.Directories.Delete_Tree (Trust_Dir);
   end Run_Test;

   overriding function Name (Item : Trust_Target_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("trust target parsing");
   end Name;

   overriding procedure Run_Test (Item : in out Trust_Target_Test) is
      pragma Unreferenced (Item);
      Linux_Target : Devcert_Trust_Stores.Trust_Target;
      Java_Target  : Devcert_Trust_Stores.Trust_Target;
      Bad_Target   : Devcert_Trust_Stores.Trust_Target;
   begin
      Assert
        (Devcert_Trust_Stores.Target_From_Name ("linux", Linux_Target)
         and then Linux_Target = Devcert_Trust_Stores.Linux,
         "linux target parses");
      Assert
        (Devcert_Trust_Stores.Target_From_Name ("java", Java_Target)
         and then Java_Target = Devcert_Trust_Stores.Java,
         "java target parses");
      pragma Warnings (Off, "possibly useless assignment*");
      Assert
        (not Devcert_Trust_Stores.Target_From_Name ("bogus", Bad_Target),
         "unknown trust target is rejected");
      pragma Warnings (On, "possibly useless assignment*");
   end Run_Test;

   overriding function Name
     (Item : Trust_Selection_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("trust store selection");
   end Name;

   overriding procedure Run_Test (Item : in out Trust_Selection_Test) is
      pragma Unreferenced (Item);
      Selection : Devcert_Trust_Stores.Store_Selection;
      Kind      : Devcert_Trust_Stores.Trust_Store_Kind;
   begin
      Assert
        (Devcert_Trust_Stores.Kind_From_Name ("system", Kind)
         and then Kind = Devcert_Trust_Stores.System_Store,
         "system store name parses");
      Assert
        (Devcert_Trust_Stores.Kind_From_Name ("nss", Kind)
         and then Kind = Devcert_Trust_Stores.NSS_Store,
         "NSS store name parses");
      Assert
        (Devcert_Trust_Stores.Selection_From_Text
           ("system,nss,java,nss", Selection),
         "comma-separated trust store selection parses");
      Assert (Selection.Count = 3, "duplicate stores are ignored");
      Assert
        (Selection.Items (1) = Devcert_Trust_Stores.System_Store,
         "system store keeps deterministic order");
      Assert
        (Selection.Items (2) = Devcert_Trust_Stores.NSS_Store,
         "NSS store keeps deterministic order");
      Assert
        (Selection.Items (3) = Devcert_Trust_Stores.Java_Store,
         "Java store keeps deterministic order");
      pragma Warnings (Off, "possibly useless assignment*");
      Assert
        (not Devcert_Trust_Stores.Selection_From_Text ("system,bogus", Selection),
         "unknown logical store is rejected");
      pragma Warnings (On, "possibly useless assignment*");
      Assert
        (Devcert_Trust_Stores.State_Image (Devcert_Trust_Stores.Tool_Missing)
         = "tool-missing",
         "trust state image is stable");
      Assert
        (Devcert_Trust_Stores.Fingerprint_Alias ("aa:BB:cc 11") =
         "devcert-aacc11",
         "trust aliases are derived only from normalized fingerprints");
   end Run_Test;

   overriding function Name (Item : Trust_Plan_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("trust store plans");
   end Name;

   overriding procedure Run_Test (Item : in out Trust_Plan_Test) is
      pragma Unreferenced (Item);
   begin
      Assert
        (Devcert_Trust_Stores.Name (Devcert_Trust_Stores.MacOS) = "macos",
         "macOS target name is stable");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_Trust_Stores.Plan
                 (Devcert_Trust_Stores.Windows,
                  Devcert_Trust_Stores.Remove,
                  "/tmp/root.pem",
                  "aa:bb")),
            "Windows certificate store") /= 0,
         "Windows trust plan is explicit");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_Trust_Stores.Plan
                 (Devcert_Trust_Stores.NSS,
                  Devcert_Trust_Stores.Install,
                  "/tmp/root.pem",
                  "aa:bb")),
            "NSS profiles") /= 0,
         "NSS trust plan is explicit");
   end Run_Test;

   overriding function Name
     (Item : Trust_Aggregate_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("trust aggregate states");
   end Name;

   overriding procedure Run_Test (Item : in out Trust_Aggregate_Test) is
      pragma Unreferenced (Item);
      Selection : constant Devcert_Trust_Stores.Store_Selection :=
        (Count => 0, Items => [others => Devcert_Trust_Stores.System_Store]);
      State   : Devcert_Trust_Stores.Trust_State;
      Message : Unbounded_String;
   begin
      Devcert_Trust_Stores.Apply
        (Selection,
         Devcert_Trust_Stores.Install,
         "/tmp/missing-root.pem",
         "aa:bb",
         State,
         Message);
      Assert
        (State = Devcert_Trust_Stores.Unsupported,
         "empty trust selection is unsupported");
      Assert
        (To_String (Message) = "no trust stores selected",
         "empty trust selection diagnostic is deterministic");
   end Run_Test;

   overriding function Name
     (Item : Trust_Linux_Mutation_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("linux trust mutation");
   end Name;

   overriding procedure Run_Test
     (Item : in out Trust_Linux_Mutation_Test)
   is
      pragma Unreferenced (Item);
      Trust_Dir : constant String := "/tmp/devcert-aunit-linux-trust";
      Cert_Path : constant String := "/tmp/devcert-aunit-linux-root.pem";
      Target    : constant String := Trust_Dir & "/devcert-aabbcc.crt";
      Cert      : constant String :=
        "-----BEGIN CERTIFICATE-----" & ASCII.LF
        & "MIIBdevcerttrustedroot" & ASCII.LF
        & "-----END CERTIFICATE-----" & ASCII.LF;
      Other_Cert : constant String :=
        "-----BEGIN CERTIFICATE-----" & ASCII.LF
        & "MIIBdifferenttrustedroot" & ASCII.LF
        & "-----END CERTIFICATE-----" & ASCII.LF;
      Success : Boolean := False;
      Message : Unbounded_String;
   begin
      if Ada.Directories.Exists (Trust_Dir) then
         Ada.Directories.Delete_Tree (Trust_Dir);
      end if;
      if Ada.Directories.Exists (Cert_Path) then
         Ada.Directories.Delete_File (Cert_Path);
      end if;

      Ada.Environment_Variables.Set ("DEVCERT_LINUX_TRUST_DIR", Trust_Dir);
      Devcert_Secure_Files.Atomic_Write (Cert_Path, Cert);

      Assert
        (Devcert_Trust_Stores.Probe (Devcert_Trust_Stores.System_Store)
         = Devcert_Trust_Stores.Available,
         "configured Linux trust directory makes system store available");

      Devcert_Trust_Stores.Apply
        (Devcert_Trust_Stores.Linux,
         Devcert_Trust_Stores.Install,
         Cert_Path,
         "aa:bb:cc",
         Success,
         Message);
      Assert (Success, "configured Linux trust anchor installs");
      Assert (Ada.Directories.Exists (Target), "trust anchor file is staged");

      Devcert_Trust_Stores.Apply
        (Devcert_Trust_Stores.Linux,
         Devcert_Trust_Stores.Remove,
         Cert_Path,
         "aa:bb:cc",
         Success,
         Message);
      Assert (Success, "matching configured Linux trust anchor removes");
      Assert
        (not Ada.Directories.Exists (Target),
         "matching trust anchor file is deleted");

      Ada.Directories.Copy_File (Cert_Path, Target);
      Devcert_Secure_Files.Atomic_Write (Cert_Path, Other_Cert);
      Devcert_Trust_Stores.Apply
        (Devcert_Trust_Stores.Linux,
         Devcert_Trust_Stores.Remove,
         Cert_Path,
         "aa:bb:cc",
         Success,
         Message);
      Assert (not Success, "mismatched Linux trust anchor refuses removal");
      Assert
        (Ada.Directories.Exists (Target),
         "mismatched trust anchor file is preserved");
      Assert
        (Index (Message, "mismatch") /= 0,
         "mismatched trust anchor diagnostic is deterministic");

      Ada.Environment_Variables.Clear ("DEVCERT_LINUX_TRUST_DIR");
      Ada.Directories.Delete_Tree (Trust_Dir);
      Ada.Directories.Delete_File (Cert_Path);
   end Run_Test;
end Devcert_Test_Suite.Core_Tests;
