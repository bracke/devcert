with Ada.Environment_Variables;

package body Devcert_State is
   function Home return String is
   begin
      if Ada.Environment_Variables.Exists ("HOME") then
         return Ada.Environment_Variables.Value ("HOME");
      elsif Ada.Environment_Variables.Exists ("USERPROFILE") then
         return Ada.Environment_Variables.Value ("USERPROFILE");
      else
         return ".";
      end if;
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
