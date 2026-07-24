with AUnit.Assertions;
with Ada.Strings.Unbounded;

with Devcert_Core;
with Devcert_Crypto;
with Devcert_JSON;
with Devcert_Trust_Stores;

package body Devcert_Test_Suite.Core_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type Devcert_Crypto.Operation_Status;
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
end Devcert_Test_Suite.Core_Tests;
