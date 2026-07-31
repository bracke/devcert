with Devcert.Context;

package Devcert.Commands is
   --  Run the named command. The name has already been accepted by the CLI;
   --  an unknown one here does nothing rather than failing, because refusing
   --  it is the parser's job and doing it twice invites the two to disagree.
   --  @param Context The run.
   --  @param Command Command name.
   procedure Dispatch
     (Context : in out Devcert.Context.Runtime_Context;
      Command : String);
end Devcert.Commands;
