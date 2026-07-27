package Devcert_Exit_Codes is
   Success               : constant := 0;
   General_Failure       : constant := 1;
   Usage_Error           : constant := 2;
   CA_State_Error        : constant := 3;
   Certificate_Error     : constant := 4;
   Cryptographic_Error   : constant := 5;
   Trust_Store_Error     : constant := 6;
   Permission_Error      : constant := 7;
   Partial_Success       : constant := 8;
   Unsupported_Feature   : constant := 9;
   --  10 is the next free code. A localization error was declared here once and
   --  never produced -- a missing or malformed catalog falls back to bare
   --  message identifiers so the real error can still be reported -- so the
   --  number went back into the pool rather than being kept out of it.
end Devcert_Exit_Codes;
