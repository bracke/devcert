package Devcert.Identities is
   type Identity_Kind is (DNS, IPv4, IPv6, Email);

   function Normalize (Value : String) return String;
   function Classify (Value : String; Kind : out Identity_Kind) return Boolean;

   function Is_Valid_DNS (Value : String) return Boolean;
   function Is_Valid_IPv4 (Value : String) return Boolean;
   function Is_Valid_IPv6 (Value : String) return Boolean;
   function Is_Valid_Email (Value : String) return Boolean;
end Devcert.Identities;
