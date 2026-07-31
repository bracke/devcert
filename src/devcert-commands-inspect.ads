with Devcert.Context;

package Devcert.Commands.Inspect is
   --  Report what the CA is: its subject, validity and fingerprint.
   --  @param Context The run.
   procedure Run (Context : Devcert.Context.Runtime_Context);
end Devcert.Commands.Inspect;
