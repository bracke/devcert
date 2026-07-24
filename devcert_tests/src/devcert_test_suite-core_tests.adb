with AUnit.Assertions;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;

with Devcert_Core;
with Devcert_Crypto;
with Devcert_JSON;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert_Trust_Stores;

package body Devcert_Test_Suite.Core_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type Devcert_Crypto.Operation_Status;
   use type Devcert_Trust_Stores.Trust_Target;

   procedure Reset_Temp_Home (Name : String) is
      Path : constant String := "/tmp/devcert-aunit-" & Name;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
      Ada.Environment_Variables.Set ("DEVCERT_HOME", Path);
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
         "{""schema"":1,""ok"":true,""command"":""ca"",""message"":""created""}",
         "status envelope is deterministic");
      Assert
        (Devcert_JSON.Error ("issue", "bad name") =
         "{""schema"":1,""ok"":false,""command"":""issue"",""error"":""bad name""}",
         "error envelope is deterministic");
      Assert
        (Devcert_JSON.Artifact ("inspect", "fingerprint", "aa:bb") =
         "{""schema"":1,""ok"":true,""command"":""inspect"",""fingerprint"":""aa:bb""}",
         "artifact envelope is deterministic");
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
         "DEVCERT_HOME controls the base directory");
      Assert
        (Devcert_State.CA_Certificate_Path =
         "/tmp/devcert-aunit-state/ca/root-ca.pem",
         "CA certificate path is stable");
      Assert
        (Devcert_State.Leaf_Private_Key_Path ("localhost") =
         "/tmp/devcert-aunit-state/certificates/localhost-key.pem",
         "leaf key path is stable");
   end Run_Test;

   overriding function Name (Item : Secure_File_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("secure file writes");
   end Name;

   overriding procedure Run_Test (Item : in out Secure_File_Test) is
      pragma Unreferenced (Item);
      Path : constant String := "/tmp/devcert-aunit-files/nested/value.txt";
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
end Devcert_Test_Suite.Core_Tests;
