with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Devcert_Core;
with Devcert.Certificate_Requests;
with Devcert.Commands;
with Devcert.Commands.Cert;
with Devcert.Commands.Install;
with Devcert.Commands.Uninstall;
with Devcert_Exit_Codes;
with Devcert_Messages;
with Devcert.Output;
with Devcert_Secure_Files;
with Devcert_Trust_Stores;

package body Devcert.CLI is

   procedure Run (Context : in out Devcert.Context.Runtime_Context) is
      use Ada.Strings.Unbounded;

      JSON_Mode     : Boolean := Context.JSON_Output;
      Plain_Mode    : Boolean := Context.Plain_Output;
      Color         : Devcert.Context.Color_Mode := Context.Color;
      Command_Index : Natural := 0;
      Usage_Failed  : Boolean := False;

      procedure Set_Status (Code : Integer) is
      begin
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Code));
      end Set_Status;

      function Argument (Index : Positive) return String renames Ada.Command_Line.Argument;

      function Command return String is
      begin
         if Command_Index /= 0 then
            return Argument (Command_Index);
         else
            return "";
         end if;
      end Command;

      procedure Usage_Error (Message : String) is
      begin
         Usage_Failed := True;
         Context.JSON_Output := JSON_Mode;
         Context.Plain_Output := Plain_Mode;
         Context.Color := Color;
         Devcert.Output.Error
           (Context, Command, Devcert_Messages.Text ("error.devcert", Message));
         Set_Status (Devcert_Exit_Codes.Usage_Error);
      end Usage_Error;

      procedure Print_Info (Message : String) is
      begin
         Devcert.Output.Info (Context, Command, Message);
      end Print_Info;

      procedure Print_Error
        (Message : String;
         Code    : Integer := Devcert_Exit_Codes.General_Failure) is
      begin
         Devcert.Output.Error (Context, Command, Message);
         Set_Status (Code);
      end Print_Error;

      procedure Print_Help is
      begin
         Print_Info (Devcert_Messages.Text ("app.name") & " " & Devcert_Core.Version);
         Print_Info (Devcert_Messages.Text ("cli.usage"));
         Print_Info (Devcert_Messages.Text ("cli.commands"));
         Print_Info (Devcert_Messages.Text ("cli.global_options"));
         Print_Info (Devcert_Messages.Text ("cli.global_options_paths"));
      end Print_Help;

      procedure Parse_Global_Options is
         Seen_Color   : Boolean := False;
         Seen_Plain   : Boolean := False;
         Seen_JSON    : Boolean := False;
         Seen_Locale  : Boolean := False;
         Seen_Catalog : Boolean := False;
         Seen_CA_Root : Boolean := False;
         Index        : Positive := 1;

         function Need_Value (Name : String) return Boolean is
         begin
            if Index = Ada.Command_Line.Argument_Count then
               Usage_Error (Devcert_Messages.Text ("error.missing_value", Name));
               return False;
            end if;
            return True;
         end Need_Value;
      begin
         while Index <= Ada.Command_Line.Argument_Count loop
            declare
               Item : constant String := Argument (Index);
            begin
               if Item = "--help" then
                  Command_Index := Index;
                  return;
               elsif Item = "--version" then
                  Command_Index := Index;
                  return;
               elsif Item = "--json" then
                  if Seen_JSON then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--json"));
                  end if;
                  Seen_JSON := True;
                  JSON_Mode := True;
               elsif Item = "--plain" then
                  if Seen_Plain then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--plain"));
                  end if;
                  Seen_Plain := True;
                  Plain_Mode := True;
               elsif Ada.Strings.Fixed.Index (Item, "--color=") = Item'First then
                  if Seen_Color then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--color"));
                  elsif Item = "--color=auto" then
                     Color := Devcert.Context.Auto;
                  elsif Item = "--color=always" then
                     Color := Devcert.Context.Always;
                  elsif Item = "--color=never" then
                     Color := Devcert.Context.Never;
                  else
                     Usage_Error (Devcert_Messages.Text ("error.invalid_color"));
                  end if;
                  Seen_Color := True;
               elsif Item = "--locale" then
                  if Seen_Locale then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--locale"));
                  elsif Need_Value (Item) then
                     Index := Index + 1;
                     Ada.Environment_Variables.Set ("DEVCERT_LOCALE", Argument (Index));
                     Seen_Locale := True;
                  end if;
               elsif Item = "--catalog" then
                  if Seen_Catalog then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--catalog"));
                  elsif Need_Value (Item) then
                     Index := Index + 1;
                     Ada.Environment_Variables.Set ("DEVCERT_CATALOG", Argument (Index));
                     Seen_Catalog := True;
                  end if;
               elsif Item = "--ca-root" then
                  if Seen_CA_Root then
                     Usage_Error
                       (Devcert_Messages.Text ("error.duplicate_option", "--ca-root"));
                  elsif Need_Value (Item) then
                     Index := Index + 1;
                     Ada.Environment_Variables.Set ("DEVCERT_CAROOT", Argument (Index));
                     Seen_CA_Root := True;
                  end if;
               elsif Item'Length > 0 and then Item (Item'First) = '-' then
                  Usage_Error (Devcert_Messages.Text ("error.unknown_option", Item));
               else
                  Command_Index := Index;
                  return;
               end if;

               exit when Usage_Failed;
               Index := Index + 1;
            end;
         end loop;
      end Parse_Global_Options;

      function Has_Command_Arguments return Boolean is
      begin
         return Command_Index /= 0
           and then Ada.Command_Line.Argument_Count > Command_Index;
      end Has_Command_Arguments;

      procedure Handle_Cert is
         Options     : Devcert.Commands.Cert.Options;
         Status      : Devcert.Certificate_Requests.Request_Status;
         Password_Set : Boolean := False;
         use type Devcert.Certificate_Requests.Request_Status;

         function Need_Value (Index : Positive; Name : String) return Boolean is
         begin
            if Index = Ada.Command_Line.Argument_Count then
               Usage_Error (Devcert_Messages.Text ("error.missing_value", Name));
               return False;
            end if;
            return True;
         end Need_Value;
      begin
         if Has_Command_Arguments then
            declare
               Index : Positive := Command_Index + 1;
            begin
               while Index <= Ada.Command_Line.Argument_Count loop
                  declare
                     Item : constant String := Argument (Index);
                  begin
                     if Item = "--server" then
                        if Options.Request.Count /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text ("error.profile_order"));
                           return;
                        end if;
                        Options.Request := Devcert.Certificate_Requests.Empty;
                     elsif Item = "--client" then
                        if Options.Request.Count /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text ("error.profile_order"));
                           return;
                        end if;
                        Options.Request :=
                          Devcert.Certificate_Requests.Empty
                            (Devcert.Certificate_Requests.Client);
                     elsif Item = "--email" then
                        if Options.Request.Count /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text ("error.profile_order"));
                           return;
                        end if;
                        Options.Request :=
                          Devcert.Certificate_Requests.Empty
                            (Devcert.Certificate_Requests.Email);
                     elsif Item = "--csr" then
                        if Options.Has_CSR then
                           Usage_Error
                             (Devcert_Messages.Text ("error.duplicate_option", "--csr"));
                           return;
                        elsif not Need_Value (Index, Item) then
                           return;
                        end if;
                        Index := Index + 1;
                        Options.Has_CSR := True;
                        Options.CSR_File := To_Unbounded_String (Argument (Index));
                     elsif Item = "--pkcs12" then
                        if Options.Make_PKCS12 then
                           Usage_Error
                             (Devcert_Messages.Text
                                ("error.duplicate_option", "--pkcs12"));
                           return;
                        end if;
                        Options.Make_PKCS12 := True;
                     elsif Item = "--p12-file" then
                        if Length (Options.PKCS12_File) /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text
                                ("error.duplicate_option", "--p12-file"));
                           return;
                        elsif not Need_Value (Index, Item) then
                           return;
                        end if;
                        Index := Index + 1;
                        Options.PKCS12_File := To_Unbounded_String (Argument (Index));
                        Options.Make_PKCS12 := True;
                     elsif Item = "--cert-file" then
                        if Length (Options.Cert_File) /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text
                                ("error.duplicate_option", "--cert-file"));
                           return;
                        elsif not Need_Value (Index, Item) then
                           return;
                        end if;
                        Index := Index + 1;
                        Options.Cert_File := To_Unbounded_String (Argument (Index));
                     elsif Item = "--key-file" then
                        if Length (Options.Key_File) /= 0 then
                           Usage_Error
                             (Devcert_Messages.Text
                                ("error.duplicate_option", "--key-file"));
                           return;
                        elsif not Need_Value (Index, Item) then
                           return;
                        end if;
                        Index := Index + 1;
                        Options.Key_File := To_Unbounded_String (Argument (Index));
                     elsif Item = "--p12-password-file" then
                        if Password_Set then
                           Usage_Error
                             (Devcert_Messages.Text ("error.duplicate_p12_password"));
                           return;
                        elsif not Need_Value (Index, Item) then
                           return;
                        end if;
                        Index := Index + 1;
                        Options.Password :=
                          To_Unbounded_String
                            (Devcert_Secure_Files.Read (Argument (Index)));
                        Password_Set := True;
                     elsif Item = "--p12-password-stdin" then
                        if Password_Set then
                           Usage_Error
                             (Devcert_Messages.Text ("error.duplicate_p12_password"));
                           return;
                        end if;
                        Options.Password := To_Unbounded_String (Ada.Text_IO.Get_Line);
                        Password_Set := True;
                     elsif Item'Length > 0 and then Item (Item'First) = '-' then
                        Usage_Error
                          (Devcert_Messages.Text ("error.unknown_cert_option", Item));
                        return;
                     else
                        Status :=
                          Devcert.Certificate_Requests.Add_Identity
                            (Options.Request, Argument (Index));
                        if Status = Devcert.Certificate_Requests.Invalid_Identity then
                           Print_Error
                             (Devcert_Messages.Text
                                ("error.invalid_identity", Argument (Index)),
                              Devcert_Exit_Codes.Certificate_Error);
                           return;
                        elsif Status =
                          Devcert.Certificate_Requests.Mixed_Identity_Modes
                        then
                           Print_Error
                             (Devcert_Messages.Text ("error.mixed_identity_modes"),
                              Devcert_Exit_Codes.Certificate_Error);
                           return;
                        elsif Status =
                          Devcert.Certificate_Requests.Too_Many_Identities
                        then
                           Print_Error
                             (Devcert_Messages.Text ("error.too_many_identities"),
                              Devcert_Exit_Codes.Certificate_Error);
                           return;
                        end if;
                     end if;
                  end;
                  Index := Index + 1;
               end loop;
            end;
         end if;

         if Options.Has_CSR then
            if Options.Request.Count /= 0
              or else Options.Make_PKCS12
              or else Length (Options.Key_File) /= 0
            then
               Usage_Error (Devcert_Messages.Text ("error.csr_combination"));
               return;
            end if;
         end if;

         Devcert.Commands.Cert.Run (Context, Options);
      end Handle_Cert;

      procedure Handle_Trust (Operation : Devcert_Trust_Stores.Action) is
         Selection : Devcert_Trust_Stores.Store_Selection :=
           Devcert_Trust_Stores.Default_Selection;

         function Parse_Selection return Boolean is
            Index      : Positive := Command_Index + 1;
            Seen_Store : Boolean := False;
         begin
            if Ada.Environment_Variables.Exists ("DEVCERT_TRUST_STORES") then
               if not Devcert_Trust_Stores.Selection_From_Text
                 (Ada.Environment_Variables.Value ("DEVCERT_TRUST_STORES"),
                  Selection)
               then
                  Usage_Error
                    (Devcert_Messages.Text
                       ("error.unknown_trust_store",
                        Ada.Environment_Variables.Value ("DEVCERT_TRUST_STORES")));
                  return False;
               end if;
               Seen_Store := True;
            end if;

            while Index <= Ada.Command_Line.Argument_Count loop
               declare
                  Item : constant String := Argument (Index);
               begin
                  if Item = "--trust-store" then
                     if Seen_Store then
                        Usage_Error
                          (Devcert_Messages.Text
                             ("error.duplicate_option", "--trust-store"));
                        return False;
                     elsif Index = Ada.Command_Line.Argument_Count then
                        Usage_Error
                          (Devcert_Messages.Text
                             ("error.missing_value", "--trust-store"));
                        return False;
                     end if;
                     Index := Index + 1;
                     if not Devcert_Trust_Stores.Selection_From_Text
                       (Argument (Index), Selection)
                     then
                        Usage_Error
                          (Devcert_Messages.Text
                             ("error.unknown_trust_store", Argument (Index)));
                        return False;
                     end if;
                     Seen_Store := True;
                  elsif Item'Length > 0 and then Item (Item'First) = '-' then
                     Usage_Error
                       (Devcert_Messages.Text ("error.unknown_trust_option", Item));
                     return False;
                  elsif not Devcert_Trust_Stores.Selection_From_Text
                    (Item, Selection)
                  then
                     Usage_Error
                       (Devcert_Messages.Text ("error.unknown_trust_store", Item));
                     return False;
                  else
                     Seen_Store := True;
                  end if;
                  Index := Index + 1;
               end;
            end loop;
            return True;
         end Parse_Selection;
      begin
         if not Parse_Selection then
            return;
         end if;

         case Operation is
            when Devcert_Trust_Stores.Install =>
               Devcert.Commands.Install.Run (Context, Selection);
            when Devcert_Trust_Stores.Remove =>
               Devcert.Commands.Uninstall.Run (Context, Selection);
         end case;
      end Handle_Trust;

   begin
      Parse_Global_Options;
      Context.JSON_Output := JSON_Mode;
      Context.Plain_Output := Plain_Mode;
      Context.Color := Color;
      if Usage_Failed then
         return;
      end if;

      if Command_Index = 0 then
         Usage_Error (Devcert_Messages.Text ("error.missing_value", "command"));
      elsif Command = "--help" or else Command = "help" then
         Print_Help;
      elsif Command = "--version" or else Command = "version" then
         Devcert.Output.Artifact (Context, Command, "version", Devcert_Core.Version);
      elsif Command = "caroot" then
         Devcert.Commands.Dispatch (Context, Command);
      elsif Command = "cert" then
         Handle_Cert;
      elsif Command = "install" then
         Handle_Trust (Devcert_Trust_Stores.Install);
      elsif Command = "uninstall" then
         Handle_Trust (Devcert_Trust_Stores.Remove);
      elsif Command = "inspect" then
         Devcert.Commands.Dispatch (Context, Command);
      elsif Command = "doctor" then
         Devcert.Commands.Dispatch (Context, Command);
      else
         Usage_Error
           (Devcert_Messages.Text ("error.unknown_command", ": " & Command));
      end if;
   end Run;

end Devcert.CLI;
