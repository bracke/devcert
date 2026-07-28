with AUnit;
with AUnit.Simple_Test_Cases;

--  Tests for JSON, localization and terminal output.
package Devcert_Test_Suite.Output_Tests is

   type Json_Escape_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Escape_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Escape_Test);

   type Json_Control_Escape_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Json_Control_Escape_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Control_Escape_Test);

   type Json_Envelope_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Envelope_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Envelope_Test);

   type Localization_Message_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Localization_Message_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Localization_Message_Test);

   type Security_Output_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Security_Output_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Security_Output_Test);

end Devcert_Test_Suite.Output_Tests;
