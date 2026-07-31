package Devcert.Locale is
   --  @return The locale in force, from --locale, DEVCERT_LOCALE, or the
   --          host's own setting, in that order.
   function Current return String;
end Devcert.Locale;
