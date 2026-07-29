with Ada.Environment_Variables;

with Hostkit.Host;

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
      end if;

      --  Windows sets none of those: the language a user chose lives in the
      --  system, not in the environment, and asking only for LANG there means
      --  every Windows user reads English whatever they picked. Hostkit answers
      --  where the host has an answer and empty where the convention above is
      --  the whole story.
      declare
         Native : constant String := Hostkit.Host.Native_Locale;
      begin
         return (if Native = "" then "en" else Native);
      end;
   end Current;
end Devcert.Locale;
