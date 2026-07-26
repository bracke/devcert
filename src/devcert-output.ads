with Devcert.Context;

package Devcert.Output is
   type Role is (Header, Success, Information, Warning, Error, Debug);

   procedure Info
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String);

   procedure Error
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String);

   procedure Artifact
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Name    : String;
      Value   : String);
end Devcert.Output;
