with Ada.Strings.Unbounded;

package body Devcert.Certificate_Policies is
   function Default_Request return Devcert.Certificate_Requests.Request is
   begin
      return Devcert.Certificate_Requests.Empty;
   end Default_Request;

   function Build_Server_Request
     (Values : Devcert.Certificate_Requests.Identity_Array;
      Count  : Natural;
      Result : out Devcert.Certificate_Requests.Request)
      return Devcert.Certificate_Requests.Request_Status
   is
      use type Devcert.Certificate_Requests.Request_Status;
      Status : Devcert.Certificate_Requests.Request_Status;
   begin
      Result := Devcert.Certificate_Requests.Empty;
      if Count = 0 then
         Status := Devcert.Certificate_Requests.Add_Identity (Result, "localhost");
         return Status;
      end if;

      for I in 1 .. Count loop
         Status :=
           Devcert.Certificate_Requests.Add_Identity
             (Result, Ada.Strings.Unbounded.To_String (Values (I).Value));
         if Status /= Devcert.Certificate_Requests.Valid then
            return Status;
         end if;
      end loop;
      return Devcert.Certificate_Requests.Valid;
   end Build_Server_Request;
end Devcert.Certificate_Policies;
