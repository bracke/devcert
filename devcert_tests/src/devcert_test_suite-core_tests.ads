with AUnit.Simple_Test_Cases;

package Devcert_Test_Suite.Core_Tests is
   type Version_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Version_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Version_Test);

   type Json_Schema_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Schema_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Schema_Test);

   type Json_Escape_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Escape_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Escape_Test);

   type Json_Envelope_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Json_Envelope_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Json_Envelope_Test);

   type Fingerprint_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Fingerprint_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Fingerprint_Test);

   type State_Path_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : State_Path_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out State_Path_Test);

   type Secure_File_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Secure_File_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Secure_File_Test);

   type Certificate_Boundary_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Boundary_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Boundary_Test);

   type Certificate_File_Workflow_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_File_Workflow_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_File_Workflow_Test);

   type Trust_Target_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Trust_Target_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Target_Test);

   type Trust_Plan_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Trust_Plan_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Plan_Test);
end Devcert_Test_Suite.Core_Tests;
