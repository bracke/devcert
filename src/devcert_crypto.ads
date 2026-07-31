with Ada.Strings.Unbounded;

with Devcert.Certificate_Requests;

package Devcert_Crypto is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Operation_Status is
     (Ok,
      Invalid_Request,
      Unsupported_Profile,
      Unsupported);

   --  @param Data Bytes to hash.
   --  @return The SHA-256 digest, colon-separated, as certificate tools show it.
   function SHA256_Fingerprint (Data : String) return String;

   --  The certificate's own fingerprint, as every other reader shows it: over
   --  the DER, not over the armoured text.
   --  @param Certificate_PEM The certificate, armoured.
   --  @return Its fingerprint, which is what a trust store indexes it by.
   function Certificate_Fingerprint (Certificate_PEM : String) return String;

   --  Issue a new local development certificate authority.
   --  @param Certificate_PEM The CA certificate.
   --  @param Private_Key_PEM Its private key, which never leaves this machine
   --         and is never installed into a trust store.
   --  @return Ok, or why no CA was made.
   function Create_CA
     (Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   --  Issue a certificate for one name, with the default profile.
   --  @param Name Subject name to issue for.
   --  @param Certificate_PEM The issued certificate.
   --  @param Private_Key_PEM Its private key.
   --  @return Ok, or why nothing was issued.
   function Issue_Certificate
     (Name            : String;
      Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   --  Issue a certificate from a request, which carries the names and the
   --  profile rather than assuming either.
   --  @param Request What to issue.
   --  @param Certificate_PEM The issued certificate.
   --  @param Private_Key_PEM Its private key.
   --  @return Ok, Invalid_Request, or Unsupported_Profile.
   function Issue_Certificate
     (Request         : Devcert.Certificate_Requests.Request;
      Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   --  Sign a certificate request, keeping the subject and public key it
   --  carries: the requester's key never comes here, which is the point of a
   --  CSR.
   --  @param CSR_PEM The request, armoured.
   --  @param Certificate_PEM The issued certificate.
   --  @return Ok, or why the request was refused.
   function Sign_CSR
     (CSR_PEM         : String;
      Certificate_PEM : out Unbounded_String) return Operation_Status;

   --  Do these two belong together?
   --  @param Certificate_PEM The certificate.
   --  @param Private_Key_PEM The key it should correspond to.
   --  @return Ok when the key matches the certificate's public key.
   function Private_Key_Matches_Certificate
     (Certificate_PEM : String;
      Private_Key_PEM : String) return Operation_Status;

   --  Bundle a freshly issued certificate and key as PKCS#12, unprotected.
   --  @param Name Subject name to issue for.
   --  @param Bundle_Data The bundle.
   --  @return Ok, or why nothing was produced.
   function Generate_PKCS12
     (Name        : String;
      Bundle_Data : out Unbounded_String) return Operation_Status;

   --  The same, protected by a password.
   --  @param Name Subject name to issue for.
   --  @param Password Passphrase for the bundle's MAC and encryption.
   --  @param Bundle_Data The bundle.
   --  @return Ok, or why nothing was produced.
   function Generate_PKCS12
     (Name        : String;
      Password    : String;
      Bundle_Data : out Unbounded_String) return Operation_Status;

   --  Bundle a certificate and key the caller already has, rather than
   --  issuing new ones.
   --  @param Certificate_PEM The certificate to bundle.
   --  @param Private_Key_PEM Its private key.
   --  @param Name Friendly name recorded in the bundle.
   --  @param Password Passphrase for the bundle's MAC and encryption.
   --  @param Bundle_Data The bundle.
   --  @return Ok, or why nothing was produced.
   function Generate_PKCS12
     (Certificate_PEM : String;
      Private_Key_PEM : String;
      Name            : String;
      Password        : String;
      Bundle_Data     : out Unbounded_String) return Operation_Status;
end Devcert_Crypto;
