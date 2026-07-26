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
   Localization_Error    : constant := 10;
end Devcert_Exit_Codes;
