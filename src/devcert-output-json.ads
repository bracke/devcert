package Devcert.Output.JSON is
   --  @param Command Command reporting.
   --  @param Message What happened; written as a JSON object.
   procedure Info (Command : String; Message : String);
   --  @param Command Command reporting.
   --  @param Message What went wrong; written as a JSON object.
   procedure Error (Command : String; Message : String);
   --  @param Command Command reporting.
   --  @param Name What the value is.
   --  @param Value The value itself; written as a JSON object.
   procedure Artifact (Command : String; Name : String; Value : String);
end Devcert.Output.JSON;
