--  Helpers every area of the suite needs: a disposable CA root, and whether
--  this host's system store is one the suite may mutate.
package Devcert_Test_Suite.Support is

   --  Point DEVCERT_CAROOT at a scratch directory of this name and clear it.
   procedure Reset_Temp_Home (Name : String);

   --  Only the Linux system store can be aimed at a directory of the suite's
   --  own, through DEVCERT_LINUX_TRUST_DIR. Everywhere else "system" means the
   --  host's real keychain or certificate store, which a test must not touch.
   function System_Store_Is_Isolated return Boolean;

end Devcert_Test_Suite.Support;
