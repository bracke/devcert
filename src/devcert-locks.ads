package Devcert.Locks is
   type Lock_Result is (Acquired, Already_Held);

   --  Take the lock that keeps two devcert runs from writing the CA at once.
   --  @param Path Lock path, which is created as a directory because creating
   --         one is atomic where creating a file and writing it is not.
   --  @return Acquired, or Already_Held when another run has it.
   function Acquire (Path : String) return Lock_Result;
   --  @param Path Lock to release. Releasing one this process does not hold
   --         is not an error, so a failed run can clean up without checking.
   procedure Release (Path : String);
end Devcert.Locks;
