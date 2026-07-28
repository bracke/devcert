with AUnit.Assertions;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Unbounded;
with Devcert_Test_Suite.Paths;
with Devcert_Crypto;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert;
with Devcert.CA_Store;
with Devcert.Clock;
with Devcert.Locks;

with Devcert_Test_Suite.Support;

package body Devcert_Test_Suite.Ca_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Devcert_Test_Suite.Support;
   use type Devcert.CA_Store.CA_State;
   use type Devcert.Locks.Lock_Result;
   use type Devcert_Crypto.Operation_Status;
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
        (Devcert_State.Base_Directory = Paths.Scratch ("devcert-aunit-state"),
         "DEVCERT_CAROOT controls the base directory");
      Assert
        (Devcert_State.CA_Certificate_Path =
         Paths.Scratch ("devcert-aunit-state/rootCA.pem"),
         "CA certificate path is stable");
      Assert
        (Devcert_State.CA_Metadata_Path =
         Paths.Scratch ("devcert-aunit-state/ca-metadata.txt"),
         "CA metadata path is stable");
      Assert
        (Devcert_State.Leaf_Private_Key_Path ("localhost") =
         Paths.Scratch ("devcert-aunit-state/issued/localhost-key.pem"),
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
      Path : constant String := Paths.Scratch ("devcert-aunit-locks/create.lock");
   begin
      if Ada.Directories.Exists (Paths.Scratch ("devcert-aunit-locks")) then
         Ada.Directories.Delete_Tree (Paths.Scratch ("devcert-aunit-locks"));
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

      Ada.Directories.Delete_Tree (Paths.Scratch ("devcert-aunit-ca-lifecycle"));
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
      --  Not a detail: NSS refuses to import an Ed25519 certificate, so a CA
      --  built that way is trusted by no browser however well the trust-store
      --  adapters work.
      Assert
        (Index
           (To_Unbounded_String
              (Devcert_Secure_Files.Read (Devcert_State.CA_Metadata_Path)),
            "key-algorithm=P-384") /= 0,
         "the CA is P-384, which a browser can import");
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
         & "key-algorithm=P-384" & ASCII.LF
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
         & "key-algorithm=P-384" & ASCII.LF
         & "certificate-fingerprint="
         & Devcert_Crypto.SHA256_Fingerprint
           (Devcert_Secure_Files.Read (Devcert_State.CA_Certificate_Path))
         & ASCII.LF,
         Secret => True);
      Assert
        (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Invalid_Metadata,
         "metadata without format version is rejected");
      Devcert_Secure_Files.Ensure_Directory (Devcert_State.Base_Directory, "755");
      --  Whether a loosened directory is even visible as such is a host fact: POSIX
      --  has the mode bits, Windows scopes a directory by ACL and hostkit declines
      --  to guess there. Ask the host first, then hold devcert to the answer.
      if Devcert_Secure_Files.Directory_Accessible_By_Others
           (Devcert_State.Base_Directory)
      then
         Assert
           (Devcert.CA_Store.Evaluate = Devcert.CA_Store.Unsafe_Permissions,
            "unsafe CA root permissions are rejected");
      end if;
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
            & "key-algorithm=P-384" & ASCII.LF
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
      Path : constant String := Paths.Scratch ("devcert-aunit-files/nested/value.txt");
      Raw_Path : constant String := Paths.Scratch ("devcert-aunit-files/nested/value.der");
   begin
      Reset_Temp_Home ("files");
      if Ada.Directories.Exists (Paths.Scratch ("devcert-aunit-files")) then
         Ada.Directories.Delete_Tree (Paths.Scratch ("devcert-aunit-files"));
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

      Assert
        (not Devcert_Secure_Files.Accessible_By_Others (Path),
         "secret atomic write leaves nothing readable by others");

      Devcert_Secure_Files.Atomic_Write (Path, "beta", Secret => False);
      Assert
        (Devcert_Secure_Files.Read (Path) = "beta",
         "atomic overwrite replaces complete file content");
      Assert
        (Devcert_Secure_Files.Has_Permissions (Path, "644"),
         "public atomic write applies public certificate permissions");

      --  Whether "readable by others" is expressible at all is a host fact:
      --  POSIX has the mode bits, Windows answers by ACL and Hostkit declines
      --  to guess there. The public write just made is the probe, so the host
      --  itself decides whether the exposed case can be asserted.
      if Devcert_Secure_Files.Accessible_By_Others (Path) then
         Devcert_Secure_Files.Atomic_Write (Path, "gamma", Secret => True);
         Assert
           (not Devcert_Secure_Files.Accessible_By_Others (Path),
            "rewriting a public file as secret withdraws access from others");
      end if;
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

end Devcert_Test_Suite.Ca_Tests;
