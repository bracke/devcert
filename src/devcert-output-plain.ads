package Devcert.Output.Plain is
   --  @param Message What happened; written as plain text, with no styling at all.
   procedure Info (Message : String);
   --  @param Message What went wrong; written as plain text, with no styling at all.
   procedure Error (Message : String);
end Devcert.Output.Plain;
