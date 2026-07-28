with GNAT.OS_Lib;

--  Helpers every area of the suite needs: a disposable CA root, whether this
--  host's system store is one the suite may mutate, and a way to ask the tools
--  that have to consume devcert's output whether they can.
package Devcert_Test_Suite.Support is

   --  Point DEVCERT_CAROOT at a scratch directory of this name and clear it.
   procedure Reset_Temp_Home (Name : String);

   --  Only the Linux system store can be aimed at a directory of the suite's
   --  own, through DEVCERT_LINUX_TRUST_DIR. Everywhere else "system" means the
   --  host's real keychain or certificate store, which a test must not touch.
   function System_Store_Is_Isolated return Boolean;

   --  Has this host an openssl to answer with?
   --
   --  A certificate that exists and parses is not one that anything will
   --  accept, and the only way to know the difference is to ask a reader that
   --  was not written here.
   function Has_Openssl return Boolean;

   --  Run openssl with these arguments; True when it exits zero.
   function Openssl_Succeeds (Arguments : GNAT.OS_Lib.Argument_List) return Boolean;

   --  What openssl printed, for the cases where the answer is a value rather
   --  than a verdict.
   function Openssl_Output (Arguments : GNAT.OS_Lib.Argument_List) return String;

end Devcert_Test_Suite.Support;
