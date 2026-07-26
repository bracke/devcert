package Devcert_Secure_Files is
   procedure Ensure_Directory
     (Path : String;
      Mode : String := "700");

   procedure Atomic_Write
     (Path    : String;
      Content : String;
      Secret  : Boolean := False);
   procedure Atomic_Write_Raw
     (Path    : String;
      Content : String;
      Secret  : Boolean := False);
   function Exists (Path : String) return Boolean;
   function Read (Path : String) return String;
   function Permissions (Path : String) return String;
   function Has_Permissions (Path : String; Mode : String) return Boolean;
end Devcert_Secure_Files;
