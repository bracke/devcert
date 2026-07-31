with Devcert.Context;

package Devcert.CLI is
   --  Parse the command line and carry out what it asked for. This is the
   --  whole of the program's behaviour; main does nothing but call it.
   --  @param Context The run: output form, locale, CA root, exit status.
   procedure Run (Context : in out Devcert.Context.Runtime_Context);
end Devcert.CLI;
