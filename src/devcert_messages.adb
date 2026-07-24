with Ada.Strings.Fixed;

package body Devcert_Messages is
   function Text (Id : String) return String is
   begin
      if Id = "app.name" then
         return "devcert";
      elsif Id = "cli.usage" then
         return "usage: devcert [--help] [--version] [--json] <command>";
      elsif Id = "error.unknown_command" then
         return "unknown command";
      elsif Id = "json.schema" then
         return "1";
      elsif Id = "release.passed" then
         return "release-check passed";
      elsif Ada.Strings.Fixed.Index (Id, ".") /= 0 then
         return Id;
      else
         return "message." & Id;
      end if;
   end Text;
end Devcert_Messages;
