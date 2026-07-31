with Ada.Strings.Unbounded;

with Devcert.Identities;

package Devcert.Certificate_Requests is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Certificate_Mode is (Server, Client, Email);
   type Request_Status is
     (Valid,
      Invalid_Identity,
      Too_Many_Identities,
      Mixed_Identity_Modes);

   Max_Identities : constant := 32;

   type Identity is record
      Kind  : Devcert.Identities.Identity_Kind := Devcert.Identities.DNS;
      Value : Unbounded_String;
   end record;

   subtype Identity_Index is Positive range 1 .. Max_Identities;
   type Identity_Array is array (Identity_Index) of Identity;

   type Request is record
      Mode : Certificate_Mode := Server;
      Count : Natural range 0 .. Max_Identities := 0;
      Identities : Identity_Array;
   end record;

   --  @param Mode What the certificate is for.
   --  @return A request carrying no identities yet.
   function Empty (Mode : Certificate_Mode := Server) return Request;

   --  @param Mode Mode to render.
   --  @return Its name, as devcert reports it.
   function Mode_Image (Mode : Certificate_Mode) return String;

   --  @param Item Request to add to.
   --  @param Value Identity as the user typed it; it is normalized here.
   --  @return Valid, or why it was refused: not an identity, more than
   --          Max_Identities, or a kind that does not belong with the mode --
   --          an email address in a server certificate is a mistake worth
   --          refusing rather than issuing.
   function Add_Identity
     (Item  : in out Request;
      Value : String) return Request_Status;

   --  @param Item Request to read.
   --  @return The name that goes in the subject, which is the first identity.
   function Common_Name (Item : Request) return String;
   --  @param Item Request to read.
   --  @return The name its files are written under, which is derived from the
   --          first identity and safe to use as a file name.
   function Output_Name (Item : Request) return String;
end Devcert.Certificate_Requests;
