with Devcert_State;

package Devcert.CA_Store is
   type CA_State is
     (Missing,
      Complete,
      Incomplete,
      Unsafe_Permissions,
      Invalid_Metadata,
      Invalid_Certificate,
      Invalid_Private_Key,
      Certificate_Key_Mismatch,
      Unsupported_Format);

   function Root return String renames Devcert_State.Base_Directory;
   function Certificate_Path return String renames Devcert_State.CA_Certificate_Path;
   function Private_Key_Path return String renames Devcert_State.CA_Private_Key_Path;
   function Metadata_Path return String renames Devcert_State.CA_Metadata_Path;

   function State_Image (State : CA_State) return String;
   function Evaluate return CA_State;
   function Ensure return CA_State;
end Devcert.CA_Store;
