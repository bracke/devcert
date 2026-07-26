with Ada.Characters.Handling;

package body Devcert.Certificate_Requests is
   use Ada.Strings.Unbounded;
   use type Devcert.Identities.Identity_Kind;

   function Empty (Mode : Certificate_Mode := Server) return Request is
   begin
      return (Mode => Mode, Count => 0, Identities => [others => <>]);
   end Empty;

   function Mode_Image (Mode : Certificate_Mode) return String is
   begin
      case Mode is
         when Server =>
            return "server";
         when Client =>
            return "client";
         when Email =>
            return "email";
      end case;
   end Mode_Image;

   function Contains (Item : Request; Value : String) return Boolean is
   begin
      for I in 1 .. Item.Count loop
         if To_String (Item.Identities (I).Value) = Value then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Add_Identity
     (Item  : in out Request;
      Value : String) return Request_Status
   is
      Normalized : constant String := Devcert.Identities.Normalize (Value);
      Kind       : Devcert.Identities.Identity_Kind;
   begin
      if not Devcert.Identities.Classify (Normalized, Kind) then
         return Invalid_Identity;
      elsif Item.Mode = Email and then Kind /= Devcert.Identities.Email then
         return Mixed_Identity_Modes;
      elsif Item.Mode /= Email and then Kind = Devcert.Identities.Email then
         return Mixed_Identity_Modes;
      elsif Contains (Item, Normalized) then
         return Valid;
      elsif Item.Count = Max_Identities then
         return Too_Many_Identities;
      end if;

      Item.Count := Item.Count + 1;
      Item.Identities (Item.Count) :=
        (Kind => Kind, Value => To_Unbounded_String (Normalized));
      return Valid;
   end Add_Identity;

   function Common_Name (Item : Request) return String is
   begin
      if Item.Count = 0 then
         return "localhost";
      else
         return To_String (Item.Identities (1).Value);
      end if;
   end Common_Name;

   function Output_Name (Item : Request) return String is
      Source : constant String := Common_Name (Item);
      Result : String (Source'Range);
   begin
      for I in Source'Range loop
         declare
            C : constant Character := Source (I);
         begin
            if Ada.Characters.Handling.Is_Alphanumeric (C)
              or else C = '.'
              or else C = '-'
              or else C = '_'
            then
               Result (I) := C;
            else
               Result (I) := '_';
            end if;
         end;
      end loop;
      return Result;
   end Output_Name;
end Devcert.Certificate_Requests;
