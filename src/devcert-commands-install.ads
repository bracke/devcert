with Devcert.Context;
with Devcert_Trust_Stores;

package Devcert.Commands.Install is
   --  Install the CA in the stores the run selected, or the default
   --  selection when it named none.
   --  @param Context The run.
   procedure Run (Context : Devcert.Context.Runtime_Context);

   --  Install the CA in exactly these stores.
   --  @param Context The run.
   --  @param Selection Stores to act on. Each reports its own outcome, and
   --         the exit status distinguishes all of them succeeding from some.
   procedure Run
     (Context   : Devcert.Context.Runtime_Context;
      Selection : Devcert_Trust_Stores.Store_Selection);
end Devcert.Commands.Install;
