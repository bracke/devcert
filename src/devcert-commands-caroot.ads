with Devcert.Context;

package Devcert.Commands.CARoot is
   --  Print where the CA root is, so a caller can point a tool at it.
   --  @param Context The run.
   procedure Run (Context : Devcert.Context.Runtime_Context);
end Devcert.Commands.CARoot;
