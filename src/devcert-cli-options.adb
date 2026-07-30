package body Devcert.CLI.Options is

   --  Written out rather than built from an array of accesses, which needs the
   --  constants aliased for no gain. The release tooling counts the constants
   --  declared in the specification and checks that Count agrees, so a name
   --  added there and forgotten here does not pass quietly.
   function Count return Natural is (19);

   function Name (Index : Positive) return String is
   begin
      return
        (case Index is
            when 1  => Help,
            when 2  => Version,
            when 3  => JSON,
            when 4  => Plain,
            when 5  => Color,
            when 6  => Locale,
            when 7  => Catalog,
            when 8  => CA_Root,
            when 9  => Trust_Store,
            when 10 => Server,
            when 11 => Client,
            when 12 => Email,
            when 13 => CSR,
            when 14 => Cert_File,
            when 15 => Key_File,
            when 16 => PKCS12,
            when 17 => P12_File,
            when 18 => P12_Password_File,
            when 19 => P12_Password_Stdin,
            when others => "");
   end Name;

end Devcert.CLI.Options;
