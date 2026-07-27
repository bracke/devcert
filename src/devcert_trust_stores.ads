with Ada.Strings.Unbounded;

package Devcert_Trust_Stores is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Trust_Target is (Linux, NSS, Java, MacOS, Windows);
   type Action is (Install, Remove);
   type Trust_Store_Kind is (System_Store, NSS_Store, Java_Store);
   type Trust_State is
     (Unsupported,
      Available,
      Installed,
      Not_Installed,
      Tool_Missing,
      Permission_Required,
      Partial,
      Error);

   Max_Selected_Stores : constant := 3;
   subtype Selection_Index is Positive range 1 .. Max_Selected_Stores;
   type Store_Array is array (Selection_Index) of Trust_Store_Kind;

   type Store_Selection is record
      Count : Natural range 0 .. Max_Selected_Stores := 0;
      Items : Store_Array := [others => System_Store];
   end record;

   function Name (Target : Trust_Target) return String;
   function Name (Kind : Trust_Store_Kind) return String;
   function State_Image (State : Trust_State) return String;
   function Target_From_Name (Value : String; Target : out Trust_Target) return Boolean;
   function Kind_From_Name
     (Value : String;
      Kind  : out Trust_Store_Kind) return Boolean;
   function Detect_Default_Target return Trust_Target;
   function Default_Selection return Store_Selection;
   function Selection_From_Text
     (Value     : String;
      Selection : out Store_Selection) return Boolean;
   function Target_For (Kind : Trust_Store_Kind) return Trust_Target;
   function Probe (Kind : Trust_Store_Kind) return Trust_State;
   --  The NSS databases devcert would act on: the shared one Chromium reads
   --  under ~/.pki/nssdb, plus one per Firefox profile, which reads no other.
   --  DEVCERT_NSS_DB names one instead of all of them.
   function NSS_Database_Count return Natural;
   function NSS_Database_Path (Index : Positive) return String;

   function Fingerprint_Alias (Fingerprint : String) return String;
   function Plan
     (Target      : Trust_Target;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String) return String;

   procedure Apply
     (Target      : Trust_Target;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      Success     : out Boolean;
      Message     : out Unbounded_String);

   procedure Apply
     (Selection   : Store_Selection;
      Operation   : Action;
      Certificate : String;
      Fingerprint : String;
      State       : out Trust_State;
      Message     : out Unbounded_String);
end Devcert_Trust_Stores;
