package Devcert.Locks is
   type Lock_Result is (Acquired, Already_Held);

   function Acquire (Path : String) return Lock_Result;
   procedure Release (Path : String);
end Devcert.Locks;
