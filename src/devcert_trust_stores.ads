with Ada.Strings.Unbounded;

package Devcert_Trust_Stores is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Trust_Target is (Linux, NSS, Java, MacOS, Windows);
   type Action is (Install, Remove);

   function Name (Target : Trust_Target) return String;
   function Target_From_Name (Value : String; Target : out Trust_Target) return Boolean;
   function Detect_Default_Target return Trust_Target;
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
end Devcert_Trust_Stores;
