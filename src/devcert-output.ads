with Devcert.Context;

package Devcert.Output is
   type Role is (Header, Success, Information, Warning, Error, Debug);

   --  Report to the user, in whichever form the run asked for: plain text,
   --  styled terminal output, or JSON. A caller says what happened and does
   --  not choose how it is shown.
   --  @param Context The run, which carries the chosen form and locale.
   --  @param Command Command reporting.
   --  @param Message What happened, already localized.
   procedure Info
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String);

   --  @param Context The run.
   --  @param Command Command reporting.
   --  @param Message What went wrong, already localized.
   procedure Error
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String);

   --  @param Context The run.
   --  @param Command Command reporting.
   --  @param Name What the value is.
   --  @param Value The value itself; it is not localized, being a path or a
   --         fingerprint rather than prose.
   procedure Artifact
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Name    : String;
      Value   : String);
end Devcert.Output;
