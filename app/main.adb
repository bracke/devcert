with Devcert.CLI;
with Devcert.Context;
with Devcert.Trust_Setup;

procedure Main is
   Context : Devcert.Context.Runtime_Context;
begin
   --  Before anything looks at a trust store: the crate that owns them has to
   --  be told which environment variables devcert documents.
   Devcert.Trust_Setup.Apply;
   Devcert.CLI.Run (Context);
end Main;
