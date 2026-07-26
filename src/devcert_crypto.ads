with Ada.Strings.Unbounded;

with Devcert.Certificate_Requests;

package Devcert_Crypto is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Operation_Status is
     (Ok,
      Invalid_Request,
      Unsupported_Profile,
      Unsupported);

   function SHA256_Fingerprint (Data : String) return String;

   function Create_CA
     (Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   function Issue_Certificate
     (Name            : String;
      Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   function Issue_Certificate
     (Request         : Devcert.Certificate_Requests.Request;
      Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status;

   function Sign_CSR
     (CSR_PEM         : String;
      Certificate_PEM : out Unbounded_String) return Operation_Status;

   function Private_Key_Matches_Certificate
     (Certificate_PEM : String;
      Private_Key_PEM : String) return Operation_Status;

   function Generate_PKCS12
     (Name        : String;
      Bundle_Data : out Unbounded_String) return Operation_Status;

   function Generate_PKCS12
     (Name        : String;
      Password    : String;
      Bundle_Data : out Unbounded_String) return Operation_Status;

   function Generate_PKCS12
     (Certificate_PEM : String;
      Private_Key_PEM : String;
      Name            : String;
      Password        : String;
      Bundle_Data     : out Unbounded_String) return Operation_Status;
end Devcert_Crypto;
