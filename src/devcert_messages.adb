with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

with Hostkit.Fs;

with Messages.Arguments;
with Messages.Result;
with Messages.Runtime;

package body Devcert_Messages is
   --  Message text is rendered through the messages crate against a catalog, so
   --  it can be localized. Standard.Messages disambiguates the top-level crate
   --  from any locally named Messages.
   Runtime     : Standard.Messages.Runtime.Instance;
   Locale      : Unbounded_String := To_Unbounded_String ("en");
   Initialized : Boolean := False;

   --  Directory holding the running executable, or "" when it cannot be
   --  determined. A bare program name is resolved through PATH so an installed
   --  devcert still locates the files shipped beside it.
   --  Where this executable is, asked of the host.
   --
   --  This used to take the directory part of argv[0], and search PATH when
   --  there was none. Neither is the question: argv[0] is what the caller
   --  typed, so a relative one stops meaning anything the moment anything
   --  changes directory, and a PATH search finds the first devcert on the path
   --  rather than the one that is running. Both answers send the catalog
   --  lookup somewhere else -- and a devcert that cannot find its catalog
   --  prints message identifiers instead of messages.
   function Executable_Directory return String is
   begin
      return Hostkit.Fs.Own_Executable_Directory;
   end Executable_Directory;

   --  The catalog ships in share/devcert. An installed devcert finds it next
   --  to its own executable (Exe/../share/devcert, matching how the i18n data
   --  is bundled); the working-directory entries keep the build tree working.
   function Catalog_Path return String is
      Leaf : constant String := "share/devcert/messages.catalog";
      Exe  : constant String := Executable_Directory;
   begin
      if Ada.Environment_Variables.Exists ("DEVCERT_CATALOG") then
         return Ada.Environment_Variables.Value ("DEVCERT_CATALOG");
      end if;

      if Exe /= "" then
         if Ada.Directories.Exists (Exe & "/../" & Leaf) then
            return Exe & "/../" & Leaf;
         elsif Ada.Directories.Exists (Exe & "/" & Leaf) then
            return Exe & "/" & Leaf;
         end if;
      end if;

      if Ada.Directories.Exists (Leaf) then
         return Leaf;
      elsif Ada.Directories.Exists ("../" & Leaf) then
         return "../" & Leaf;
      else
         return Leaf;
      end if;
   end Catalog_Path;

   --  The system locale's language part (LC_ALL, then LC_MESSAGES, then LANG),
   --  or "en" for an empty, C, or POSIX value.
   function Detected_Locale return String is
      function Env (Name : String) return String is
        (if Ada.Environment_Variables.Exists (Name)
         then Ada.Environment_Variables.Value (Name)
         else "");

      Raw  : constant String :=
        (if Env ("DEVCERT_LOCALE") /= "" then Env ("DEVCERT_LOCALE")
         elsif Env ("LC_ALL") /= "" then Env ("LC_ALL")
         elsif Env ("LC_MESSAGES") /= "" then Env ("LC_MESSAGES")
         else Env ("LANG"));
      Last : Natural := Raw'First - 1;
   begin
      for Index in Raw'Range loop
         exit when Raw (Index) in '.' | '@' | '_';
         Last := Index;
      end loop;

      if Last < Raw'First then
         return "en";
      end if;

      declare
         Language : constant String := Raw (Raw'First .. Last);
      begin
         if Language = "C" or else Language = "POSIX" then
            return "en";
         end if;
         return Language;
      end;
   end Detected_Locale;

   procedure Ensure_Initialized is
   begin
      if not Initialized then
         Standard.Messages.Runtime.Initialize (Runtime, Catalog_Path);
         Locale := To_Unbounded_String (Detected_Locale);
         Initialized := True;
      end if;
   end Ensure_Initialized;

   function Text (Id : String) return String is
      use type Standard.Messages.Result.Render_Status;
      Args : Standard.Messages.Arguments.Arguments;
   begin
      Ensure_Initialized;

      declare
         Result : constant Standard.Messages.Result.Render_Result :=
           Standard.Messages.Runtime.Render
             (Item      => Runtime,
              Locale    => To_String (Locale),
              Key       => Id,
              Arguments => Args);
      begin
         if Result.Status = Standard.Messages.Result.Success then
            return Standard.Messages.Result.Output_Text (Result.Text);
         end if;
      end;

      --  Fallback for ids absent from the catalog, preserving prior behavior.
      if Ada.Strings.Fixed.Index (Id, ".") /= 0 then
         return Id;
      else
         return "message." & Id;
      end if;
   end Text;

   function Text
     (Id    : String;
      Value : String) return String
   is
      use type Standard.Messages.Result.Render_Status;
      Args : Standard.Messages.Arguments.Arguments;
   begin
      Ensure_Initialized;
      Standard.Messages.Arguments.Set (Args, "value", Value);

      declare
         Result : constant Standard.Messages.Result.Render_Result :=
           Standard.Messages.Runtime.Render
             (Item      => Runtime,
              Locale    => To_String (Locale),
              Key       => Id,
              Arguments => Args);
      begin
         if Result.Status = Standard.Messages.Result.Success then
            return Standard.Messages.Result.Output_Text (Result.Text);
         end if;
      end;

      declare
         Template : constant String := Text (Id);
         Marker   : constant String := "{value}";
         Start    : constant Natural := Ada.Strings.Fixed.Index (Template, Marker);
      begin
         if Start = 0 then
            return Template & Value;
         else
            return Template (Template'First .. Start - 1)
              & Value
              & Template (Start + Marker'Length .. Template'Last);
         end if;
      end;
   end Text;

end Devcert_Messages;
