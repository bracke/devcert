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

   --  Can anyone but the owner read this file? Asked of the host through
   --  Hostkit, which reads the POSIX mode bits itself rather than shelling out
   --  to a `stat` whose options differ between GNU and BSD, and which declines
   --  to answer on Windows instead of guessing at an ACL. Unlike
   --  Has_Permissions this is a security invariant, not an expected-mode
   --  assertion: it is only meaningful for files that must stay private.
   function Accessible_By_Others (Path : String) return Boolean;

   --  The same question for a directory. A directory's mode bits do not mean
   --  what a file's mean, so hostkit answers them separately.
   function Directory_Accessible_By_Others (Path : String) return Boolean;
end Devcert_Secure_Files;
