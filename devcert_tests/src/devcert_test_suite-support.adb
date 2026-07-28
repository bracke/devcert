with Ada.Directories;
with Ada.Environment_Variables;

with Devcert_Secure_Files;
with Devcert_Trust_Stores;

with Devcert_Test_Suite.Paths;

package body Devcert_Test_Suite.Support is
   use type Devcert_Trust_Stores.Trust_Target;
   use type GNAT.OS_Lib.String_Access;

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

   function Openssl_Path return String is
      Found : GNAT.OS_Lib.String_Access :=
        GNAT.OS_Lib.Locate_Exec_On_Path ("openssl");
   begin
      if Found = null then
         return "";
      end if;
      declare
         Result : constant String := Found.all;
      begin
         GNAT.OS_Lib.Free (Found);
         return Result;
      end;
   end Openssl_Path;

   function Has_Openssl return Boolean is
   begin
      return Openssl_Path /= "";
   end Has_Openssl;

   function Sink return String is
     (Paths.Scratch ("devcert-aunit-openssl.out"));

   function Run (Arguments : GNAT.OS_Lib.Argument_List; Code : out Integer)
     return String
   is
      Program : constant String := Openssl_Path;
      Spawned : Boolean := False;
   begin
      Code := -1;
      if Program = "" then
         return "";
      end if;
      if Ada.Directories.Exists (Sink) then
         Ada.Directories.Delete_File (Sink);
      end if;
      GNAT.OS_Lib.Spawn
        (Program, Arguments, Sink, Spawned, Code, Err_To_Out => True);
      if not Spawned then
         Code := -1;
      end if;

      declare
         Text : constant String :=
           (if Ada.Directories.Exists (Sink)
            then Devcert_Secure_Files.Read (Sink) else "");
      begin
         if Ada.Directories.Exists (Sink) then
            Ada.Directories.Delete_File (Sink);
         end if;
         return Text;
      end;
   end Run;

   function Openssl_Succeeds (Arguments : GNAT.OS_Lib.Argument_List) return Boolean is
      Code    : Integer;
      Ignored : constant String := Run (Arguments, Code);
   begin
      pragma Unreferenced (Ignored);
      return Code = 0;
   end Openssl_Succeeds;

   function Openssl_Output (Arguments : GNAT.OS_Lib.Argument_List) return String is
      Code : Integer;
   begin
      return Run (Arguments, Code);
   end Openssl_Output;

end Devcert_Test_Suite.Support;
