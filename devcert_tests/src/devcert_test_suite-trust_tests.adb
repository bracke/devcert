with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Hostkit.Host;
with Devcert_Crypto;
with Ada.Strings.Unbounded;
with Devcert_Test_Suite.Paths;
with Devcert_Secure_Files;
with Devcert_Trust_Stores;

package body Devcert_Test_Suite.Trust_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type Devcert_Crypto.Operation_Status;
   use type Devcert_Trust_Stores.Trust_State;
   use type Devcert_Trust_Stores.Trust_Store_Kind;
   use type Devcert_Trust_Stores.Trust_Target;
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
     (Item : NSS_Discovery_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("NSS database discovery");
   end Name;
   overriding procedure Run_Test (Item : in out NSS_Discovery_Test) is
      pragma Unreferenced (Item);

      Home    : constant String := Paths.Scratch ("devcert-aunit-nss-home");
      Shared  : constant String := Home & "/.pki/nssdb";

      Saved_Home : constant String :=
        (if Ada.Environment_Variables.Exists ("HOME")
         then Ada.Environment_Variables.Value ("HOME") else "");

      --  Compared canonically: the host decides how a path is spelled, and on
      --  Windows the one devcert returns carries backslashes while the one
      --  written here does not.
      function Discovered (Path : String) return Boolean is
         Wanted : constant String := Ada.Directories.Full_Name (Path);
      begin
         for Index in 1 .. Devcert_Trust_Stores.NSS_Database_Count loop
            if Ada.Directories.Full_Name
                 (Devcert_Trust_Stores.NSS_Database_Path (Index)) = Wanted
            then
               return True;
            end if;
         end loop;
         return False;
      end Discovered;
   begin
      if Ada.Directories.Exists (Home) then
         Ada.Directories.Delete_Tree (Home);
      end if;
      Ada.Environment_Variables.Clear ("DEVCERT_NSS_DB");
      Ada.Directories.Create_Path (Shared);

      --  Firefox keeps its profiles somewhere different on every host, so the
      --  fixture is built where this host actually looks rather than where a
      --  Linux machine would.
      Ada.Environment_Variables.Set ("HOME", Home);
      Ada.Environment_Variables.Set ("APPDATA", Home & "/AppData/Roaming");

      declare
         Root    : constant String := Devcert_Trust_Stores.Firefox_Profile_Root;
         Profile : constant String := Root & "/abcd1234.default-release";
         Decoy   : constant String := Root & "/Crash Reports";
      begin
         Ada.Directories.Create_Path (Profile);
         Ada.Directories.Create_Path (Decoy);
         Devcert_Secure_Files.Atomic_Write
           (Profile & "/cert9.db", "not a real db");

         --  Firefox reads none of the shared database, so finding only that
         --  one would leave every Firefox on the machine untrusting of the CA.
         Assert
           (Discovered (Shared),
            "the shared Chromium database is discovered");
         Assert
           (Discovered (Profile),
            "a Firefox profile holding cert9.db is discovered");
         Assert
           (not Discovered (Decoy),
            "a directory without cert9.db is not handed to certutil");
      end;

      --  An explicit database is the whole answer, which is what the platform
      --  runs rely on to stay off the real profiles.
      Ada.Environment_Variables.Set ("DEVCERT_NSS_DB", Shared);
      Assert
        (Devcert_Trust_Stores.NSS_Database_Count = 1
         and then Discovered (Shared),
         "DEVCERT_NSS_DB names one database instead of all of them");
      Ada.Environment_Variables.Clear ("DEVCERT_NSS_DB");

      if Saved_Home = "" then
         Ada.Environment_Variables.Clear ("HOME");
      else
         Ada.Environment_Variables.Set ("HOME", Saved_Home);
      end if;
      Ada.Directories.Delete_Tree (Home);
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

   function Has_Keytool return Boolean is
      use type GNAT.OS_Lib.String_Access;
      Found : GNAT.OS_Lib.String_Access :=
        GNAT.OS_Lib.Locate_Exec_On_Path ("keytool");
   begin
      if Found = null then
         return False;
      end if;
      GNAT.OS_Lib.Free (Found);
      return True;
   end Has_Keytool;

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
                  Paths.Scratch ("root.pem"),
                  "aa:bb")),
            "Windows certificate store") /= 0,
         "Windows trust plan is explicit");
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_Trust_Stores.Plan
                 (Devcert_Trust_Stores.NSS,
                  Devcert_Trust_Stores.Install,
                  Paths.Scratch ("root.pem"),
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
         Paths.Scratch ("missing-root.pem"),
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
     (Item : Trust_Denial_Test) return AUnit.Message_String
   is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("a store that will not have us says so");
   end Name;

   --  A store that refuses an unprivileged caller is not a broken store, and
   --  the difference is the whole of what the caller can do about it. Every
   --  adapter has had this wrong at least once: macOS and Windows reported a
   --  denial as an error until a real store was tried, and Java did until this
   --  host turned out to have a keytool and a root-owned cacerts.
   --
   --  The keystore here is one nobody can create -- an ordinary directory this
   --  process may not write -- so the real JDK store is never touched.
   overriding procedure Run_Test (Item : in out Trust_Denial_Test) is
      pragma Unreferenced (Item);

      Unwritable : constant String := "/usr/lib/devcert-aunit-keystore.jks";
      Cert_Path  : constant String := Paths.Scratch ("devcert-aunit-denial.pem");
      Outcome    : Devcert_Trust_Stores.Trust_State := Devcert_Trust_Stores.Error;
      Message    : Unbounded_String;
      Cert       : Unbounded_String;
      Key        : Unbounded_String;
   begin
      if Hostkit.Host.Is_Elevated then
         Ada.Text_IO.Put_Line
           ("   (skipped: elevated, so nothing here would be refused)");
         return;
      end if;

      if not Has_Keytool then
         Ada.Text_IO.Put_Line ("   (skipped: no keytool on this host)");
         return;
      end if;

      if not Ada.Directories.Exists ("/usr/lib") then
         Ada.Text_IO.Put_Line
           ("   (skipped: no directory here that refuses us)");
         return;
      end if;

      Assert
        (Devcert_Crypto.Create_CA (Cert, Key) = Devcert_Crypto.Ok,
         "a CA to offer the store");
      Devcert_Secure_Files.Atomic_Write (Cert_Path, To_String (Cert));

      Ada.Environment_Variables.Set ("DEVCERT_JAVA_KEYSTORE", Unwritable);
      Devcert_Trust_Stores.Apply
        (Devcert_Trust_Stores.Java,
         Devcert_Trust_Stores.Install,
         Cert_Path,
         "aa:bb:cc",
         Outcome,
         Message);
      Ada.Environment_Variables.Clear ("DEVCERT_JAVA_KEYSTORE");

      Assert
        (Outcome = Devcert_Trust_Stores.Permission_Required,
         "a keystore we may not write is a denial, not a broken store");
      Assert
        (not Ada.Directories.Exists (Unwritable),
         "and nothing was created where we may not write");

      Ada.Directories.Delete_File (Cert_Path);
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
      Trust_Dir : constant String := Paths.Scratch ("devcert-aunit-linux-trust");
      Cert_Path : constant String := Paths.Scratch ("devcert-aunit-linux-root.pem");
      Target    : constant String := Trust_Dir & "/devcert-aabbcc.crt";
      Cert      : constant String :=
        "-----BEGIN CERTIFICATE-----" & ASCII.LF
        & "MIIBdevcerttrustedroot" & ASCII.LF
        & "-----END CERTIFICATE-----" & ASCII.LF;
      Other_Cert : constant String :=
        "-----BEGIN CERTIFICATE-----" & ASCII.LF
        & "MIIBdifferenttrustedroot" & ASCII.LF
        & "-----END CERTIFICATE-----" & ASCII.LF;
      Outcome : Devcert_Trust_Stores.Trust_State :=
        Devcert_Trust_Stores.Error;
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
         Outcome,
         Message);
      Assert
        (Outcome = Devcert_Trust_Stores.Installed,
         "configured Linux trust anchor installs");
      Assert (Ada.Directories.Exists (Target), "trust anchor file is staged");

      Devcert_Trust_Stores.Apply
        (Devcert_Trust_Stores.Linux,
         Devcert_Trust_Stores.Remove,
         Cert_Path,
         "aa:bb:cc",
         Outcome,
         Message);
      Assert
        (Outcome = Devcert_Trust_Stores.Installed,
         "matching configured Linux trust anchor removes");
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
         Outcome,
         Message);
      --  And says why in its own terms: a refusal here is the store being
      --  wrong about what it holds, not a denial and not a missing tool.
      Assert
        (Outcome = Devcert_Trust_Stores.Error,
         "mismatched Linux trust anchor refuses removal");
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

end Devcert_Test_Suite.Trust_Tests;
