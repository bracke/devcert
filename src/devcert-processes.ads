package Devcert.Processes is
   --  @param Name Program to find on PATH.
   --  @return Its resolved path, or "" when it is not there. Resolved rather
   --          than returned as given, because a name that fails to start is
   --          indistinguishable from a tool that ran and refused.
   function Locate (Name : String) return String;
end Devcert.Processes;
