package Devcert.Identities is
   type Identity_Kind is (DNS, IPv4, IPv6, Email);

   --  @param Value Identity as the user typed it.
   --  @return It in the form devcert compares and stores, so that two
   --          spellings of one name do not become two identities.
   function Normalize (Value : String) return String;
   --  @param Value Identity to classify.
   --  @param Kind What it turned out to be, when it is valid.
   --  @return True when Value is a valid identity of some kind.
   function Classify (Value : String; Kind : out Identity_Kind) return Boolean;

   --  @param Value Candidate name.
   --  @return True when it is a valid DNS name.
   function Is_Valid_DNS (Value : String) return Boolean;
   --  @param Value Candidate address.
   --  @return True when it is a valid IPv4 address.
   function Is_Valid_IPv4 (Value : String) return Boolean;
   --  @param Value Candidate address.
   --  @return True when it is a valid IPv6 address.
   function Is_Valid_IPv6 (Value : String) return Boolean;
   --  @param Value Candidate address.
   --  @return True when it is a valid email address.
   function Is_Valid_Email (Value : String) return Boolean;
end Devcert.Identities;
