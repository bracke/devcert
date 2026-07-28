with Ada.Characters.Handling;
with Ada.Strings.Fixed;

with CryptoLib.Certificates;

package body Devcert.Identities is
   function Normalize (Value : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both));
   end Normalize;

   --  One implementation decides what an identity is, and it is the one that
   --  has to encode it. Validating here as well produced rules that could
   --  disagree with cryptolib's in either direction: an identity accepted here
   --  and refused at encoding time, or refused here that would have encoded.
   function Is_Valid_DNS (Value : String) return Boolean is
   begin
      return CryptoLib.Certificates.Valid_DNS_Name (Normalize (Value));
   end Is_Valid_DNS;

   function Is_Valid_IPv4 (Value : String) return Boolean is
   begin
      return CryptoLib.Certificates.Valid_IP_Address (Normalize (Value))
        and then Ada.Strings.Fixed.Index (Normalize (Value), ":") = 0;
   end Is_Valid_IPv4;

   function Is_Valid_IPv6 (Value : String) return Boolean is
   begin
      return CryptoLib.Certificates.Valid_IP_Address (Normalize (Value))
        and then Ada.Strings.Fixed.Index (Normalize (Value), ":") /= 0;
   end Is_Valid_IPv6;

   function Is_Valid_Email (Value : String) return Boolean is
   begin
      return CryptoLib.Certificates.Valid_Email_Address (Normalize (Value));
   end Is_Valid_Email;

   function Classify (Value : String; Kind : out Identity_Kind) return Boolean is
      Text : constant String := Normalize (Value);
   begin
      if Is_Valid_IPv4 (Text) then
         Kind := IPv4;
         return True;
      elsif Is_Valid_IPv6 (Text) then
         Kind := IPv6;
         return True;
      elsif Is_Valid_Email (Text) then
         Kind := Email;
         return True;
      elsif Is_Valid_DNS (Text) then
         Kind := DNS;
         return True;
      else
         Kind := DNS;
         return False;
      end if;
   end Classify;
end Devcert.Identities;
