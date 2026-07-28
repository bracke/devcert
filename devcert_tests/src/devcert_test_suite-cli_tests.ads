with AUnit;
with AUnit.Simple_Test_Cases;

--  Tests for CLI and dispatch.
package Devcert_Test_Suite.Cli_Tests is

   type Version_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Version_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Version_Test);

   type Json_Schema_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Schema_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Schema_Test);

   type Exit_Code_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Exit_Code_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Exit_Code_Test);

   type Architecture_Surface_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Architecture_Surface_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Architecture_Surface_Test);

   type CLI_Contract_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : CLI_Contract_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out CLI_Contract_Test);

   type Output_Mode_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Output_Mode_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Output_Mode_Test);

   type Integration_Workflow_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Integration_Workflow_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Integration_Workflow_Test);

end Devcert_Test_Suite.Cli_Tests;
