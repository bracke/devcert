with Ada.Command_Line;
with Ada.Strings.Unbounded;

with Devcert.CA_Store;
with Devcert_Crypto;
with Devcert_Exit_Codes;
with Devcert_Messages;
with Devcert.Output;
with Devcert_Secure_Files;
with Devcert_State;

package body Devcert.Commands.Install is
   procedure Run (Context : Devcert.Context.Runtime_Context) is
   begin
      Run (Context, Devcert_Trust_Stores.Default_Selection);
   end Run;

   procedure Run
     (Context   : Devcert.Context.Runtime_Context;
      Selection : Devcert_Trust_Stores.Store_Selection)
   is
      CA_State : constant Devcert.CA_Store.CA_State := Devcert.CA_Store.Ensure;
      Trust_State : Devcert_Trust_Stores.Trust_State;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      use type Devcert.CA_Store.CA_State;
      use type Devcert_Trust_Stores.Trust_State;
   begin
      if CA_State /= Devcert.CA_Store.Complete then
         Devcert.Output.Error
           (Context,
            "install",
            Devcert_Messages.Text
              ("error.ca_unusable", Devcert.CA_Store.State_Image (CA_State)));
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (Devcert_Exit_Codes.CA_State_Error));
         return;
      end if;

      declare
         Certificate : constant String := Devcert_State.CA_Certificate_Path;
         Certificate_Text : constant String :=
           Devcert_Secure_Files.Read (Certificate);
      begin
         Devcert_Trust_Stores.Apply
           (Selection,
            Devcert_Trust_Stores.Install,
            Certificate,
            Devcert_Crypto.SHA256_Fingerprint (Certificate_Text),
            Trust_State,
            Message);
      end;

      if Trust_State = Devcert_Trust_Stores.Installed then
         Devcert.Output.Info
           (Context, "install", Ada.Strings.Unbounded.To_String (Message));
      elsif Trust_State = Devcert_Trust_Stores.Partial then
         Devcert.Output.Error
           (Context, "install", Ada.Strings.Unbounded.To_String (Message));
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (Devcert_Exit_Codes.Partial_Success));
      elsif Trust_State = Devcert_Trust_Stores.Permission_Required then
         --  Distinct from a broken store: the caller has something to do about
         --  it. Folding this into the trust-store code left the commonest
         --  failure of all -- a system store wanting elevated privileges --
         --  indistinguishable from one that is unusable.
         Devcert.Output.Error
           (Context, "install", Ada.Strings.Unbounded.To_String (Message));
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (Devcert_Exit_Codes.Permission_Error));
      else
         Devcert.Output.Error
           (Context, "install", Ada.Strings.Unbounded.To_String (Message));
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (Devcert_Exit_Codes.Trust_Store_Error));
      end if;
   end Run;
end Devcert.Commands.Install;
