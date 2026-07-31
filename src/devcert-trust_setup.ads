--  Tell the trust-store crate which environment variables devcert documents.
--
--  A library does not read its caller's environment: DEVCERT_LINUX_TRUST_DIR,
--  DEVCERT_NSS_DB and DEVCERT_JAVA_KEYSTORE are devcert's contract with its
--  users, so devcert is what names them. They are read whenever a store is
--  looked at, not captured here, which is what lets a test set one and be
--  heard.
package Devcert.Trust_Setup is

   --  Call once, before any trust store is looked at.
   --  Tell the trust-store library which environment variables devcert
   --  documents, so that a library which does not read its caller's
   --  environment can still honour them. Called once at startup.
   procedure Apply;

end Devcert.Trust_Setup;
