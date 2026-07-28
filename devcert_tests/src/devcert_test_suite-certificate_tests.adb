with AUnit.Assertions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Devcert_Crypto;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert;
with Devcert.Certificate_Requests;
with Devcert.Identities;

with Devcert_Test_Suite.Support;

with GNAT.OS_Lib;

with Ada.Text_IO;

with Ada.Directories;

with Devcert_Test_Suite.Paths;

package body Devcert_Test_Suite.Certificate_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Devcert_Test_Suite.Support;
   use type Devcert.Certificate_Requests.Request_Status;
   use type Devcert.Identities.Identity_Kind;
   use type Devcert_Crypto.Operation_Status;
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

      --  That it is DER says nothing about the password it was built with. The
      --  bundle is integrity protected by that password, so a reader given the
      --  right one accepts it and a reader given another does not -- which is
      --  the only claim a caller of --p12-password-file is making.
      declare
         use type GNAT.OS_Lib.String_Access;
         Found : GNAT.OS_Lib.String_Access :=
           GNAT.OS_Lib.Locate_Exec_On_Path ("openssl");

         Bundle_Path : constant String :=
           Paths.Scratch ("devcert-aunit-p12-password.p12");

         function Openssl_Accepts (Password : String) return Boolean is
            Spawned : Boolean := False;
            Code    : Integer := 1;
            Sink    : constant String :=
              Paths.Scratch ("devcert-aunit-p12-openssl.out");
         begin
            GNAT.OS_Lib.Spawn
              (Found.all,
               [new String'("pkcs12"),
                new String'("-in"),
                new String'(Bundle_Path),
                new String'("-passin"),
                new String'("pass:" & Password),
                new String'("-nokeys"),
                new String'("-noout")],
               Sink,
               Spawned,
               Code,
               Err_To_Out => True);
            if Ada.Directories.Exists (Sink) then
               Ada.Directories.Delete_File (Sink);
            end if;
            return Spawned and then Code = 0;
         end Openssl_Accepts;
      begin
         if Found = null then
            Ada.Text_IO.Put_Line
              ("   (skipped: no openssl on this host to read the bundle back)");
         else
            Devcert_Secure_Files.Atomic_Write_Raw
              (Bundle_Path, To_String (Bundle));
            Assert
              (Openssl_Accepts ("secret"),
               "the bundle opens with the password it was built with");
            Assert
              (not Openssl_Accepts ("not-the-password"),
               "and does not open with another");
            GNAT.OS_Lib.Free (Found);
            Ada.Directories.Delete_File (Bundle_Path);
         end if;
      end;
   end Run_Test;

end Devcert_Test_Suite.Certificate_Tests;
