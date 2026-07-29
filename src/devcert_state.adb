with Ada.Environment_Variables;

with Hostkit.Fs;

package body Devcert_State is
   --  Asked of the host rather than of the environment: HOME and USERPROFILE
   --  are conventions a process can be started without, and the CA root goes
   --  here. "." was the old answer when neither was set, which put a private
   --  key in whatever directory the caller happened to be in.
   function Home return String is
      Own : constant String := Hostkit.Fs.Home_Directory;
   begin
      return (if Own = "" then "." else Own);
   end Home;

   function Base_Directory return String is
   begin
      if Ada.Environment_Variables.Exists ("DEVCERT_CAROOT") then
         return Ada.Environment_Variables.Value ("DEVCERT_CAROOT");
      elsif Ada.Environment_Variables.Exists ("DEVCERT_HOME") then
         return Ada.Environment_Variables.Value ("DEVCERT_HOME");
      else
         return Home & "/.local/share/devcert";
      end if;
   end Base_Directory;

   function CA_Directory return String is
   begin
      return Base_Directory;
   end CA_Directory;

   function CA_Certificate_Path return String is
   begin
      return CA_Directory & "/rootCA.pem";
   end CA_Certificate_Path;

   function CA_Private_Key_Path return String is
   begin
      return CA_Directory & "/rootCA-key.pem";
   end CA_Private_Key_Path;

   function CA_Metadata_Path return String is
   begin
      return CA_Directory & "/ca-metadata.txt";
   end CA_Metadata_Path;

   function Issued_Directory return String is
   begin
      return Base_Directory & "/issued";
   end Issued_Directory;

   function Leaf_Certificate_Path (Name : String) return String is
   begin
      return Issued_Directory & "/" & Name & ".pem";
   end Leaf_Certificate_Path;

   function Leaf_Private_Key_Path (Name : String) return String is
   begin
      return Issued_Directory & "/" & Name & "-key.pem";
   end Leaf_Private_Key_Path;

   function PKCS12_Path (Name : String) return String is
   begin
      return Issued_Directory & "/" & Name & ".p12";
   end PKCS12_Path;
end Devcert_State;
