with Devcert.Context;

package Devcert.Commands.Doctor is
   --  Report the state of the CA and of each trust store, changing nothing.
   --  @param Context The run.
   procedure Run (Context : Devcert.Context.Runtime_Context);
end Devcert.Commands.Doctor;
