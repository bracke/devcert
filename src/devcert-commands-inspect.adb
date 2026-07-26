with Devcert_Crypto;
with Devcert_Messages;
with Devcert.Output;
with Devcert_Secure_Files;
with Devcert_State;

package body Devcert.Commands.Inspect is
   procedure Run (Context : Devcert.Context.Runtime_Context) is
      Certificate : constant String := Devcert_State.CA_Certificate_Path;
   begin
      if Devcert_Secure_Files.Exists (Certificate) then
         declare
            Certificate_Text : constant String :=
              Devcert_Secure_Files.Read (Certificate);
         begin
            Devcert.Output.Info
              (Context,
               "inspect",
               Devcert_Messages.Text
                  ("inspect.ca",
                  Certificate & " fingerprint="
                  & Devcert_Crypto.SHA256_Fingerprint (Certificate_Text)));
         end;
      else
         Devcert.Output.Info
           (Context,
            "inspect",
            Devcert_Messages.Text ("inspect.ca_missing", Certificate));
      end if;
   end Run;
end Devcert.Commands.Inspect;
