with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Text;

--  The release gate: what has to hold before devcert is fit to publish.
--
--  It runs the build and the suite itself, states the documentation it will not
--  release without, and then hands the devcert-specific checks -- style,
--  manifests, the message catalog, the parity matrix, generated artifacts -- to
--  devcert_tools, which is where they live because they are about devcert
--  rather than about releasing.
procedure Check_Devcert is
   use Ada.Text_IO;

   Build_Command : constant String := "alr --non-interactive build";
   Tests_Command : constant String := "./bin/devcert_tests";
   Tools_Command : constant String :=
     "./devcert_tools/bin/devcert_tools release-check";
   GNAT_Command  : constant String := "alr exec -- gnatls --version";

   function Root_Directory return String is
      Current : constant String := Ada.Directories.Current_Directory;
   begin
      if Ada.Directories.Exists (Current & "/devcert.gpr") then
         return Current;
      elsif Ada.Directories.Exists (Current & "/../devcert.gpr") then
         return Ada.Directories.Full_Name (Current & "/..");
      else
         Put_Line (Standard_Error, "devcert root not found from " & Current);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
   end Root_Directory;

   Root   : constant String := Root_Directory;
   Errors : Natural := 0;

   procedure Error (Message : String) is
   begin
      Errors := Errors + 1;
      Put_Line (Standard_Error, "error: " & Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Error;

   procedure Run_Command
     (Label     : String;
      Directory : String;
      Command   : String)
   is
      Status : Integer;
   begin
      Put_Line ("");
      Put_Line ("==> " & Label);
      Status :=
        Project_Tools.Processes.Run_Shell_In_Directory (Directory, Command);
      if Status /= 0 then
         Error (Label & " failed with status" & Integer'Image (Status));
      end if;
   end Run_Command;

   --  The toolchain is pinned in every manifest; this catches a host that
   --  resolved a different one anyway, which shows up as a puzzling build
   --  error much later.
   procedure Require_Alire_GNAT_15 is
      Output : constant String :=
        Project_Tools.Processes.Shell_Output
          ("cd " & Project_Tools.Processes.Shell_Quote (Root)
           & " && " & GNAT_Command);
   begin
      Put_Line ("");
      Put_Line ("==> verify Alire-selected GNAT 15 toolchain");
      if Output = "" then
         Error ("alr exec -- gnatls --version failed");
      elsif not Project_Tools.Text.Contains (Output, "GNATLS 15.") then
         Error ("devcert must build with Alire-selected GNAT 15, got: " & Output);
      end if;
   end Require_Alire_GNAT_15;

   procedure Require_Text
     (Relative_Path : String;
      Pattern       : String;
      Message       : String) is
   begin
      Project_Tools.Files.Require_Contains
        (Root & "/" & Relative_Path, Pattern, Message);
   exception
      when others =>
         Error (Message);
   end Require_Text;
begin
   Require_Alire_GNAT_15;

   Put_Line ("");
   Put_Line ("==> documentation a release depends on");

   --  Each of these is something a reader has to be able to find. They are
   --  here rather than in the tooling because they are the terms of a release,
   --  not properties of the source.
   Require_Text
     ("README.md", "bin/devcert cert localhost",
      "README must show the worked example, not only the command names");
   Require_Text
     ("docs/installation.md", "share/devcert",
      "installation must say the data files travel with the executable");
   Require_Text
     ("docs/cli.md", "Diagnosing Failures",
      "the CLI reference must tell a caller what a failure means");
   Require_Text
     ("docs/security.md", "never installed into",
      "the security model must state that the CA key stays out of trust stores");
   Require_Text
     ("docs/platform_evidence.md", "Not validated",
      "the evidence file must say which platforms have not been validated");
   Require_Text
     ("docs/cryptolib_contract.md", "must not contain duplicate",
      "the cryptolib contract must state the boundary devcert keeps");

   Run_Command ("build devcert", Root, Build_Command);
   Run_Command ("build the test suite", Root & "/devcert_tests", Build_Command);
   Run_Command ("run the test suite", Root & "/devcert_tests", Tests_Command);
   Run_Command ("build the tooling", Root & "/devcert_tools", Build_Command);
   Run_Command ("devcert-specific checks", Root, Tools_Command);

   if Errors = 0 then
      Put_Line ("");
      Put_Line ("devcert release check passed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line
        (Standard_Error,
         "devcert release check failed:" & Natural'Image (Errors) & " error(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
exception
   when Program_Error =>
      null;
end Check_Devcert;
