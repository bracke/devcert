package Devcert_State is

   --  Where devcert keeps what it owns. Every path is derived here rather than
   --  composed by each caller, so the CA root can be redirected -- by
   --  DEVCERT_CAROOT, by --ca-root, or by a test wanting a disposable one --
   --  in one place.

   --  @return The CA root directory.
   function Base_Directory return String;

   --  @return The directory holding the CA's own files.
   function CA_Directory return String;

   --  @return Path to the CA certificate.
   function CA_Certificate_Path return String;

   --  @return Path to the CA private key, which is never installed anywhere.
   function CA_Private_Key_Path return String;

   --  @return Path to the CA metadata file.
   function CA_Metadata_Path return String;

   --  @return The directory issued certificates are written to.
   function Issued_Directory return String;

   --  @param Name Subject name the certificate was issued for.
   --  @return Path to that certificate.
   function Leaf_Certificate_Path (Name : String) return String;

   --  @param Name Subject name the certificate was issued for.
   --  @return Path to its private key.
   function Leaf_Private_Key_Path (Name : String) return String;

   --  @param Name Subject name the bundle was issued for.
   --  @return Path to the PKCS#12 bundle.
   function PKCS12_Path (Name : String) return String;

end Devcert_State;
