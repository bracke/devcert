with AUnit.Simple_Test_Cases;

package Devcert_Test_Suite.Core_Tests is
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

   type Fingerprint_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Fingerprint_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Fingerprint_Test);

   type State_Path_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : State_Path_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out State_Path_Test);

   type Clock_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Clock_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Clock_Test);

   type CA_Lifecycle_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : CA_Lifecycle_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out CA_Lifecycle_Test);

   type CA_Invalid_Material_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : CA_Invalid_Material_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out CA_Invalid_Material_Test);

   type Secure_File_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Secure_File_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Secure_File_Test);

   type Security_Output_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Security_Output_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Security_Output_Test);

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

   type Trust_Target_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Trust_Target_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Target_Test);

   type Trust_Selection_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Trust_Selection_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Selection_Test);

   type Trust_Plan_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Trust_Plan_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Plan_Test);

   type Trust_Aggregate_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Trust_Aggregate_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Aggregate_Test);

   type Trust_Linux_Mutation_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Trust_Linux_Mutation_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Linux_Mutation_Test);
end Devcert_Test_Suite.Core_Tests;
