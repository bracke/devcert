with Ada.Command_Line;

with Devcert.Output;
with Devcert.CA_Store;
with Devcert_Crypto;
with Devcert_Exit_Codes;
with Devcert_Messages;
with Devcert_Secure_Files;
with Devcert_State;

package body Devcert.Commands.Cert is
   use Ada.Strings.Unbounded;
   use type Devcert.CA_Store.CA_State;
   use type Devcert_Crypto.Operation_Status;

   procedure Set_Status (Code : Integer) is
   begin
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Code));
   end Set_Status;

   procedure Print_Error
     (Context : Devcert.Context.Runtime_Context;
      Message : String;
      Code    : Integer := Devcert_Exit_Codes.General_Failure) is
   begin
      Devcert.Output.Error (Context, "cert", Message);
      Set_Status (Code);
   end Print_Error;

   procedure Reject_Cert_Status
     (Context   : Devcert.Context.Runtime_Context;
      Request   : Devcert.Certificate_Requests.Request;
      Op_Status : Devcert_Crypto.Operation_Status) is
   begin
      case Op_Status is
         when Devcert_Crypto.Invalid_Request =>
            Print_Error
              (Context,
               Devcert_Messages.Text ("error.invalid_certificate_request"),
               Devcert_Exit_Codes.Certificate_Error);
         when Devcert_Crypto.Unsupported_Profile =>
            Print_Error
              (Context,
               Devcert_Messages.Text
                 ("error.unsupported_certificate_profile",
                  Devcert.Certificate_Requests.Mode_Image (Request.Mode)),
               Devcert_Exit_Codes.Unsupported_Feature);
         when Devcert_Crypto.Unsupported =>
            Print_Error
              (Context,
               Devcert_Messages.Text ("error.crypto_api_unavailable"),
               Devcert_Exit_Codes.Cryptographic_Error);
         when Devcert_Crypto.Ok =>
            null;
      end case;
   end Reject_Cert_Status;

   procedure Run
     (Context : Devcert.Context.Runtime_Context;
      Name    : String)
   is
      Item   : Options;
      Status : Devcert.Certificate_Requests.Request_Status;
      use type Devcert.Certificate_Requests.Request_Status;
   begin
      Status := Devcert.Certificate_Requests.Add_Identity (Item.Request, Name);
      if Status = Devcert.Certificate_Requests.Valid then
         Run (Context, Item);
      else
         Print_Error
           (Context,
            Devcert_Messages.Text ("error.invalid_identity", Name),
            Devcert_Exit_Codes.Certificate_Error);
      end if;
   end Run;

   procedure Run
     (Context : Devcert.Context.Runtime_Context;
      Item    : Options)
   is
      Request     : Devcert.Certificate_Requests.Request := Item.Request;
      Certificate : Unbounded_String;
      Private_Key : Unbounded_String;
      Bundle      : Unbounded_String;
      CA_State    : Devcert.CA_Store.CA_State;
      Issue_Status : Devcert_Crypto.Operation_Status;
   begin
      CA_State := Devcert.CA_Store.Ensure;
      if CA_State /= Devcert.CA_Store.Complete then
         Print_Error
           (Context,
            Devcert_Messages.Text
              ("error.ca_unusable", Devcert.CA_Store.State_Image (CA_State)),
            Devcert_Exit_Codes.CA_State_Error);
         return;
      end if;

      if Item.Has_CSR then
         if not Devcert_Secure_Files.Exists (To_String (Item.CSR_File)) then
            Print_Error
              (Context,
               Devcert_Messages.Text
                 ("error.csr_missing", To_String (Item.CSR_File)),
               Devcert_Exit_Codes.Certificate_Error);
            return;
         end if;

         case Devcert_Crypto.Sign_CSR
           (Devcert_Secure_Files.Read (To_String (Item.CSR_File)), Certificate)
         is
            when Devcert_Crypto.Ok =>
               Devcert_Secure_Files.Atomic_Write
                 ((if Length (Item.Cert_File) = 0
                   then Devcert_State.Leaf_Certificate_Path ("csr")
                   else To_String (Item.Cert_File)),
                  To_String (Certificate));
               Devcert.Output.Info
                 (Context, "cert", Devcert_Messages.Text ("cert.signed_csr"));
            when others =>
               Reject_Cert_Status (Context, Request, Devcert_Crypto.Invalid_Request);
         end case;
         return;
      end if;

      if Request.Count = 0 then
         declare
            Status : constant Devcert.Certificate_Requests.Request_Status :=
              Devcert.Certificate_Requests.Add_Identity (Request, "localhost");
            pragma Unreferenced (Status);
         begin
            null;
         end;
      end if;

      Issue_Status :=
        Devcert_Crypto.Issue_Certificate (Request, Certificate, Private_Key);
      case Issue_Status is
         when Devcert_Crypto.Ok =>
            declare
               Output_Name : constant String :=
                 Devcert.Certificate_Requests.Output_Name (Request);
               Certificate_Path : constant String :=
                 (if Length (Item.Cert_File) = 0
                  then Devcert_State.Leaf_Certificate_Path (Output_Name)
                  else To_String (Item.Cert_File));
               Key_Path : constant String :=
                 (if Length (Item.Key_File) = 0
                  then Devcert_State.Leaf_Private_Key_Path (Output_Name)
                  else To_String (Item.Key_File));
            begin
               Devcert_Secure_Files.Atomic_Write
                 (Certificate_Path, To_String (Certificate));
               Devcert_Secure_Files.Atomic_Write
                 (Key_Path, To_String (Private_Key), Secret => True);
            end;

            Devcert.Output.Info
              (Context,
               "cert",
               Devcert_Messages.Text
                 ("cert.issued",
                  Devcert.Certificate_Requests.Common_Name (Request)));

            if Item.Make_PKCS12 then
               declare
                  Output_Name : constant String :=
                    Devcert.Certificate_Requests.Output_Name (Request);
                  Output_Path : constant String :=
                    (if Length (Item.PKCS12_File) = 0
                     then Devcert_State.PKCS12_Path (Output_Name)
                     else To_String (Item.PKCS12_File));
               begin
                  case Devcert_Crypto.Generate_PKCS12
                    (To_String (Certificate),
                     To_String (Private_Key),
                     Output_Name,
                     To_String (Item.Password),
                     Bundle)
                  is
                     when Devcert_Crypto.Ok =>
                        Devcert_Secure_Files.Atomic_Write_Raw
                          (Output_Path, To_String (Bundle), Secret => True);
                        Devcert.Output.Info
                          (Context,
                           "cert",
                           Devcert_Messages.Text
                             ("cert.p12_written", Output_Path));
                     when others =>
                        Reject_Cert_Status
                          (Context, Request, Devcert_Crypto.Invalid_Request);
                  end case;
               end;
            end if;
         when others =>
            Reject_Cert_Status (Context, Request, Issue_Status);
      end case;
   end Run;
end Devcert.Commands.Cert;
