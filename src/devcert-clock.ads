package Devcert.Clock is
   --  @return The current time, or whatever Set_Test_Time last fixed it to.
   function Now return String;
   --  Fix the time, so that what a test produces does not depend on when it
   --  ran.
   --  @param Value The time to report until reset.
   procedure Set_Test_Time (Value : String);
   --  Go back to reading the real clock.
   procedure Reset_Test_Time;
end Devcert.Clock;
