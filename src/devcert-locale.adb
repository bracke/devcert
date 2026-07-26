with Ada.Environment_Variables;

package body Devcert.Locale is
   function Current return String is
   begin
      if Ada.Environment_Variables.Exists ("DEVCERT_LOCALE") then
         return Ada.Environment_Variables.Value ("DEVCERT_LOCALE");
      elsif Ada.Environment_Variables.Exists ("LC_ALL") then
         return Ada.Environment_Variables.Value ("LC_ALL");
      elsif Ada.Environment_Variables.Exists ("LC_MESSAGES") then
         return Ada.Environment_Variables.Value ("LC_MESSAGES");
      elsif Ada.Environment_Variables.Exists ("LANG") then
         return Ada.Environment_Variables.Value ("LANG");
      else
         return "en";
      end if;
   end Current;
end Devcert.Locale;
