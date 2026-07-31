package Devcert_Secure_Files is
   --  Create a directory if it is not there, with the mode it must have.
   --  @param Path Directory to create.
   --  @param Mode POSIX mode the directory is created with; the default keeps
   --         it to its owner, which is what a CA root needs.
   procedure Ensure_Directory
     (Path : String;
      Mode : String := "700");

   --  Write a file so a reader sees either the old contents or the new, never
   --  a half-written one: the content goes to a temporary beside it and is
   --  renamed over.
   --  @param Path File to write.
   --  @param Content Text to write.
   --  @param Secret Restrict the file to its owner, for a private key.
   procedure Atomic_Write
     (Path    : String;
      Content : String;
      Secret  : Boolean := False);
   --  The same, without touching line endings -- for bytes that are not text.
   --  @param Path File to write.
   --  @param Content Bytes to write.
   --  @param Secret Restrict the file to its owner.
   procedure Atomic_Write_Raw
     (Path    : String;
      Content : String;
      Secret  : Boolean := False);
   --  @param Path File to look for.
   --  @return True when it is there.
   function Exists (Path : String) return Boolean;
   --  @param Path File to read.
   --  @return Its contents, or "" when it cannot be read.
   function Read (Path : String) return String;
   --  @param Path File to inspect.
   --  @return Its POSIX mode as text, or "" where the host will not say.
   function Permissions (Path : String) return String;
   --  @param Path File to inspect.
   --  @param Mode Mode it is expected to carry.
   --  @return True when they match. This is an expectation, not a security
   --          invariant -- Accessible_By_Others is the one that answers that.
   function Has_Permissions (Path : String; Mode : String) return Boolean;

   --  Can anyone but the owner read this file? Asked of the host through
   --  Hostkit, which reads the POSIX mode bits itself rather than shelling out
   --  to a `stat` whose options differ between GNU and BSD, and which declines
   --  to answer on Windows instead of guessing at an ACL. Unlike
   --  Has_Permissions this is a security invariant, not an expected-mode
   --  assertion: it is only meaningful for files that must stay private.
   --  @param Path File to inspect.
   --  @return True when someone other than the owner can read it. False on a
   --          host that declines to answer, so a caller must not read False as
   --          proof of privacy on Windows.
   function Accessible_By_Others (Path : String) return Boolean;

   --  The same question for a directory. A directory's mode bits do not mean
   --  what a file's mean, so hostkit answers them separately.
   --  @param Path Directory to inspect.
   --  @return True when someone other than the owner can reach it.
   function Directory_Accessible_By_Others (Path : String) return Boolean;

   --  The host's directory for scratch files, without a trailing separator.
   --  Asked of hostkit: $TMPDIR or /tmp on POSIX, GetTempPath on Windows, which
   --  answers even for a spawned tool whose environment carries no TEMP.
   --  "/tmp" is not a place every host has.
   --  @return The directory, without a trailing separator.
   function Temp_Directory return String;
end Devcert_Secure_Files;
