with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Fixed;

with GNAT.OS_Lib;

package body Devcert_Trust_Stores is
   use type GNAT.OS_Lib.String_Access;

   type Linux_System_Backend is
     (No_Backend,
      Configured_Anchor_Directory,
      Update_CA_Certificates,
      Update_CA_Trust,
      Trust_Anchor);

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

   function Name (Kind : Trust_Store_Kind) return String is
   begin
      case Kind is
         when System_Store =>
            return "system";
         when NSS_Store =>
            return "nss";
         when Java_Store =>
            return "java";
      end case;
   end Name;

   function State_Image (State : Trust_State) return String is
   begin
      case State is
         when Unsupported =>
            return "unsupported";
         when Available =>
            return "available";
         when Installed =>
            return "installed";
         when Not_Installed =>
            return "not-installed";
         when Tool_Missing =>
            return "tool-missing";
         when Permission_Required =>
            return "permission-required";
         when Partial =>
            return "partial";
         when Error =>
            return "error";
      end case;
   end State_Image;

   function Target_From_Name (Value : String; Target : out Trust_Target) return Boolean is
   begin
      if Value = "system" then
         Target := Detect_Default_Target;
      elsif Value = "linux" then
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

   function Kind_From_Name
     (Value : String;
      Kind  : out Trust_Store_Kind) return Boolean
   is
   begin
      if Value = "system"
        or else Value = "linux"
        or else Value = "macos"
        or else Value = "mac"
        or else Value = "windows"
        or else Value = "win"
      then
         Kind := System_Store;
      elsif Value = "nss" then
         Kind := NSS_Store;
      elsif Value = "java" then
         Kind := Java_Store;
      else
         return False;
      end if;
      return True;
   end Kind_From_Name;

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

   function Default_Selection return Store_Selection is
   begin
      return (Count => 1, Items => [1 => System_Store, others => System_Store]);
   end Default_Selection;

   function Contains
     (Selection : Store_Selection;
      Kind      : Trust_Store_Kind) return Boolean
   is
   begin
      for I in 1 .. Selection.Count loop
         if Selection.Items (I) = Kind then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Append
     (Selection : in out Store_Selection;
      Kind      : Trust_Store_Kind) is
   begin
      if not Contains (Selection, Kind) then
         Selection.Count := Selection.Count + 1;
         Selection.Items (Selection.Count) := Kind;
      end if;
   end Append;

   function Selection_From_Text
     (Value     : String;
      Selection : out Store_Selection) return Boolean
   is
      First : Positive := Value'First;
      Last  : Natural;
      Comma : Natural;
      Kind  : Trust_Store_Kind;
   begin
      Selection := (Count => 0, Items => [others => System_Store]);
      if Value'Length = 0 then
         return False;
      end if;

      while First <= Value'Last loop
         Comma := Ada.Strings.Fixed.Index
           (Value (First .. Value'Last), ",");
         if Comma = 0 then
            Last := Value'Last;
         else
            Last := Comma - 1;
         end if;

         declare
            Part : constant String :=
              Ada.Strings.Fixed.Trim (Value (First .. Last), Ada.Strings.Both);
         begin
            if Part = "" or else not Kind_From_Name (Part, Kind) then
               return False;
            end if;
            Append (Selection, Kind);
         end;

         First := Last + 2;
      end loop;

      return Selection.Count > 0;
   end Selection_From_Text;

   function Target_For (Kind : Trust_Store_Kind) return Trust_Target is
   begin
      case Kind is
         when System_Store =>
            return Detect_Default_Target;
         when NSS_Store =>
            return NSS;
         when Java_Store =>
            return Java;
      end case;
   end Target_For;

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

   function Fingerprint_Alias (Fingerprint : String) return String is
   begin
      return "devcert-" & Safe_Fingerprint (Fingerprint);
   end Fingerprint_Alias;

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

   function NSS_Database return String;
   function Detect_Linux_Backend return Linux_System_Backend;

   function Configured_Linux_Trust_Dir return String is
   begin
      if Ada.Environment_Variables.Exists ("DEVCERT_LINUX_TRUST_DIR") then
         return Ada.Environment_Variables.Value ("DEVCERT_LINUX_TRUST_DIR");
      else
         return "";
      end if;
   end Configured_Linux_Trust_Dir;

   function Probe (Kind : Trust_Store_Kind) return Trust_State is
   begin
      case Kind is
         when System_Store =>
            case Detect_Default_Target is
               when Linux =>
                  return
                    (if Detect_Linux_Backend = No_Backend
                     then Tool_Missing
                     else Available);
               when MacOS =>
                  if Locate ("security") /= "" then
                     return Available;
                  else
                     return Tool_Missing;
                  end if;
               when Windows =>
                  if Locate ("certutil") /= "" then
                     return Available;
                  else
                     return Tool_Missing;
                  end if;
               when others =>
                  return Unsupported;
            end case;
         when NSS_Store =>
            if Locate ("certutil") = "" then
               return Tool_Missing;
            elsif NSS_Database = "" or else not Ada.Directories.Exists (NSS_Database) then
               return Not_Installed;
            else
               return Available;
            end if;
         when Java_Store =>
            if Locate ("keytool") = "" then
               return Tool_Missing;
            else
               return Available;
            end if;
      end case;
   end Probe;

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

   function Read_Text_File (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Strings.Unbounded.Append (Result, Ada.Text_IO.Get_Line (File));
         Ada.Strings.Unbounded.Append (Result, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return Ada.Strings.Unbounded.To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end Read_Text_File;

   procedure Run_Capture
     (Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Success : out Boolean;
      Output  : out Unbounded_String)
   is
      Return_Code : Integer := 1;
      Spawned     : Boolean := False;
      Output_File : constant String := "/tmp/devcert-trust-capture.out";
   begin
      GNAT.OS_Lib.Spawn
        (Program,
         Args,
         Output_File,
         Spawned,
         Return_Code,
         Err_To_Out => True);
      Output :=
        (if Ada.Directories.Exists (Output_File)
         then Ada.Strings.Unbounded.To_Unbounded_String
           (Read_Text_File (Output_File))
         else Ada.Strings.Unbounded.Null_Unbounded_String);
      if Ada.Directories.Exists (Output_File) then
         Ada.Directories.Delete_File (Output_File);
      end if;
      Success := Spawned and then Return_Code = 0;
   end Run_Capture;

   function Canonical_PEM (Text : String) return String is
      Result : Unbounded_String;
   begin
      for C of Text loop
         if C in 'A' .. 'Z'
           or else C in 'a' .. 'z'
           or else C in '0' .. '9'
           or else C = '+'
           or else C = '/'
           or else C = '='
           or else C = '-'
         then
            Ada.Strings.Unbounded.Append (Result, C);
         end if;
      end loop;
      return Ada.Strings.Unbounded.To_String (Result);
   end Canonical_PEM;

   function Same_Certificate (Left : String; Right : String) return Boolean is
   begin
      return Canonical_PEM (Left) = Canonical_PEM (Right);
   end Same_Certificate;

   function Detect_Linux_Backend return Linux_System_Backend is
   begin
      if Configured_Linux_Trust_Dir /= "" then
         return Configured_Anchor_Directory;
      elsif Locate ("update-ca-certificates") /= "" then
         return Update_CA_Certificates;
      elsif Locate ("update-ca-trust") /= "" then
         return Update_CA_Trust;
      elsif Locate ("trust") /= "" then
         return Trust_Anchor;
      else
         return No_Backend;
      end if;
   end Detect_Linux_Backend;

   function Linux_Target
     (Backend     : Linux_System_Backend;
      Fingerprint : String) return String
   is
      Safe : constant String := Safe_Fingerprint (Fingerprint);
   begin
      case Backend is
         when Configured_Anchor_Directory =>
            return Configured_Linux_Trust_Dir & "/devcert-" & Safe & ".crt";
         when Update_CA_Certificates =>
            return "/usr/local/share/ca-certificates/devcert-" & Safe & ".crt";
         when Update_CA_Trust =>
            return "/etc/pki/ca-trust/source/anchors/devcert-" & Safe & ".crt";
         when others =>
            return "";
      end case;
   end Linux_Target;

   procedure Refresh_Linux
     (Backend : Linux_System_Backend;
      Success : out Boolean)
   is
   begin
      case Backend is
         when Configured_Anchor_Directory =>
            Success := True;
         when Update_CA_Certificates =>
            Run
              (Locate ("update-ca-certificates"),
               [1 => new String'("--fresh")],
               Success);
         when Update_CA_Trust =>
            Run
              (Locate ("update-ca-trust"),
               [1 => new String'("extract")],
               Success);
         when others =>
            Success := True;
      end case;
   end Refresh_Linux;

   procedure Apply_Linux
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Backend : constant Linux_System_Backend := Detect_Linux_Backend;
      Target : constant String :=
        Linux_Target (Backend, Fingerprint);
      Ran : Boolean := False;
   begin
      Success := False;
      Message := Ada.Strings.Unbounded.Null_Unbounded_String;

      if Backend = No_Backend then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("linux trust backend is not installed");
         return;
      end if;

      case Operation is
         when Install =>
            if Backend = Trust_Anchor then
               Run
                 (Locate ("trust"),
                  [new String'("anchor"), new String'(Certificate)],
                  Ran);
            else
               if Backend = Configured_Anchor_Directory then
                  Ada.Directories.Create_Path (Configured_Linux_Trust_Dir);
               end if;
               Ada.Directories.Copy_File (Certificate, Target);
               Refresh_Linux (Backend, Ran);
            end if;
            Success := Ran;
            if Success then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("installed linux trust anchor for " & Fingerprint);
            else
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("linux trust refresh failed");
            end if;
         when Remove =>
            if Backend = Trust_Anchor then
               Run
                 (Locate ("trust"),
                  [new String'("anchor"),
                   new String'("--remove"),
                   new String'(Certificate)],
                  Ran);
            elsif Ada.Directories.Exists (Target)
              and then Same_Certificate (Read_Text_File (Target), Read_Text_File (Certificate))
            then
               Ada.Directories.Delete_File (Target);
               Refresh_Linux (Backend, Ran);
            elsif Ada.Directories.Exists (Target) then
               Ran := False;
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("linux trust anchor fingerprint mismatch; refusing removal");
               return;
            else
               Ran := True;
            end if;
            Success := Ran;
            if Success then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("removed linux trust anchor for " & Fingerprint);
            else
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("linux trust removal failed");
            end if;
      end case;
   exception
      when others =>
         Success := False;
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("linux trust store update requires permission for " & Target);
   end Apply_Linux;

   function Java_Contains_Certificate
     (Keytool     : String;
      Keystore    : String;
      Alias       : String;
      Certificate : String) return Boolean
   is
      Ran    : Boolean := False;
      Output : Unbounded_String;
   begin
      if Keystore = "" then
         Run_Capture
           (Keytool,
            [new String'("-list"),
             new String'("-rfc"),
             new String'("-cacerts"),
             new String'("-storepass"),
             new String'("changeit"),
             new String'("-alias"),
             new String'(Alias)],
            Ran,
            Output);
      else
         Run_Capture
           (Keytool,
            [new String'("-list"),
             new String'("-rfc"),
             new String'("-keystore"),
             new String'(Keystore),
             new String'("-storepass"),
             new String'("changeit"),
             new String'("-alias"),
             new String'(Alias)],
            Ran,
            Output);
      end if;
      return Ran
        and then Same_Certificate
          (Ada.Strings.Unbounded.To_String (Output),
           Read_Text_File (Certificate));
   end Java_Contains_Certificate;

   procedure Apply_Java
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Keytool : constant String := Locate ("keytool");
      Alias   : constant String := Fingerprint_Alias (Fingerprint);
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
            if Success
              and then not Java_Contains_Certificate
                (Keytool, Keystore, Alias, Certificate)
            then
               Success := False;
               Ran := False;
            end if;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "installed" else "failed to install")
                 & " Java trust anchor " & Alias);
         when Remove =>
            if not Java_Contains_Certificate
              (Keytool, Keystore, Alias, Certificate)
            then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("Java trust anchor fingerprint mismatch; refusing removal");
               return;
            elsif Keystore = "" then
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
      Alias    : constant String := Fingerprint_Alias (Fingerprint);
      Ran      : Boolean := False;

      function NSS_Contains_Certificate return Boolean is
         Output : Unbounded_String;
         Listed : Boolean := False;
      begin
         Run_Capture
           (Certutil,
            [new String'("-L"),
             new String'("-d"),
             new String'("sql:" & DB),
             new String'("-n"),
             new String'(Alias),
             new String'("-a")],
            Listed,
            Output);
         return Listed
           and then Same_Certificate
             (Ada.Strings.Unbounded.To_String (Output),
              Read_Text_File (Certificate));
      end NSS_Contains_Certificate;
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
            if Success and then not NSS_Contains_Certificate then
               Success := False;
               Ran := False;
            end if;
            Message :=
              Ada.Strings.Unbounded.To_Unbounded_String
                ((if Ran then "installed" else "failed to install")
                 & " NSS trust anchor " & Alias);
         when Remove =>
            if not NSS_Contains_Certificate then
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("NSS trust anchor fingerprint mismatch; refusing removal");
               return;
            end if;
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

   function State_From_Result
     (Kind    : Trust_Store_Kind;
      Success : Boolean;
      Message : String) return Trust_State
   is
      pragma Unreferenced (Kind);
   begin
      if Success then
         return Installed;
      elsif Ada.Strings.Fixed.Index (Message, "not installed") /= 0
        or else Ada.Strings.Fixed.Index (Message, "is missing") /= 0
      then
         return Tool_Missing;
      elsif Ada.Strings.Fixed.Index (Message, "requires permission") /= 0 then
         return Permission_Required;
      else
         return Error;
      end if;
   end State_From_Result;

   procedure Apply
     (Selection   : Store_Selection;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      State       : out Trust_State;
      Message     : out Unbounded_String)
   is
      Success_Count : Natural := 0;
      Failure_Count : Natural := 0;
      Combined      : Unbounded_String;
   begin
      Message := Ada.Strings.Unbounded.Null_Unbounded_String;
      if Selection.Count = 0 then
         State := Unsupported;
         Message := Ada.Strings.Unbounded.To_Unbounded_String
           ("no trust stores selected");
         return;
      end if;

      for I in 1 .. Selection.Count loop
         declare
            Kind          : constant Trust_Store_Kind := Selection.Items (I);
            Target        : constant Trust_Target := Target_For (Kind);
            Item_Success  : Boolean := False;
            Item_Message  : Unbounded_String;
            Item_State    : Trust_State;
         begin
            Apply
              (Target, Operation, Certificate, Fingerprint, Item_Success,
               Item_Message);
            Item_State :=
              State_From_Result
                (Kind, Item_Success,
                 Ada.Strings.Unbounded.To_String (Item_Message));

            if I > 1 then
               Ada.Strings.Unbounded.Append (Combined, "; ");
            end if;
            Ada.Strings.Unbounded.Append
              (Combined,
               Name (Kind)
               & "="
               & State_Image (Item_State)
               & ": "
               & Ada.Strings.Unbounded.To_String (Item_Message));

            if Item_Success then
               Success_Count := Success_Count + 1;
            else
               Failure_Count := Failure_Count + 1;
            end if;
         end;
      end loop;

      Message := Combined;
      if Success_Count > 0 and then Failure_Count > 0 then
         State := Partial;
      elsif Success_Count > 0 then
         State := Installed;
      else
         State := Error;
      end if;
   end Apply;
end Devcert_Trust_Stores;
