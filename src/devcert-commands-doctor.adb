with Ada.Command_Line;

with Devcert.CA_Store;
with Devcert_Exit_Codes;
with Devcert_Messages;
with Devcert.Output;

package body Devcert.Commands.Doctor is
   procedure Run (Context : Devcert.Context.Runtime_Context) is
      State : constant Devcert.CA_Store.CA_State := Devcert.CA_Store.Evaluate;
      use type Devcert.CA_Store.CA_State;
   begin
      if State = Devcert.CA_Store.Complete then
         Devcert.Output.Info
           (Context, "doctor", Devcert_Messages.Text ("doctor.ca_complete"));
      else
         Devcert.Output.Error
           (Context,
            "doctor",
            Devcert_Messages.Text
              ("doctor.ca_state", Devcert.CA_Store.State_Image (State)));
         Ada.Command_Line.Set_Exit_Status
           (Ada.Command_Line.Exit_Status (Devcert_Exit_Codes.CA_State_Error));
      end if;
   end Run;
end Devcert.Commands.Doctor;
