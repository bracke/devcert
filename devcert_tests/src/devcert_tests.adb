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
   --  And pin the locale. The suite asserts on English text, and devcert now
   --  follows the host's: on a German desktop every one of those assertions
   --  would be comparing a translation with the English it was written against.
   --  A test says what it means to say, not what the machine happens to speak.
   Ada.Environment_Variables.Set ("DEVCERT_LOCALE", "en");

   Ada.Environment_Variables.Set
     ("DEVCERT_CATALOG",
      Devcert_Test_Suite.Paths.In_Repository ("share/devcert/messages.catalog"));

   Status := Run (Reporter);
   if Status = AUnit.Failure then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Devcert_Tests;
