with Ada.Characters.Handling;
with Ada.Strings.Fixed;

package body Devcert.Identities is
   function Normalize (Value : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both));
   end Normalize;

   function Is_Alpha_Num (C : Character) return Boolean is
   begin
      return C in 'a' .. 'z'
        or else C in 'A' .. 'Z'
        or else C in '0' .. '9';
   end Is_Alpha_Num;

   function Is_Hex (C : Character) return Boolean is
   begin
      return C in 'a' .. 'f'
        or else C in 'A' .. 'F'
        or else C in '0' .. '9';
   end Is_Hex;

   function Is_Digit (C : Character) return Boolean is
   begin
      return C in '0' .. '9';
   end Is_Digit;

   function Is_Valid_DNS (Value : String) return Boolean is
      Text        : constant String := Normalize (Value);
      Label_Start : Positive;
      Label_Len   : Natural := 0;
      Saw_Dot     : Boolean := False;

      function Valid_Label (First : Positive; Last : Natural) return Boolean is
      begin
         if Last < First or else Last - First + 1 > 63 then
            return False;
         elsif not Is_Alpha_Num (Text (First))
           or else not Is_Alpha_Num (Text (Last))
         then
            return False;
         end if;

         for I in First .. Last loop
            if not Is_Alpha_Num (Text (I)) and then Text (I) /= '-' then
               return False;
            end if;
         end loop;
         return True;
      end Valid_Label;
   begin
      if Text'Length = 0 or else Text'Length > 253 then
         return False;
      elsif Text = "*" then
         return False;
      elsif Text'Length > 2
        and then Text (Text'First) = '*'
        and then Text (Text'First + 1) = '.'
      then
         return Ada.Strings.Fixed.Index
             (Text (Text'First + 2 .. Text'Last), ".") /= 0
           and then Is_Valid_DNS (Text (Text'First + 2 .. Text'Last));
      elsif Ada.Strings.Fixed.Index (Text, "*") /= 0 then
         return False;
      end if;

      Label_Start := Text'First;
      for I in Text'Range loop
         if Text (I) = '.' then
            Saw_Dot := True;
            if not Valid_Label (Label_Start, I - 1) then
               return False;
            end if;
            Label_Start := I + 1;
            Label_Len := 0;
         else
            Label_Len := Label_Len + 1;
         end if;
      end loop;

      return Label_Len > 0
        and then Valid_Label (Label_Start, Text'Last)
        and then (Saw_Dot or else Text /= "local");
   end Is_Valid_DNS;

   function Is_Valid_IPv4 (Value : String) return Boolean is
      Text       : constant String := Normalize (Value);
      Parts      : Natural := 0;
      Number     : Natural := 0;
      Digit_Count : Natural := 0;

      function Finish_Part return Boolean is
      begin
         if Digit_Count = 0 or else Number > 255 then
            return False;
         end if;
         Parts := Parts + 1;
         Number := 0;
         Digit_Count := 0;
         return True;
      end Finish_Part;
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for C of Text loop
         if Is_Digit (C) then
            Number := Number * 10 + Character'Pos (C) - Character'Pos ('0');
            Digit_Count := Digit_Count + 1;
            if Digit_Count > 3 then
               return False;
            end if;
         elsif C = '.' then
            if not Finish_Part then
               return False;
            end if;
         else
            return False;
         end if;
      end loop;

      return Finish_Part and then Parts = 4;
   end Is_Valid_IPv4;

   function Is_Valid_IPv6 (Value : String) return Boolean is
      Text            : constant String := Normalize (Value);
      Groups          : Natural := 0;
      Digits_In_Group : Natural := 0;
      Compression     : Boolean := False;
      Previous_Colon  : Boolean := False;
   begin
      if Text'Length < 2 or else Ada.Strings.Fixed.Index (Text, ":") = 0 then
         return False;
      end if;

      for I in Text'Range loop
         declare
            C : constant Character := Text (I);
         begin
            if Is_Hex (C) then
               Digits_In_Group := Digits_In_Group + 1;
               Previous_Colon := False;
               if Digits_In_Group > 4 then
                  return False;
               end if;
            elsif C = ':' then
               if Previous_Colon then
                  if Compression then
                     return False;
                  end if;
                  Compression := True;
               elsif Digits_In_Group = 0 and then I /= Text'First then
                  return False;
               else
                  Groups := Groups + 1;
                  Digits_In_Group := 0;
               end if;
               Previous_Colon := True;
            else
               return False;
            end if;
         end;
      end loop;

      if Digits_In_Group > 0 then
         Groups := Groups + 1;
      end if;

      return (Compression and then Groups < 8) or else Groups = 8;
   end Is_Valid_IPv6;

   function Is_Valid_Email (Value : String) return Boolean is
      Text   : constant String := Normalize (Value);
      At_Pos : constant Natural := Ada.Strings.Fixed.Index (Text, "@");
   begin
      if At_Pos = 0
        or else At_Pos = Text'First
        or else At_Pos = Text'Last
        or else Ada.Strings.Fixed.Index (Text (At_Pos + 1 .. Text'Last), "@") /= 0
      then
         return False;
      end if;

      for I in Text'First .. At_Pos - 1 loop
         if Text (I) <= ' '
           or else Text (I) = '<'
           or else Text (I) = '>'
           or else Text (I) = '"'
           or else Text (I) = '\'
         then
            return False;
         end if;
      end loop;

      return Is_Valid_DNS (Text (At_Pos + 1 .. Text'Last));
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
