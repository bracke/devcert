package Devcert_Test_Suite.Paths is
   --  Repository paths derived from the location of the test executable, so
   --  the suite behaves identically from every working directory.

   --  Absolute path of the repository root.
   function Repository_Root return String;

   --  Absolute path of Relative, interpreted from the repository root.
   function In_Repository (Relative : String) return String;

   --  Absolute path of the devcert executable exercised by the suite.
   function Devcert_Executable return String;
end Devcert_Test_Suite.Paths;
