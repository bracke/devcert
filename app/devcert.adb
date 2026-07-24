with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Devcert_Crypto;
with Devcert_Core;
with Devcert_JSON;
with Devcert_Messages;
with Devcert_Secure_Files;
with Devcert_State;
with Devcert_Trust_Stores;
with Terminal_Styles;

procedure Devcert is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;

   JSON_Mode : constant Boolean :=
     Ada.Command_Line.Argument_Count > 0
     and then Ada.Command_Line.Argument (1) = "--json";

   First_Command : constant Positive := (if JSON_Mode then 2 else 1);

   function Has_Command return Boolean is
   begin
      return Ada.Command_Line.Argument_Count >= First_Command;
   end Has_Command;

   function Command return String is
   begin
      if Has_Command then
         return Ada.Command_Line.Argument (First_Command);
      else
         return "";
      end if;
   end Command;

   procedure Print_Info (Message : String) is
   begin
      if JSON_Mode then
         Put_Line (Devcert_JSON.Status (Command, Message));
      else
         Put_Line (Terminal_Styles.Line (Message, Terminal_Styles.Role_Info));
      end if;
   end Print_Info;

   procedure Print_Error (Message : String) is
   begin
      if JSON_Mode then
         Put_Line (Devcert_JSON.Error (Command, Message));
      else
         Put_Line
           (Standard_Error,
            Terminal_Styles.Line (Message, Terminal_Styles.Role_Error));
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Print_Error;

   procedure Print_Help is
   begin
      Put_Line (Devcert_Messages.Text ("app.name") & " " & Devcert_Core.Version);
      Put_Line (Devcert_Messages.Text ("cli.usage"));
      Put_Line ("commands: ca, issue, sign-csr, pkcs12, install, uninstall, inspect");
      Put_Line ("trust targets: linux, nss, java, macos, windows");
   end Print_Help;

   procedure Handle_CA is
      Certificate : Unbounded_String;
      Private_Key : Unbounded_String;
   begin
      case Devcert_Crypto.Create_CA (Certificate, Private_Key) is
         when Devcert_Crypto.Ok =>
            Devcert_Secure_Files.Atomic_Write
              (Devcert_State.CA_Certificate_Path, To_String (Certificate));
            Devcert_Secure_Files.Atomic_Write
              (Devcert_State.CA_Private_Key_Path,
               To_String (Private_Key),
               Secret => True);
            Print_Info ("local CA created");
         when Devcert_Crypto.Unsupported =>
            Print_Error ("cryptolib certificate API is not available");
      end case;
   end Handle_CA;

   procedure Handle_Issue is
      Name        : constant String :=
        (if Ada.Command_Line.Argument_Count > First_Command
         then Ada.Command_Line.Argument (First_Command + 1)
         else "localhost");
      Certificate : Unbounded_String;
      Private_Key : Unbounded_String;
   begin
      case Devcert_Crypto.Issue_Certificate (Name, Certificate, Private_Key) is
         when Devcert_Crypto.Ok =>
            Devcert_Secure_Files.Atomic_Write
              (Devcert_State.Leaf_Certificate_Path (Name), To_String (Certificate));
            Devcert_Secure_Files.Atomic_Write
              (Devcert_State.Leaf_Private_Key_Path (Name),
               To_String (Private_Key),
               Secret => True);
            Print_Info ("certificate issued for " & Name);
         when Devcert_Crypto.Unsupported =>
            Print_Error ("cryptolib certificate API is not available");
      end case;
   end Handle_Issue;

   procedure Handle_Sign_CSR is
      CSR         : constant String :=
        (if Ada.Command_Line.Argument_Count > First_Command
         then Ada.Command_Line.Argument (First_Command + 1)
         else "");
      Certificate : Unbounded_String;
   begin
      case Devcert_Crypto.Sign_CSR (CSR, Certificate) is
         when Devcert_Crypto.Ok =>
            if JSON_Mode then
               Put_Line
                 (Devcert_JSON.Artifact
                    (Command, "certificate", To_String (Certificate)));
            else
               Put_Line (To_String (Certificate));
            end if;
         when Devcert_Crypto.Unsupported =>
            Print_Error ("cryptolib CSR signing API is not available");
      end case;
   end Handle_Sign_CSR;

   procedure Handle_PKCS12 is
      Name   : constant String :=
        (if Ada.Command_Line.Argument_Count > First_Command
         then Ada.Command_Line.Argument (First_Command + 1)
         else "localhost");
      Bundle : Unbounded_String;
   begin
      case Devcert_Crypto.Generate_PKCS12 (Name, Bundle) is
         when Devcert_Crypto.Ok =>
            Devcert_Secure_Files.Atomic_Write_Raw
              (Devcert_State.PKCS12_Path (Name),
               To_String (Bundle),
               Secret => True);
            Print_Info ("PKCS#12 bundle generated for " & Name);
         when Devcert_Crypto.Unsupported =>
            Print_Error ("cryptolib PKCS#12 API is not available");
      end case;
   end Handle_PKCS12;

   procedure Handle_Trust (Operation : Devcert_Trust_Stores.Action) is
      Cert : constant String := Devcert_State.CA_Certificate_Path;
   begin
      if not Devcert_Secure_Files.Exists (Cert) then
         Print_Error ("CA certificate is missing: " & Cert);
         return;
      end if;

      declare
         Body_Text   : constant String := Devcert_Secure_Files.Read (Cert);
         Fingerprint : constant String :=
           Devcert_Crypto.SHA256_Fingerprint (Body_Text);
         Target      : Devcert_Trust_Stores.Trust_Target :=
           Devcert_Trust_Stores.Detect_Default_Target;
         Success     : Boolean := False;
         Message     : Unbounded_String;
      begin
         if Ada.Command_Line.Argument_Count > First_Command
           and then not Devcert_Trust_Stores.Target_From_Name
             (Ada.Command_Line.Argument (First_Command + 1), Target)
         then
            Print_Error
              ("unknown trust target: "
               & Ada.Command_Line.Argument (First_Command + 1));
            return;
         end if;

         Devcert_Trust_Stores.Apply
           (Target, Operation, Cert, Fingerprint, Success, Message);
         if Success then
            Print_Info (To_String (Message));
         else
            Print_Error (To_String (Message));
         end if;
      end;
   end Handle_Trust;

   procedure Handle_Inspect is
      Cert : constant String := Devcert_State.CA_Certificate_Path;
   begin
      if Devcert_Secure_Files.Exists (Cert) then
         declare
            Body_Text : constant String := Devcert_Secure_Files.Read (Cert);
         begin
            Print_Info
              ("ca=" & Cert & " fingerprint="
               & Devcert_Crypto.SHA256_Fingerprint (Body_Text));
         end;
      else
         Print_Info ("ca=missing path=" & Cert);
      end if;
   end Handle_Inspect;
begin
   if JSON_Mode and then Ada.Command_Line.Argument_Count = 1 then
      Put_Line
        ("{""schema"":"
         & Devcert_Core.Json_Schema_Version
         & ",""version"":"""
         & Devcert_Core.Version
         & """}");
   elsif Ada.Command_Line.Argument_Count = 0 then
      Print_Help;
   elsif Command = "--help" then
      Print_Help;
   elsif Command = "--version" then
      Put_Line (Devcert_Core.Version);
   elsif Command = "ca" then
      Handle_CA;
   elsif Command = "issue" then
      Handle_Issue;
   elsif Command = "sign-csr" then
      Handle_Sign_CSR;
   elsif Command = "pkcs12" then
      Handle_PKCS12;
   elsif Command = "install" then
      Handle_Trust (Devcert_Trust_Stores.Install);
   elsif Command = "uninstall" then
      Handle_Trust (Devcert_Trust_Stores.Remove);
   elsif Command = "inspect" then
      Handle_Inspect;
   else
      Print_Error
        ("devcert: " & Devcert_Messages.Text ("error.unknown_command") & ": "
         & Command);
   end if;
end Devcert;
