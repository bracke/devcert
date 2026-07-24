package Devcert_Secure_Files is
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
end Devcert_Secure_Files;
