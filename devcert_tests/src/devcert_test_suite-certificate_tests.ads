with AUnit;
with AUnit.Simple_Test_Cases;

--  Tests for certificate policy, requests and issuance.
package Devcert_Test_Suite.Certificate_Tests is

   type Certificate_Boundary_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Boundary_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Boundary_Test);

   type Identity_Validation_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Identity_Validation_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Identity_Validation_Test);

   type Certificate_Request_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Request_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Request_Test);

   type Certificate_Request_Limit_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Request_Limit_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Request_Limit_Test);

   type Certificate_Profile_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Profile_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Profile_Test);

   type Certificate_File_Workflow_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_File_Workflow_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_File_Workflow_Test);

   type Certificate_Custom_PKCS12_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Certificate_Custom_PKCS12_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Certificate_Custom_PKCS12_Test);

end Devcert_Test_Suite.Certificate_Tests;
