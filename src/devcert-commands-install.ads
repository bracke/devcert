with Devcert.Context;
with Devcert_Trust_Stores;

package Devcert.Commands.Install is
   procedure Run (Context : Devcert.Context.Runtime_Context);

   procedure Run
     (Context   : Devcert.Context.Runtime_Context;
      Selection : Devcert_Trust_Stores.Store_Selection);
end Devcert.Commands.Install;
