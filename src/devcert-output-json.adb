with Ada.Text_IO;

with Devcert_JSON;

package body Devcert.Output.JSON is
   procedure Info (Command : String; Message : String) is
   begin
      Ada.Text_IO.Put_Line (Devcert_JSON.Status (Command, Message));
   end Info;

   procedure Error (Command : String; Message : String) is
   begin
      Ada.Text_IO.Put_Line (Devcert_JSON.Error (Command, Message));
   end Error;

   procedure Artifact (Command : String; Name : String; Value : String) is
   begin
      Ada.Text_IO.Put_Line (Devcert_JSON.Artifact (Command, Name, Value));
   end Artifact;
end Devcert.Output.JSON;
