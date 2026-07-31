--  The option names, once.
--
--  They were string literals spread through the parser's if-chain, which is a
--  list only the compiler can see. Anything that had to say which options
--  exist -- docs/cli.md, the usage text, a release check -- wrote them out
--  again, and the copies drifted: --trust-store was accepted and missing from
--  the list in the document.
--
--  Declared rather than computed so the release tooling can read this file as
--  text without depending on the program: one constant per line, and Count and
--  Name agree with them because they are written from them.
package Devcert.CLI.Options is

   Help                : constant String := "--help";
   Version             : constant String := "--version";
   JSON                : constant String := "--json";
   Plain               : constant String := "--plain";
   Locale              : constant String := "--locale";
   Catalog             : constant String := "--catalog";
   CA_Root             : constant String := "--ca-root";
   Trust_Store         : constant String := "--trust-store";
   Server              : constant String := "--server";
   Client              : constant String := "--client";
   Email               : constant String := "--email";
   CSR                 : constant String := "--csr";
   Cert_File           : constant String := "--cert-file";
   Key_File            : constant String := "--key-file";
   PKCS12              : constant String := "--pkcs12";
   P12_File            : constant String := "--p12-file";
   P12_Password_File   : constant String := "--p12-password-file";
   P12_Password_Stdin  : constant String := "--p12-password-stdin";

   --  Written "--color=VALUE", so the parser matches the prefix rather than
   --  the whole argument. The name is what a reader types and what a document
   --  has to carry; the "=" is the parser's business.
   Color               : constant String := "--color";
   Color_Prefix        : constant String := Color & "=";

   --  Every option above, for a caller that has to list them: usage text, or a
   --  check that the documentation still names them all.
   --  @return How many option names there are.
   function Count return Natural;

   --  @param Index in 1 .. Count; "" outside that.
   --  @return The option name at that position.
   function Name (Index : Positive) return String;

end Devcert.CLI.Options;
