with Truststores;

package body Devcert.Trust_Setup is

   procedure Apply is
   begin
      Truststores.Configure
        (Linux_Directory_Variable => "DEVCERT_LINUX_TRUST_DIR",
         NSS_Database_Variable    => "DEVCERT_NSS_DB",
         Java_Keystore_Variable   => "DEVCERT_JAVA_KEYSTORE");
   end Apply;

end Devcert.Trust_Setup;
