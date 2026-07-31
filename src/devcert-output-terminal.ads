package Devcert.Output.Terminal is
   --  @param Message What happened; written with terminal styling, when the output is a terminal.
   procedure Info (Message : String);
   --  @param Message What went wrong; written with terminal styling, when the output is a terminal.
   procedure Error (Message : String);
end Devcert.Output.Terminal;
