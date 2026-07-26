package Devcert.Output.JSON is
   procedure Info (Command : String; Message : String);
   procedure Error (Command : String; Message : String);
   procedure Artifact (Command : String; Name : String; Value : String);
end Devcert.Output.JSON;
