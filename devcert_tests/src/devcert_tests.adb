with Ada.Command_Line;
with Ada.Environment_Variables;

with AUnit;
with AUnit.Reporter.Text;
with AUnit.Run;

with Devcert_Test_Suite;
with Devcert_Test_Suite.Paths;

procedure Devcert_Tests is
   use type AUnit.Status;

   function Run is new AUnit.Run.Test_Runner_With_Status
     (Devcert_Test_Suite.Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
begin
   --  The suite executable does not sit next to the bundled catalog, so point
   --  in-process message rendering at the repository copy. Tests that cover
   --  catalog resolution set their own value and leave it cleared, which keeps
   --  spawned devcert processes on the runtime's own discovery order.
   Ada.Environment_Variables.Set
     ("DEVCERT_CATALOG",
      Devcert_Test_Suite.Paths.In_Repository ("share/devcert/messages.catalog"));

   Status := Run (Reporter);
   if Status = AUnit.Failure then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Devcert_Tests;
