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

   function Empty (Mode : Certificate_Mode := Server) return Request;

   function Mode_Image (Mode : Certificate_Mode) return String;

   function Add_Identity
     (Item  : in out Request;
      Value : String) return Request_Status;

   function Common_Name (Item : Request) return String;
   function Output_Name (Item : Request) return String;
end Devcert.Certificate_Requests;
