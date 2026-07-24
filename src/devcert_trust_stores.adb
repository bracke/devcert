with Ada.Environment_Variables;
with Ada.Directories;

with GNAT.OS_Lib;

package body Devcert_Trust_Stores is
   use type GNAT.OS_Lib.String_Access;

   function Name (Target : Trust_Target) return String is
   begin
      case Target is
         when Linux =>
            return "linux";
         when NSS =>
            return "nss";
         when Java =>
            return "java";
         when MacOS =>
            return "macos";
         when Windows =>
            return "windows";
      end case;
   end Name;

   function Target_From_Name (Value : String; Target : out Trust_Target) return Boolean is
   begin
      if Value = "linux" then
         Target := Linux;
      elsif Value = "nss" then
         Target := NSS;
      elsif Value = "java" then
         Target := Java;
      elsif Value = "macos" or else Value = "mac" then
         Target := MacOS;
      elsif Value = "windows" or else Value = "win" then
         Target := Windows;
      else
         return False;
      end if;
      return True;
   end Target_From_Name;

   function Detect_Default_Target return Trust_Target is
   begin
      if Ada.Environment_Variables.Exists ("OS")
        and then Ada.Environment_Variables.Value ("OS") = "Windows_NT"
      then
         return Windows;
      elsif Ada.Environment_Variables.Exists ("OSTYPE")
        and then Ada.Environment_Variables.Value ("OSTYPE") = "darwin"
      then
         return MacOS;
      else
         return Linux;
      end if;
   end Detect_Default_Target;

   function Plan
     (Target      : Trust_Target;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String) return String is
      Verb : constant String := (if Operation = Install then "install" else "remove");
   begin
      case Target is
         when Linux =>
            return Verb & " linux system trust for " & Fingerprint & " using "
              & Certificate;
         when NSS =>
            return Verb & " NSS profiles for " & Fingerprint & " using "
              & Certificate;
         when Java =>
            return Verb & " Java trust stores for " & Fingerprint & " using "
              & Certificate;
         when MacOS =>
            return Verb & " macOS keychain trust for " & Fingerprint & " using "
              & Certificate;
         when Windows =>
            return Verb & " Windows certificate store trust for " & Fingerprint
              & " using " & Certificate;
      end case;
   end Plan;

   function Safe_Fingerprint (Fingerprint : String) return String is
      Result : Unbounded_String;
   begin
      for C of Fingerprint loop
         if C in 'a' .. 'f' or else C in '0' .. '9' then
            Ada.Strings.Unbounded.Append (Result, C);
         end if;
      end loop;
      return Ada.Strings.Unbounded.To_String (Result);
   end Safe_Fingerprint;

   function Locate (Name : String) return String is
      Found : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Name);
   begin
      if Found = null then
         return "";
      else
         declare
            Result : constant String := Found.all;
         begin
            GNAT.OS_Lib.Free (Found);
            return Result;
         end;
      end if;
   end Locate;

   procedure Run
     (Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Success : out Boolean)
   is
      Return_Code : Integer := 1;
      Spawned     : Boolean := False;
      Output_File : constant String := "/tmp/devcert-trust-command.out";
   begin
      GNAT.OS_Lib.Spawn
        (Program,
         Args,
         Output_File,
         Spawned,
         Return_Code,
         Err_To_Out => True);
      if Ada.Directories.Exists (Output_File) then
         Ada.Directories.Delete_File (Output_File);
      end if;
      Success := Spawned and then Return_Code = 0;
   end Run;

   procedure Apply_Linux
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Update : constant String := Locate ("update-ca-certificates");
      Target : constant String :=
        "/usr/local/share/ca-certificates/devcert-"
        & Safe_Fingerprint (Fingerprint)
        & ".crt";
      Ran : Boolean := False;
   begin
      Success := False;
      Message := Ada.Strings.Unbounded.Null_Unbounded_String;

      if Update = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("update-ca-certificates is not installed");
         return;
      end if;

      case Operation is
         when Install =>
            Ada.Directories.Copy_File (Certificate, Target);
            Run (Update, [1 => new String'("--fresh")], Ran);
            Success := Ran;
            if Success then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("installed linux trust anchor " & Target);
            else
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("update-ca-certificates failed");
            end if;
         when Remove =>
            if Ada.Directories.Exists (Target) then
               Ada.Directories.Delete_File (Target);
            end if;
            Run (Update, [1 => new String'("--fresh")], Ran);
            Success := Ran;
            if Success then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("removed linux trust anchor " & Target);
            else
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("update-ca-certificates failed");
            end if;
      end case;
   exception
      when others =>
         Success := False;
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("linux trust store update requires permission for " & Target);
   end Apply_Linux;

   procedure Apply_Java
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Keytool : constant String := Locate ("keytool");
      Alias   : constant String := "devcert-" & Safe_Fingerprint (Fingerprint);
      Keystore : constant String :=
        (if Ada.Environment_Variables.Exists ("DEVCERT_JAVA_KEYSTORE")
         then Ada.Environment_Variables.Value ("DEVCERT_JAVA_KEYSTORE")
         else "");
      Ran     : Boolean := False;
   begin
      Success := False;
      if Keytool = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("keytool is not installed");
         return;
      end if;

      case Operation is
         when Install =>
            if Keystore = "" then
               Run
                 (Keytool,
                  [new String'("-importcert"),
                   new String'("-noprompt"),
                   new String'("-trustcacerts"),
                   new String'("-cacerts"),
                   new String'("-storepass"),
                   new String'("changeit"),
                   new String'("-alias"),
                   new String'(Alias),
                   new String'("-file"),
                   new String'(Certificate)],
                  Ran);
            else
               Run
                 (Keytool,
                  [new String'("-importcert"),
                   new String'("-noprompt"),
                   new String'("-trustcacerts"),
                   new String'("-keystore"),
                   new String'(Keystore),
                   new String'("-storepass"),
                   new String'("changeit"),
                   new String'("-alias"),
                   new String'(Alias),
                   new String'("-file"),
                   new String'(Certificate)],
                  Ran);
            end if;
            Success := Ran;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "installed" else "failed to install")
                 & " Java trust anchor " & Alias);
         when Remove =>
            if Keystore = "" then
               Run
                 (Keytool,
                  [new String'("-delete"),
                   new String'("-cacerts"),
                   new String'("-storepass"),
                   new String'("changeit"),
                   new String'("-alias"),
                   new String'(Alias)],
                  Ran);
            else
               Run
                 (Keytool,
                  [new String'("-delete"),
                   new String'("-keystore"),
                   new String'(Keystore),
                   new String'("-storepass"),
                   new String'("changeit"),
                   new String'("-alias"),
                   new String'(Alias)],
                  Ran);
            end if;
            Success := Ran;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "removed" else "failed to remove")
                 & " Java trust anchor " & Alias);
      end case;
   end Apply_Java;

   function NSS_Database return String is
   begin
      if Ada.Environment_Variables.Exists ("DEVCERT_NSS_DB") then
         return Ada.Environment_Variables.Value ("DEVCERT_NSS_DB");
      elsif Ada.Environment_Variables.Exists ("HOME") then
         return Ada.Environment_Variables.Value ("HOME") & "/.pki/nssdb";
      else
         return "";
      end if;
   end NSS_Database;

   procedure Apply_NSS
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Certutil : constant String := Locate ("certutil");
      DB       : constant String := NSS_Database;
      Alias    : constant String := "devcert-" & Safe_Fingerprint (Fingerprint);
      Ran      : Boolean := False;
   begin
      Success := False;
      if Certutil = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("certutil is not installed");
         return;
      elsif DB = "" or else not Ada.Directories.Exists (DB) then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("NSS database is missing");
         return;
      end if;

      case Operation is
         when Install =>
            Run
              (Certutil,
               [new String'("-A"),
                new String'("-d"),
                new String'("sql:" & DB),
                new String'("-n"),
                new String'(Alias),
                new String'("-t"),
                new String'("C,,"),
                new String'("-i"),
                new String'(Certificate)],
               Ran);
            Success := Ran;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "installed" else "failed to install")
                 & " NSS trust anchor " & Alias);
         when Remove =>
            Run
              (Certutil,
               [new String'("-D"),
                new String'("-d"),
                new String'("sql:" & DB),
                new String'("-n"),
                new String'(Alias)],
               Ran);
            Success := Ran;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "removed" else "failed to remove")
                 & " NSS trust anchor " & Alias);
      end case;
   end Apply_NSS;

   procedure Apply_MacOS
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Security : constant String := Locate ("security");
      Ran      : Boolean := False;
   begin
      Success := False;
      if Security = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("security is not installed");
         return;
      end if;

      case Operation is
         when Install =>
            Run
              (Security,
               [new String'("add-trusted-cert"),
                new String'("-d"),
                new String'("-r"),
                new String'("trustRoot"),
                new String'("-k"),
                new String'("/Library/Keychains/System.keychain"),
                new String'(Certificate)],
               Ran);
         when Remove =>
            Run
              (Security,
               [new String'("delete-certificate"),
                new String'("-Z"),
                new String'(Safe_Fingerprint (Fingerprint)),
                new String'("/Library/Keychains/System.keychain")],
               Ran);
      end case;
      Success := Ran;
      Message :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ((if Ran then "updated" else "failed to update")
           & " macOS trust store");
   end Apply_MacOS;

   procedure Apply_Windows
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Certutil : constant String := Locate ("certutil");
      Ran      : Boolean := False;
   begin
      Success := False;
      if Certutil = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("certutil is not installed");
         return;
      end if;

      case Operation is
         when Install =>
            Run
              (Certutil,
               [new String'("-addstore"),
                new String'("Root"),
                new String'(Certificate)],
               Ran);
         when Remove =>
            Run
              (Certutil,
               [new String'("-delstore"),
                new String'("Root"),
                new String'(Safe_Fingerprint (Fingerprint))],
               Ran);
      end case;
      Success := Ran;
      Message :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ((if Ran then "updated" else "failed to update")
           & " Windows trust store");
   end Apply_Windows;

   procedure Apply
     (Target      : Trust_Target;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String) is
   begin
      case Target is
         when Linux =>
            Apply_Linux (Operation, Certificate, Fingerprint, Success, Message);
         when NSS =>
            Apply_NSS (Operation, Certificate, Fingerprint, Success, Message);
         when Java =>
            Apply_Java (Operation, Certificate, Fingerprint, Success, Message);
         when MacOS =>
            Apply_MacOS (Operation, Certificate, Fingerprint, Success, Message);
         when Windows =>
            Apply_Windows (Operation, Certificate, Fingerprint, Success, Message);
      end case;
   end Apply;
end Devcert_Trust_Stores;
