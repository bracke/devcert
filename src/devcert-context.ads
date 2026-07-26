package Devcert.Context is
   type Color_Mode is (Auto, Always, Never);

   type Runtime_Context is record
      JSON_Output  : Boolean := False;
      Plain_Output : Boolean := False;
      Color        : Color_Mode := Auto;
   end record;
end Devcert.Context;
