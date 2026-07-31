package Devcert_Messages is
   --  @param Id Message key in the catalogue.
   --  @return The message in the current locale, or the key itself when the
   --          catalogue does not carry it -- a missing message shows as its
   --          name rather than as nothing.
   function Text (Id : String) return String;
   --  @param Id Message key in the catalogue.
   --  @param Value Text substituted into the message's argument.
   --  @return The rendered message.
   function Text
     (Id    : String;
      Value : String) return String;
end Devcert_Messages;
