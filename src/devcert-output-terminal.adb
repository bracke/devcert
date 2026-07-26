with Ada.Text_IO;

with Terminal_Styles;

package body Devcert.Output.Terminal is
   procedure Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line
        (Terminal_Styles.Line (Message, Terminal_Styles.Role_Info));
   end Info;

   procedure Error (Message : String) is
   begin
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         Terminal_Styles.Line (Message, Terminal_Styles.Role_Error));
   end Error;
end Devcert.Output.Terminal;
