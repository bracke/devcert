with Devcert_Trust_Stores;

package Devcert.Trust_Stores.System is
   --  @return The system trust store this host actually has.
   function Default_Target return Devcert_Trust_Stores.Trust_Target
     renames Devcert_Trust_Stores.Detect_Default_Target;
end Devcert.Trust_Stores.System;
