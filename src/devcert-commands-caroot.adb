with Devcert.Output;
with Devcert_State;

package body Devcert.Commands.CARoot is
   procedure Run (Context : Devcert.Context.Runtime_Context) is
   begin
      Devcert.Output.Artifact
        (Context, "caroot", "path", Devcert_State.Base_Directory);
   end Run;
end Devcert.Commands.CARoot;
