package body Devcert_Core is
   function Version return String is
   begin
      return "0.1.0-dev";
   end Version;

   function Json_Schema_Version return String is
   begin
      return "1";
   end Json_Schema_Version;
end Devcert_Core;
