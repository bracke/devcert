with Devcert_Test_Suite.Core_Tests;

package body Devcert_Test_Suite is
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      pragma Warnings (Off, "use of an anonymous access type allocator");
      Result.Add_Test (new Core_Tests.Version_Test);
      Result.Add_Test (new Core_Tests.Json_Schema_Test);
      Result.Add_Test (new Core_Tests.Json_Escape_Test);
      Result.Add_Test (new Core_Tests.Json_Envelope_Test);
      Result.Add_Test (new Core_Tests.Fingerprint_Test);
      Result.Add_Test (new Core_Tests.State_Path_Test);
      Result.Add_Test (new Core_Tests.Secure_File_Test);
      Result.Add_Test (new Core_Tests.Certificate_Boundary_Test);
      Result.Add_Test (new Core_Tests.Certificate_File_Workflow_Test);
      Result.Add_Test (new Core_Tests.Trust_Target_Test);
      Result.Add_Test (new Core_Tests.Trust_Plan_Test);
      pragma Warnings (On, "use of an anonymous access type allocator");
      return Result;
   end Suite;
end Devcert_Test_Suite;
