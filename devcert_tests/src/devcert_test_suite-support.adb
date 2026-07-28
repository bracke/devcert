with Ada.Directories;
with Ada.Environment_Variables;

with Devcert_Trust_Stores;

with Devcert_Test_Suite.Paths;

package body Devcert_Test_Suite.Support is
   use type Devcert_Trust_Stores.Trust_Target;

   procedure Reset_Temp_Home (Name : String) is
      Path : constant String := Paths.Scratch ("devcert-aunit-") & Name;
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
      Ada.Environment_Variables.Set ("DEVCERT_HOME", Path & "-legacy");
      Ada.Environment_Variables.Set ("DEVCERT_CAROOT", Path);
   end Reset_Temp_Home;

   function System_Store_Is_Isolated return Boolean is
   begin
      return Devcert_Trust_Stores.Detect_Default_Target = Devcert_Trust_Stores.Linux;
   end System_Store_Is_Isolated;

end Devcert_Test_Suite.Support;
