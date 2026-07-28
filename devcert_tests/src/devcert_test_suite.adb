with Devcert_Test_Suite.Cli_Tests;
with Devcert_Test_Suite.Output_Tests;
with Devcert_Test_Suite.Ca_Tests;
with Devcert_Test_Suite.Certificate_Tests;
with Devcert_Test_Suite.Trust_Tests;

package body Devcert_Test_Suite is
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      pragma Warnings (Off, "use of an anonymous access type allocator");
      Result.Add_Test (new Cli_Tests.Version_Test);
      Result.Add_Test (new Cli_Tests.Json_Schema_Test);
      Result.Add_Test (new Cli_Tests.Exit_Code_Test);
      Result.Add_Test (new Cli_Tests.Architecture_Surface_Test);
      Result.Add_Test (new Cli_Tests.CLI_Contract_Test);
      Result.Add_Test (new Cli_Tests.Output_Mode_Test);
      Result.Add_Test (new Cli_Tests.Integration_Workflow_Test);

      Result.Add_Test (new Output_Tests.Json_Escape_Test);
      Result.Add_Test (new Output_Tests.Json_Control_Escape_Test);
      Result.Add_Test (new Output_Tests.Json_Envelope_Test);
      Result.Add_Test (new Output_Tests.Localization_Message_Test);
      Result.Add_Test (new Output_Tests.Security_Output_Test);

      Result.Add_Test (new Ca_Tests.Fingerprint_Test);
      Result.Add_Test (new Ca_Tests.State_Path_Test);
      Result.Add_Test (new Ca_Tests.Clock_Test);
      Result.Add_Test (new Ca_Tests.Lock_Test);
      Result.Add_Test (new Ca_Tests.CA_Lifecycle_Test);
      Result.Add_Test (new Ca_Tests.CA_Invalid_Material_Test);
      Result.Add_Test (new Ca_Tests.Secure_File_Test);

      Result.Add_Test (new Certificate_Tests.Certificate_Boundary_Test);
      Result.Add_Test (new Certificate_Tests.Identity_Validation_Test);
      Result.Add_Test (new Certificate_Tests.Certificate_Request_Test);
      Result.Add_Test (new Certificate_Tests.Certificate_Request_Limit_Test);
      Result.Add_Test (new Certificate_Tests.Certificate_Profile_Test);
      Result.Add_Test (new Certificate_Tests.Certificate_File_Workflow_Test);
      Result.Add_Test (new Certificate_Tests.Certificate_Custom_PKCS12_Test);
      Result.Add_Test (new Certificate_Tests.Chain_Verification_Test);

      Result.Add_Test (new Trust_Tests.Trust_Target_Test);
      Result.Add_Test (new Trust_Tests.NSS_Discovery_Test);
      Result.Add_Test (new Trust_Tests.Trust_Selection_Test);
      Result.Add_Test (new Trust_Tests.Trust_Plan_Test);
      Result.Add_Test (new Trust_Tests.Trust_Aggregate_Test);
      Result.Add_Test (new Trust_Tests.Trust_Linux_Mutation_Test);
      pragma Warnings (On, "use of an anonymous access type allocator");
      return Result;
   end Suite;
end Devcert_Test_Suite;
