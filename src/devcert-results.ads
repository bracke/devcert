with Devcert.Errors;

package Devcert.Results is
   type Result is record
      Error : Devcert.Errors.Error_Kind := Devcert.Errors.None;
   end record;

   --  @return A result carrying no error.
   function Ok return Result is ((Error => Devcert.Errors.None));
end Devcert.Results;
