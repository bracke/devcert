with Devcert.Certificate_Requests;

package Devcert.Certificate_Policies is
   function Default_Request return Devcert.Certificate_Requests.Request;

   function Build_Server_Request
     (Values : Devcert.Certificate_Requests.Identity_Array;
      Count  : Natural;
      Result : out Devcert.Certificate_Requests.Request)
      return Devcert.Certificate_Requests.Request_Status;
end Devcert.Certificate_Policies;
