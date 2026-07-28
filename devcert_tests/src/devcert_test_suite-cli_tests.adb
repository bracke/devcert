with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with GNAT.OS_Lib;
with Hostkit;
with Hostkit.Host;
with Hostkit.Process;
with Devcert_Test_Suite.Paths;
with Devcert_Core;
with Devcert_Exit_Codes;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert_Trust_Stores;
with Devcert;
with Devcert.CA_Store;
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

with Devcert_Test_Suite.Support;

package body Devcert_Test_Suite.Cli_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Devcert_Test_Suite.Support;
   use type Devcert.Certificate_Requests.Certificate_Mode;
   use type Devcert.Errors.Error_Kind;
   use type Devcert.Locks.Lock_Result;
   use type Devcert_Trust_Stores.Trust_Target;
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
        (Devcert.Locks.Acquire (Paths.Scratch ("devcert-aunit-architecture.lock"))
         = Devcert.Locks.Acquired,
         "lock layer exposes writer serialization primitive");
      Devcert.Locks.Release (Paths.Scratch ("devcert-aunit-architecture.lock"));
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
         Output_File : constant String := Paths.Scratch ("devcert-aunit-cli.out");
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

      Unknown_Root : constant String := Paths.Scratch ("devcert-aunit-cli-unknown");
      Option_Root  : constant String := Paths.Scratch ("devcert-aunit-cli-option");
      Env_Root     : constant String := Paths.Scratch ("devcert-aunit-cli-env-root");
      Env_Override : constant String := Paths.Scratch ("devcert-aunit-cli-env-override");
      CLI_Root     : constant String := Paths.Scratch ("devcert-aunit-cli-override-root");
      Dup_Root     : constant String := Paths.Scratch ("devcert-aunit-cli-duplicate");
      Trust_Root   : constant String := Paths.Scratch ("devcert-aunit-cli-trust-root");
      Trust_Dir    : constant String := Paths.Scratch ("devcert-aunit-cli-trust-dir");
      Bad_Env_Root : constant String := Paths.Scratch ("devcert-aunit-cli-bad-env");
      Denied_Root  : constant String := Paths.Scratch ("devcert-aunit-cli-denied-root");
      Denied_Dir   : constant String := Paths.Scratch ("devcert-aunit-cli-denied-dir");
      Profile_Root : constant String := Paths.Scratch ("devcert-aunit-cli-profile");
      CSR_Root     : constant String := Paths.Scratch ("devcert-aunit-cli-csr");
      Password_Root : constant String := Paths.Scratch ("devcert-aunit-cli-password");
      CSR_Path     : constant String := Paths.Scratch ("devcert-aunit-cli.csr");
      Password_Path : constant String := Paths.Scratch ("devcert-aunit-cli.password");
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
      if System_Store_Is_Isolated then
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
      end if;

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

      --  A store that wants privileges the process does not have is a distinct
      --  outcome from a broken one, and the caller has something to do about it.
      --  An anchor directory the process cannot write into is the reachable form
      --  of that on this host; a run as root can write anywhere, and a host with
      --  no mode bits cannot withhold the write at all, so both skip.
      if System_Store_Is_Isolated then
         Devcert_Secure_Files.Ensure_Directory (Denied_Dir, "500");
         Ada.Environment_Variables.Set ("DEVCERT_LINUX_TRUST_DIR", Denied_Dir);
         if Devcert_Secure_Files.Permissions (Denied_Dir) = "500" then
            Run_Devcert
              ([new String'("--ca-root"),
                new String'(Denied_Root),
                new String'("--plain"),
                new String'("install"),
                new String'("--trust-store"),
                new String'("system")],
               Code,
               Output);
            Assert
              (Code = Devcert_Exit_Codes.Permission_Error,
               "a trust store that requires privileges reports the permission code");
            Assert
              (Index (Output, "requires permission") /= 0,
               "the permission diagnostic says what the caller has to do");
         end if;
         Devcert_Secure_Files.Ensure_Directory (Denied_Dir, "700");
         if Ada.Directories.Exists (Denied_Dir) then
            Ada.Directories.Delete_Tree (Denied_Dir);
         end if;
         if Ada.Directories.Exists (Denied_Root) then
            Ada.Directories.Delete_Tree (Denied_Root);
         end if;
      end if;
      Ada.Environment_Variables.Clear ("DEVCERT_LINUX_TRUST_DIR");

      --  caroot had no test at all, though it is one of the eight command
      --  groups and the one a script uses to find everything else.
      declare
         Root : constant String := Paths.Scratch ("devcert-aunit-cli-caroot");
      begin
         if Ada.Directories.Exists (Root) then
            Ada.Directories.Delete_Tree (Root);
         end if;
         Run_Devcert
           ([new String'("--ca-root"),
             new String'(Root),
             new String'("--plain"),
             new String'("caroot")],
            Code,
            Output);
         Assert (Code = Devcert_Exit_Codes.Success, "caroot succeeds");
         Assert
           (Index (Output, Root) /= 0,
            "caroot reports the CA root it was given");
         Assert
           (not Ada.Directories.Exists (Root),
            "caroot reports a path without creating it");

         Run_Devcert
           ([new String'("--ca-root"),
             new String'(Root),
             new String'("--json"),
             new String'("caroot")],
            Code,
            Output);
         Assert
           (Index
              (Output,
               "{""schema_version"":1,""status"":""success"",""command"":""caroot""")
            /= 0,
            "caroot speaks the stable JSON envelope");
      end;

      --  A CSR brings its own key, so there is none to write: cli.md says this
      --  combination is refused, and nothing checked that it was.
      declare
         CSR_Root : constant String :=
           Paths.Scratch ("devcert-aunit-cli-csr-keyfile");
      begin
         Run_Devcert
           ([new String'("--ca-root"),
             new String'(CSR_Root),
             new String'("--plain"),
             new String'("cert"),
             new String'("--csr"),
             new String'(CSR_Path),
             new String'("--key-file"),
             new String'(Paths.Scratch ("devcert-aunit-cli-unwanted.key"))],
            Code,
            Output);
         --  The specific diagnostic, not merely a non-zero exit: the CSR file
         --  here holds only an armour line, so "it failed" would have been
         --  true either way.
         Assert
           (Code /= Devcert_Exit_Codes.Success,
            "signing a CSR refuses --key-file, which it cannot honour");
         Assert
           (Index (Output, "--csr cannot be combined with") /= 0,
            "and says which combination it refused");
         Assert
           (not Ada.Directories.Exists
                  (Paths.Scratch ("devcert-aunit-cli-unwanted.key")),
            "and writes no key when it refuses");
      end;
   end Run_Test;

   overriding function Name
     (Item : Partial_Trust_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("one store trusts the CA and the other refuses");
   end Name;

   --  Two stores, one answer each. A user asking for both on an ordinary
   --  machine gets exactly this: the databases they own accept the CA, and the
   --  system store wants root. Only the exit code's value was tested; the
   --  aggregation that decides to use it had never run, and it is the part that
   --  has to keep the two outcomes apart instead of flattening them into one.
   overriding procedure Run_Test (Item : in out Partial_Trust_Test) is
      pragma Unreferenced (Item);

      function Has_Certutil return Boolean is
         use type GNAT.OS_Lib.String_Access;
         Found : GNAT.OS_Lib.String_Access :=
           GNAT.OS_Lib.Locate_Exec_On_Path ("certutil");
      begin
         if Found = null then
            return False;
         end if;
         GNAT.OS_Lib.Free (Found);
         return True;
      end Has_Certutil;

      Root    : constant String := Paths.Scratch ("devcert-aunit-partial");
      NSS_Dir : constant String := Paths.Scratch ("devcert-aunit-partial-nssdb");
      Code    : Integer := 0;
      Output  : Unbounded_String;

      procedure Run_Devcert
        (Args        : GNAT.OS_Lib.Argument_List;
         Exit_Code   : out Integer;
         Output_Text : out Unbounded_String)
      is
         Spawned     : Boolean := False;
         Output_File : constant String := Paths.Scratch ("devcert-aunit-partial.out");
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
   begin
      --  Two things make this test unsafe rather than merely useless, and both
      --  end it here. Elevated, the system store would take the certificate
      --  rather than refuse it -- and it would be the real one. Pointed at a
      --  directory of the suite's own, it would succeed for a different reason.
      --  Either way there is no denial to observe, and the first would leave a
      --  development CA trusted on whoever ran the suite.
      if Hostkit.Host.Is_Elevated then
         Ada.Text_IO.Put_Line
           ("   (skipped: elevated, so the system store would accept the CA)");
         return;
      end if;

      --  The suite points the Linux system store at a directory of its own
      --  elsewhere, through this variable. Aimed there it would accept the CA
      --  rather than refuse it, and there would be no denial to observe.
      if Ada.Environment_Variables.Exists ("DEVCERT_LINUX_TRUST_DIR") then
         Ada.Text_IO.Put_Line
           ("   (skipped: the system store is aimed at a directory of ours)");
         return;
      end if;

      if not Has_Certutil then
         Ada.Text_IO.Put_Line
           ("   (skipped: no certutil, so NSS would decline rather than accept)");
         return;
      end if;

      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      if Ada.Directories.Exists (NSS_Dir) then
         Ada.Directories.Delete_Tree (NSS_Dir);
      end if;
      Ada.Directories.Create_Path (NSS_Dir);

      --  A database of ours, never the caller's own: this installs a CA.
      Ada.Environment_Variables.Set ("DEVCERT_NSS_DB", NSS_Dir);

      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("install"),
          new String'("--trust-store"),
          new String'("nss,system")],
         Code,
         Output);

      Assert
        (Code = Devcert_Exit_Codes.Partial_Success,
         "a mixed result is its own exit code, not success and not failure;"
         & " exit was " & Code'Image);
      Assert
        (Index (Output, "nss=installed") /= 0,
         "the store that accepted the CA is reported as having accepted it");
      Assert
        (Index (Output, "system=permission-required") /= 0,
         "and the one that refused is reported as a denial, not as an error");

      --  Ours to take out again: the NSS database really does trust it now.
      Run_Devcert
        ([new String'("--ca-root"),
          new String'(Root),
          new String'("--plain"),
          new String'("uninstall"),
          new String'("--trust-store"),
          new String'("nss")],
         Code,
         Output);
      Assert
        (Index (Output, "nss=removed") /= 0,
         "and the anchor this test installed is removed again");

      Ada.Environment_Variables.Clear ("DEVCERT_NSS_DB");
      Ada.Directories.Delete_Tree (NSS_Dir);
      Ada.Directories.Delete_Tree (Root);
   end Run_Test;

   overriding function Name
     (Item : P12_Stdin_Password_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("a PKCS#12 password read from standard input");
   end Name;

   --  The one option that cannot be exercised by spawning devcert with
   --  arguments: the password arrives on standard input, so the test has to
   --  put it there. Until Hostkit.Process could feed a subprocess a file there
   --  was no way to run this path at all, and only its duplicate-option error
   --  was covered -- a bundle locked with the wrong bytes, or with none, would
   --  have looked exactly like a bundle.
   overriding procedure Run_Test (Item : in out P12_Stdin_Password_Test) is
      pragma Unreferenced (Item);

      Root      : constant String := Paths.Scratch ("devcert-aunit-p12-stdin");
      Password  : constant String := Paths.Scratch ("devcert-aunit-p12-stdin.pw");
      Bundle    : constant String := Paths.Scratch ("devcert-aunit-p12-stdin.p12");
      Log       : constant String := Paths.Scratch ("devcert-aunit-p12-stdin.out");
      Secret    : constant String := "correct-horse-battery";

      Arguments : Hostkit.String_Vectors.Vector;
      Outcome   : Hostkit.Process.Process_Outcome;
   begin
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      if Ada.Directories.Exists (Password) then
         Ada.Directories.Delete_File (Password);
      end if;
      if Ada.Directories.Exists (Bundle) then
         Ada.Directories.Delete_File (Bundle);
      end if;

      Devcert_Secure_Files.Atomic_Write (Password, Secret & ASCII.LF);

      Arguments.Append (To_Unbounded_String ("--ca-root"));
      Arguments.Append (To_Unbounded_String (Root));
      Arguments.Append (To_Unbounded_String ("--plain"));
      Arguments.Append (To_Unbounded_String ("cert"));
      Arguments.Append (To_Unbounded_String ("--p12-file"));
      Arguments.Append (To_Unbounded_String (Bundle));
      Arguments.Append (To_Unbounded_String ("--p12-password-stdin"));
      Arguments.Append (To_Unbounded_String ("localhost"));

      Outcome :=
        Hostkit.Process.Run_Captured
          (Program     => Paths.Devcert_Executable,
           Arguments   => Arguments,
           Stdin_Path  => Password,
           Stdout_Path => Log,
           Stderr_Path => Log,
           --  A password that never arrives is a wait, not a failure; the
           --  deadline is what turns one into the other.
           Timeout_Ms  => 60_000);

      Assert (Outcome.Started, "devcert runs with a password on standard input");
      Assert
        (not Outcome.Timed_Out,
         "and does not sit waiting for input it was already given");
      Assert
        (Outcome.Exit_Status = Devcert_Exit_Codes.Success,
         "and succeeds; exit was " & Outcome.Exit_Status'Image);
      Assert
        (Ada.Directories.Exists (Bundle), "and writes the bundle it was asked for");

      if not Has_Openssl then
         Ada.Text_IO.Put_Line
           ("   (skipped: no openssl on this host to open the bundle)");
         return;
      end if;

      --  The point of the password is that it is the one the bundle now wants.
      Assert
        (Openssl_Succeeds
           ([new String'("pkcs12"),
             new String'("-in"),
             new String'(Bundle),
             new String'("-nokeys"),
             new String'("-passin"),
             new String'("pass:" & Secret),
             new String'("-out"),
             new String'(Paths.Scratch ("devcert-aunit-p12-stdin-read.pem"))]),
         "and the bundle opens with the password it was given on stdin");
      Assert
        (not Openssl_Succeeds
           ([new String'("pkcs12"),
             new String'("-in"),
             new String'(Bundle),
             new String'("-nokeys"),
             new String'("-passin"),
             new String'("pass:" & Secret & "-not"),
             new String'("-out"),
             new String'(Paths.Scratch ("devcert-aunit-p12-stdin-read.pem"))]),
         "and not with another, so the password is what locked it");

      Ada.Directories.Delete_File (Password);
      Ada.Directories.Delete_File (Bundle);
      if Ada.Directories.Exists (Log) then
         Ada.Directories.Delete_File (Log);
      end if;
      Ada.Directories.Delete_Tree (Root);
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
         Output_File : constant String := Paths.Scratch ("devcert-aunit-output.out");
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
         Output_File : constant String := Paths.Scratch ("devcert-aunit-workflow.out");
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

      Root      : constant String := Paths.Scratch ("devcert-aunit-workflow-root");
      Trust_Dir : constant String := Paths.Scratch ("devcert-aunit-workflow-trust");
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

      --  The trust-mutating ends of the workflow only run where the system store
      --  is a directory of the suite's own; the certificate half below is the
      --  same on every host.
      if System_Store_Is_Isolated then
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
      end if;

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

      if System_Store_Is_Isolated then
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
      end if;

      Ada.Environment_Variables.Clear ("DEVCERT_LINUX_TRUST_DIR");
      Ada.Directories.Delete_Tree (Root);
      if Ada.Directories.Exists (Trust_Dir) then
         Ada.Directories.Delete_Tree (Trust_Dir);
      end if;
   end Run_Test;

end Devcert_Test_Suite.Cli_Tests;
