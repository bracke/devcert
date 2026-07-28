with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Fixed;

with GNAT.OS_Lib;

with CryptoLib.Certificates;

with Hostkit.Host;

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

   --  The host says which host it is. Sniffing the environment for it read every
   --  macOS as a Linux: OSTYPE is a shell variable, not part of the environment a
   --  spawned process inherits, so devcert reached for update-ca-certificates on a
   --  machine whose trust store is the keychain.
   function Detect_Default_Target return Trust_Target is
      use type Hostkit.Host.Kind;
   begin
      case Hostkit.Host.Current is
         when Hostkit.Host.Windows =>
            return Windows;
         when Hostkit.Host.MacOS =>
            return MacOS;
         when Hostkit.Host.Linux | Hostkit.Host.Unsupported =>
            --  A host with no body of its own is treated as the POSIX case, which is
            --  what the file-based backends assume.
            return Linux;
      end case;
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

   Max_NSS_Databases : constant := 16;
   type NSS_Database_List is
     array (1 .. Max_NSS_Databases) of Unbounded_String;

   procedure Discover_NSS_Databases
     (Databases : out NSS_Database_List;
      Count     : out Natural);

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
            elsif NSS_Database_Count = 0 then
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

   --  Asked of cryptolib, which owns PEM. Comparing scrubbed text here treated
   --  the armour as noise, so a private key and a certificate whose base64
   --  matched would have compared equal -- and this decides whether an anchor
   --  on disk is ours before it is deleted.
   function Same_Certificate (Left : String; Right : String) return Boolean is
   begin
      return CryptoLib.Certificates.Same_Certificate (Left, Right);
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
            --  Same tool, different directory: Fedora and RHEL keep anchors
            --  under /etc/pki/ca-trust, Arch under /etc/ca-certificates. The
            --  Fedora path was hardcoded, so on Arch every install wrote into
            --  a directory that does not exist and reported it as wanting
            --  privileges.
            declare
               Fedora : constant String := "/etc/pki/ca-trust/source/anchors";
               Arch   : constant String :=
                 "/etc/ca-certificates/trust-source/anchors";
            begin
               if Ada.Directories.Exists (Fedora) then
                  return Fedora & "/devcert-" & Safe & ".crt";
               elsif Ada.Directories.Exists (Arch) then
                  return Arch & "/devcert-" & Safe & ".crt";
               end if;
               return Fedora & "/devcert-" & Safe & ".crt";
            end;
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
               --  Nothing of ours to remove. That is a success, but saying
               --  "removed" for it is a claim about work that never happened,
               --  and it read as removal from a store that had refused the
               --  install moments earlier.
               Success := True;
               Message :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   ("no linux trust anchor for " & Fingerprint);
               return;
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

   --  Where the host keeps Firefox profiles. Firefox does not read the shared
   --  database under ~/.pki/nssdb -- that one is Chromium's -- and keeps a
   --  cert9.db of its own per profile, so a certificate installed only into the
   --  shared database is trusted by Chromium and by nothing else.
   function Firefox_Profile_Root return String is
      function Env (Name : String) return String is
        (if Ada.Environment_Variables.Exists (Name)
         then Ada.Environment_Variables.Value (Name)
         else "");

      Home : constant String := Env ("HOME");
   begin
      case Hostkit.Host.Current is
         when Hostkit.Host.Windows =>
            return (if Env ("APPDATA") = "" then ""
                    else Env ("APPDATA") & "\Mozilla\Firefox\Profiles");
         when Hostkit.Host.MacOS =>
            return (if Home = "" then ""
                    else Home & "/Library/Application Support/Firefox/Profiles");
         when others =>
            return (if Home = "" then "" else Home & "/.mozilla/firefox");
      end case;
   end Firefox_Profile_Root;

   procedure Add_Database
     (Databases : in out NSS_Database_List;
      Count     : in out Natural;
      Path      : String) is
   begin
      if Path /= "" and then Count < Max_NSS_Databases
        and then Ada.Directories.Exists (Path)
      then
         Count := Count + 1;
         --  Canonical, so every entry is comparable with every other. A profile
         --  found by enumeration arrives full-named already; leaving the ones
         --  built from environment variables as typed meant two spellings of
         --  the same directory, which only shows up where the separator
         --  differs from the one the caller wrote.
         Databases (Count) :=
           Ada.Strings.Unbounded.To_Unbounded_String
             (Ada.Directories.Full_Name (Path));
      end if;
   end Add_Database;

   procedure Discover_NSS_Databases
     (Databases : out NSS_Database_List;
      Count     : out Natural)
   is
      Root : constant String := Firefox_Profile_Root;
   begin
      Databases := [others => Ada.Strings.Unbounded.Null_Unbounded_String];
      Count := 0;

      --  An explicit database is the whole answer: a caller who names one is
      --  pointing at a disposable profile, not asking devcert to go looking.
      if Ada.Environment_Variables.Exists ("DEVCERT_NSS_DB") then
         Add_Database
           (Databases, Count,
            Ada.Environment_Variables.Value ("DEVCERT_NSS_DB"));
         return;
      end if;

      Add_Database (Databases, Count, NSS_Database);

      if Root = "" or else not Ada.Directories.Exists (Root) then
         return;
      end if;

      declare
         Search : Ada.Directories.Search_Type;
         Item   : Ada.Directories.Directory_Entry_Type;
      begin
         Ada.Directories.Start_Search
           (Search,
            Directory => Root,
            Pattern   => "*",
            Filter    =>
              [Ada.Directories.Directory     => True,
               Ada.Directories.Ordinary_File => False,
               Ada.Directories.Special_File  => False]);
         while Ada.Directories.More_Entries (Search) loop
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Item);
               Path : constant String := Ada.Directories.Full_Name (Item);
            begin
               --  A profile is a directory holding cert9.db; anything else in
               --  there is not a database and must not be handed to certutil.
               if Name /= "." and then Name /= ".."
                 and then Ada.Directories.Exists (Path & "/cert9.db")
               then
                  Add_Database (Databases, Count, Path);
               end if;
            end;
         end loop;
         Ada.Directories.End_Search (Search);
      exception
         when others =>
            null;
      end;
   end Discover_NSS_Databases;

   function NSS_Database_Count return Natural is
      Databases : NSS_Database_List;
      Count     : Natural;
   begin
      Discover_NSS_Databases (Databases, Count);
      return Count;
   end NSS_Database_Count;

   function NSS_Database_Path (Index : Positive) return String is
      Databases : NSS_Database_List;
      Count     : Natural;
   begin
      Discover_NSS_Databases (Databases, Count);
      if Index > Count then
         return "";
      end if;
      return Ada.Strings.Unbounded.To_String (Databases (Index));
   end NSS_Database_Path;

   procedure Apply_NSS
     (Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String)
   is
      Certutil  : constant String := Locate ("certutil");
      Alias     : constant String := Fingerprint_Alias (Fingerprint);
      Databases : NSS_Database_List;
      Found     : Natural;
      Failures  : Natural := 0;
      Combined  : Unbounded_String;

      DB  : Unbounded_String;
      Ran : Boolean := False;

      function Database return String is
        (Ada.Strings.Unbounded.To_String (DB));

      --  Absent and present-but-different are not the same answer: an anchor
      --  missing from one profile is nothing to remove there, while one whose
      --  stored certificate differs is somebody else's and must be left alone.
      function Alias_Present return Boolean is
         Output : Unbounded_String;
         Listed : Boolean := False;
      begin
         Run_Capture
           (Certutil,
            [new String'("-L"),
             new String'("-d"),
             new String'("sql:" & Database),
             new String'("-n"),
             new String'(Alias),
             new String'("-a")],
            Listed,
            Output);
         return Listed;
      end Alias_Present;

      function NSS_Contains_Certificate return Boolean is
         Output : Unbounded_String;
         Listed : Boolean := False;
      begin
         Run_Capture
           (Certutil,
            [new String'("-L"),
             new String'("-d"),
             new String'("sql:" & Database),
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
      procedure Note (Text : String) is
      begin
         if Ada.Strings.Unbounded.Length (Combined) > 0 then
            Ada.Strings.Unbounded.Append (Combined, "; ");
         end if;
         Ada.Strings.Unbounded.Append (Combined, Text);
      end Note;
   begin
      Success := False;
      Discover_NSS_Databases (Databases, Found);

      if Certutil = "" then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("certutil is not installed");
         return;
      elsif Found = 0 then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("NSS database is missing");
         return;
      end if;

      --  Every database the host has: the shared one Chromium reads, and one
      --  per Firefox profile, which reads nothing else.
      for Index in 1 .. Found loop
         DB := Databases (Index);
         Ran := False;

         case Operation is
            when Install =>
               Run
                 (Certutil,
                  [new String'("-A"),
                   new String'("-d"),
                   new String'("sql:" & Database),
                   new String'("-n"),
                   new String'(Alias),
                   new String'("-t"),
                   new String'("C,,"),
                   new String'("-i"),
                   new String'(Certificate)],
                  Ran);
               if Ran and then not NSS_Contains_Certificate then
                  Ran := False;
               end if;
               if not Ran then
                  Failures := Failures + 1;
               end if;
               Note
                 ((if Ran then "installed" else "failed to install")
                  & " NSS trust anchor " & Alias & " in " & Database);

            when Remove =>
               if not Alias_Present then
                  Note ("no NSS trust anchor " & Alias & " in " & Database);
               elsif not NSS_Contains_Certificate then
                  Failures := Failures + 1;
                  Note
                    ("NSS trust anchor fingerprint mismatch in " & Database
                     & "; refusing removal");
               else
                  Run
                    (Certutil,
                     [new String'("-D"),
                      new String'("-d"),
                      new String'("sql:" & Database),
                      new String'("-n"),
                      new String'(Alias)],
                     Ran);
                  if not Ran then
                     Failures := Failures + 1;
                  end if;
                  Note
                    ((if Ran then "removed" else "failed to remove")
                     & " NSS trust anchor " & Alias & " in " & Database);
               end if;
         end case;
      end loop;

      Success := Failures = 0;
      Message := Combined;
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

      --  A denial is not a broken store, and on macOS it is the ordinary case:
      --  the system keychain belongs to root. Reported as an error, the only
      --  thing wrong -- that this has to run under sudo -- was the one thing
      --  the message did not say. The privilege is asked about only once the
      --  attempt has failed: whether a keychain will have us is the keychain's
      --  answer to give, not ours to predict.
      if Ran then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("updated macOS trust store");
      elsif not Hostkit.Host.Is_Elevated then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("macOS trust store update requires permission for "
              & "/Library/Keychains/System.keychain");
      else
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("failed to update macOS trust store");
      end if;
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

      --  The machine Root store is the administrator's, the same way the system
      --  keychain is root's; see the note in Apply_MacOS.
      if Ran then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String ("updated Windows trust store");
      elsif not Hostkit.Host.Is_Elevated then
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("Windows trust store update requires permission for "
              & "the machine Root certificate store");
      else
         Message :=
           Ada.Strings.Unbounded.To_Unbounded_String
             ("failed to update Windows trust store");
      end if;
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
      --  Of the failures, how many were the store asking for privileges. Kept
      --  apart because that is the one failure the caller can act on, and the
      --  aggregate used to flatten it into Error along with everything else.
      Denied_Count  : Natural := 0;
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
            --  A removal that worked is reported as removed, not installed.
            --  The state is one success either way, but "uninstall" answering
            --  "system=installed" reads as the opposite of what happened, and
            --  this is a tool people run to be sure a root is gone.
            Ada.Strings.Unbounded.Append
              (Combined,
               Name (Kind)
               & "="
               & (if Operation = Remove and then Item_State = Installed
                  then "removed"
                  else State_Image (Item_State))
               & ": "
               & Ada.Strings.Unbounded.To_String (Item_Message));

            if Item_Success then
               Success_Count := Success_Count + 1;
            else
               Failure_Count := Failure_Count + 1;
               if Item_State = Permission_Required then
                  Denied_Count := Denied_Count + 1;
               end if;
            end if;
         end;
      end loop;

      Message := Combined;
      if Success_Count > 0 and then Failure_Count > 0 then
         State := Partial;
      elsif Success_Count > 0 then
         State := Installed;
      elsif Denied_Count = Failure_Count then
         --  Every store that failed did so for want of privileges, so the whole
         --  operation has one answer and it is actionable.
         State := Permission_Required;
      else
         State := Error;
      end if;
   end Apply;
end Devcert_Trust_Stores;
