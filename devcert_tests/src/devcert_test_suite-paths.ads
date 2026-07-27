package Devcert_Test_Suite.Paths is
   --  Repository paths derived from the location of the test executable, so
   --  the suite behaves identically from every working directory.

   --  Absolute path of the repository root.
   function Repository_Root return String;

   --  Absolute path of Relative, interpreted from the repository root.
   function In_Repository (Relative : String) return String;

   --  Absolute path of the devcert executable exercised by the suite.
   function Devcert_Executable return String;

   --  Path of Name inside the host's scratch directory. Tests write only here,
   --  never into the user's real CA root, and never into a literal "/tmp" --
   --  which Windows does not have.
   function Scratch (Name : String) return String;
end Devcert_Test_Suite.Paths;
