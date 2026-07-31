package Devcert_JSON is
   --  @param Text Text to put inside a JSON string.
   --  @return It with the characters JSON reserves escaped.
   function Escape (Text : String) return String;
   --  @param Command Command the error came from.
   --  @param Message What went wrong.
   --  @return A complete JSON object carrying the schema version, status and
   --          command fields that do not change between locales.
   function Error (Command : String; Message : String) return String;
   --  @param Command Command reporting.
   --  @param Message What happened.
   --  @return A complete JSON status object.
   function Status (Command : String; Message : String) return String;
   --  @param Command Command reporting.
   --  @param Name What the value is.
   --  @param Value The value itself -- a path, a fingerprint.
   --  @return A complete JSON object naming one artifact.
   function Artifact
     (Command : String;
      Name    : String;
      Value   : String) return String;
end Devcert_JSON;
