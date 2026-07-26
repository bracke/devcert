package Devcert_State is
   function Base_Directory return String;
   function CA_Directory return String;
   function CA_Certificate_Path return String;
   function CA_Private_Key_Path return String;
   function CA_Metadata_Path return String;
   function Issued_Directory return String;
   function Leaf_Certificate_Path (Name : String) return String;
   function Leaf_Private_Key_Path (Name : String) return String;
   function PKCS12_Path (Name : String) return String;
end Devcert_State;
