package Devcert_JSON is
   function Escape (Text : String) return String;
   function Error (Command : String; Message : String) return String;
   function Status (Command : String; Message : String) return String;
   function Artifact
     (Command : String;
      Name    : String;
      Value   : String) return String;
end Devcert_JSON;
