with Devcert.Certificate_Requests;

package Devcert.Certificate_Policies is
   --  @return The request devcert issues from when the caller named no
   --          identities: a server certificate for localhost.
   function Default_Request return Devcert.Certificate_Requests.Request;

   --  @param Values Identities the caller gave, in order.
   --  @param Count How many of them are set.
   --  @param Result The assembled request, when they are acceptable.
   --  @return Valid, or why not -- an identity that is not one, too many of
   --          them, or kinds that do not belong together.
   function Build_Server_Request
     (Values : Devcert.Certificate_Requests.Identity_Array;
      Count  : Natural;
      Result : out Devcert.Certificate_Requests.Request)
      return Devcert.Certificate_Requests.Request_Status;
end Devcert.Certificate_Policies;
