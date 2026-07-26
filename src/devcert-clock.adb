with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Strings.Unbounded;

package body Devcert.Clock is
   use Ada.Strings.Unbounded;

   Test_Time : Unbounded_String;

   function Now return String is
   begin
      if Length (Test_Time) /= 0 then
         return To_String (Test_Time);
      else
         return Ada.Calendar.Formatting.Image
           (Ada.Calendar.Clock, Include_Time_Fraction => False);
      end if;
   end Now;

   procedure Set_Test_Time (Value : String) is
      Parsed : constant Ada.Calendar.Time :=
        Ada.Calendar.Formatting.Value (Value);
   begin
      Test_Time := To_Unbounded_String
        (Ada.Calendar.Formatting.Image
           (Parsed, Include_Time_Fraction => False));
   end Set_Test_Time;

   procedure Reset_Test_Time is
   begin
      Test_Time := Null_Unbounded_String;
   end Reset_Test_Time;
end Devcert.Clock;
