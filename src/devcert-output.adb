with Ada.Environment_Variables;

with Devcert.Output.JSON;
with Devcert.Output.Plain;
with Devcert.Output.Terminal;

package body Devcert.Output is
   use type Devcert.Context.Color_Mode;

   function Plain_Selected (Context : Devcert.Context.Runtime_Context) return Boolean is
   begin
      return Context.Plain_Output
        or else Context.Color = Devcert.Context.Never
        or else
          (Context.Color = Devcert.Context.Auto
           and then Ada.Environment_Variables.Exists ("NO_COLOR"));
   end Plain_Selected;

   procedure Info
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String) is
   begin
      if Context.JSON_Output then
         Devcert.Output.JSON.Info (Command, Message);
      elsif Plain_Selected (Context) then
         Devcert.Output.Plain.Info (Message);
      else
         Devcert.Output.Terminal.Info (Message);
      end if;
   end Info;

   procedure Error
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Message : String) is
   begin
      if Context.JSON_Output then
         Devcert.Output.JSON.Error (Command, Message);
      elsif Plain_Selected (Context) then
         Devcert.Output.Plain.Error (Message);
      else
         Devcert.Output.Terminal.Error (Message);
      end if;
   end Error;

   procedure Artifact
     (Context : Devcert.Context.Runtime_Context;
      Command : String;
      Name    : String;
      Value   : String) is
   begin
      if Context.JSON_Output then
         Devcert.Output.JSON.Artifact (Command, Name, Value);
      else
         Info (Context, Command, Value);
      end if;
   end Artifact;
end Devcert.Output;
