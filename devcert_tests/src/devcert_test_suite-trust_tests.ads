with AUnit;
with AUnit.Simple_Test_Cases;

--  Tests for trust stores.
package Devcert_Test_Suite.Trust_Tests is

   type Trust_Target_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Trust_Target_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Target_Test);

   type NSS_Discovery_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : NSS_Discovery_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out NSS_Discovery_Test);

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

   type Trust_Denial_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Trust_Denial_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Denial_Test);

   type Trust_Linux_Mutation_Test is
     new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name
     (Item : Trust_Linux_Mutation_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Trust_Linux_Mutation_Test);

end Devcert_Test_Suite.Trust_Tests;
