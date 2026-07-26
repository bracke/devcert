with Devcert.Commands.CARoot;
with Devcert.Commands.Cert;
with Devcert.Commands.Doctor;
with Devcert.Commands.Inspect;
with Devcert.Commands.Install;
with Devcert.Commands.Uninstall;

package body Devcert.Commands is
   procedure Dispatch
     (Context : in out Devcert.Context.Runtime_Context;
      Command : String) is
   begin
      if Command = "caroot" then
         Devcert.Commands.CARoot.Run (Context);
      elsif Command = "cert" then
         Devcert.Commands.Cert.Run (Context, "localhost");
      elsif Command = "install" then
         Devcert.Commands.Install.Run (Context);
      elsif Command = "uninstall" then
         Devcert.Commands.Uninstall.Run (Context);
      elsif Command = "inspect" then
         Devcert.Commands.Inspect.Run (Context);
      elsif Command = "doctor" then
         Devcert.Commands.Doctor.Run (Context);
      end if;
   end Dispatch;
end Devcert.Commands;
