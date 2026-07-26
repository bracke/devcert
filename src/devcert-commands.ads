with Devcert.Context;

package Devcert.Commands is
   procedure Dispatch
     (Context : in out Devcert.Context.Runtime_Context;
      Command : String);
end Devcert.Commands;
