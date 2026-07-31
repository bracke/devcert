package Devcert_Core is
   --  @return devcert's version, as reported by --version.
   function Version return String;
   --  @return The version of the JSON output's shape, which changes only when
   --          that shape does -- a consumer pins to it, not to the program's
   --          version.
   function Json_Schema_Version return String;
end Devcert_Core;
