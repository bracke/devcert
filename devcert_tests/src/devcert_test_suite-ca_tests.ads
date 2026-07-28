with AUnit;
with AUnit.Simple_Test_Cases;

--  Tests for CA lifecycle, state and filesystem safety.
package Devcert_Test_Suite.Ca_Tests is

   type Fingerprint_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Fingerprint_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Fingerprint_Test);

   type State_Path_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : State_Path_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out State_Path_Test);

   type Clock_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Clock_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Clock_Test);

   type Lock_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Lock_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Lock_Test);

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

end Devcert_Test_Suite.Ca_Tests;
