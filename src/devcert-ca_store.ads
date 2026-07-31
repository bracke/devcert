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

   --  The CA's paths, named here as well as in Devcert_State so that code
   --  about the CA reads as being about the CA.
   --  @return The CA root directory.
   function Root return String renames Devcert_State.Base_Directory;
   --  @return Path to the CA certificate.
   function Certificate_Path return String renames Devcert_State.CA_Certificate_Path;
   --  @return Path to the CA private key.
   function Private_Key_Path return String renames Devcert_State.CA_Private_Key_Path;
   --  @return Path to the CA metadata file.
   function Metadata_Path return String renames Devcert_State.CA_Metadata_Path;

   --  @param State State to render.
   --  @return Its name, as devcert reports it.
   function State_Image (State : CA_State) return String;
   --  Look at what is on disk and say what state the CA is in, changing
   --  nothing.
   --  @return The CA's state. Unsafe_Permissions is a state of its own: the
   --          files are there and readable by someone who should not.
   function Evaluate return CA_State;
   --  Evaluate, and create the CA when it is Missing.
   --  @return The state afterwards; anything but Complete means the CA cannot
   --          be used and says why.
   function Ensure return CA_State;
end Devcert.CA_Store;
