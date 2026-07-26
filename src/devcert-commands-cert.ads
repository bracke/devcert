with Ada.Strings.Unbounded;

with Devcert.Context;
with Devcert.Certificate_Requests;

package Devcert.Commands.Cert is
   subtype Unbounded_String is
     Ada.Strings.Unbounded.Unbounded_String;

   type Options is record
      Request      : Devcert.Certificate_Requests.Request :=
        Devcert.Certificate_Requests.Empty;
      Has_CSR      : Boolean := False;
      CSR_File     : Unbounded_String;
      Make_PKCS12  : Boolean := False;
      PKCS12_File  : Unbounded_String;
      Cert_File    : Unbounded_String;
      Key_File     : Unbounded_String;
      Password     : Unbounded_String;
   end record;

   procedure Run
     (Context : Devcert.Context.Runtime_Context;
      Name    : String);

   procedure Run
     (Context : Devcert.Context.Runtime_Context;
      Item    : Options);
end Devcert.Commands.Cert;
