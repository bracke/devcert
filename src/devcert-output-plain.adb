with Ada.Text_IO;

package body Devcert.Output.Plain is
   procedure Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Info;

   procedure Error (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
   end Error;
end Devcert.Output.Plain;
