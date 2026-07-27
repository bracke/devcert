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
   --  10 was a localization error. Nothing produced it and nothing should: a
   --  missing or malformed catalog falls back to bare message identifiers so
   --  that the real error can still be reported. The number stays retired
   --  rather than being reused for something else.
end Devcert_Exit_Codes;
