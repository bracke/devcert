with Ada.Streams;

with CryptoLib.Certificates;
with CryptoLib.Hashes;

with Devcert_Secure_Files;
with Devcert_State;

package body Devcert_Crypto is
   use type Ada.Streams.Stream_Element_Offset;
   use Ada.Strings.Unbounded;
   use type CryptoLib.Certificates.Certificate_Status;

   Hex : constant String := "0123456789abcdef";

   function To_Bytes (Text : String) return Ada.Streams.Stream_Element_Array is
      Result : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
      Pos : Ada.Streams.Stream_Element_Offset := Result'First;
   begin
      for C of Text loop
         Result (Pos) := Ada.Streams.Stream_Element (Character'Pos (C));
         Pos := Pos + Ada.Streams.Stream_Element_Offset (1);
      end loop;
      return Result;
   end To_Bytes;

   function Hex_Image (Digest : CryptoLib.Hashes.SHA256_Digest) return String is
      Result : String (1 .. Digest'Length * 3 - 1);
      Pos    : Positive := Result'First;
   begin
      for I in Digest'Range loop
         declare
            B : constant Natural := Natural (Digest (I));
         begin
            if I /= Digest'First then
               Result (Pos) := ':';
               Pos := Pos + 1;
            end if;
            Result (Pos) := Hex (B / 16 + 1);
            Result (Pos + 1) := Hex (B mod 16 + 1);
            Pos := Pos + 2;
         end;
      end loop;
      return Result;
   end Hex_Image;

   function SHA256_Fingerprint (Data : String) return String is
   begin
      return Hex_Image (CryptoLib.Hashes.SHA256 (To_Bytes (Data)));
   end SHA256_Fingerprint;

   function Create_CA
     (Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status
   is
      Status : constant CryptoLib.Certificates.Certificate_Status :=
        CryptoLib.Certificates.Create_Local_CA
          ("devcert-local-development-ca", Certificate_PEM, Private_Key_PEM);
   begin
      if Status = CryptoLib.Certificates.Ok then
         return Ok;
      else
         return Unsupported;
      end if;
   end Create_CA;

   function Issue_Certificate
     (Name            : String;
      Certificate_PEM : out Unbounded_String;
      Private_Key_PEM : out Unbounded_String) return Operation_Status
   is
   begin
      if not Devcert_Secure_Files.Exists (Devcert_State.CA_Certificate_Path)
        or else not Devcert_Secure_Files.Exists (Devcert_State.CA_Private_Key_Path)
      then
         Certificate_PEM := Null_Unbounded_String;
         Private_Key_PEM := Null_Unbounded_String;
         return Unsupported;
      end if;

      declare
         CA_Cert : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.CA_Certificate_Path);
         CA_Key  : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.CA_Private_Key_Path);
         Status  : constant CryptoLib.Certificates.Certificate_Status :=
           CryptoLib.Certificates.Issue_Server_Certificate
             (CA_Cert,
              CA_Key,
              Name,
              [1 => To_Unbounded_String (Name)],
              Certificate_PEM,
              Private_Key_PEM);
      begin
         if Status = CryptoLib.Certificates.Ok then
            return Ok;
         else
            return Unsupported;
         end if;
      end;
   end Issue_Certificate;

   function Sign_CSR
     (CSR_PEM         : String;
      Certificate_PEM : out Unbounded_String) return Operation_Status
   is
   begin
      if not Devcert_Secure_Files.Exists (Devcert_State.CA_Certificate_Path)
        or else not Devcert_Secure_Files.Exists (Devcert_State.CA_Private_Key_Path)
      then
         Certificate_PEM := Null_Unbounded_String;
         return Unsupported;
      end if;

      declare
         CA_Cert : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.CA_Certificate_Path);
         CA_Key  : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.CA_Private_Key_Path);
         Status  : constant CryptoLib.Certificates.Certificate_Status :=
           CryptoLib.Certificates.Sign_CSR
             (CA_Cert, CA_Key, CSR_PEM, Certificate_PEM);
      begin
         if Status = CryptoLib.Certificates.Ok then
            return Ok;
         else
            return Unsupported;
         end if;
      end;
   end Sign_CSR;

   function Generate_PKCS12
     (Name        : String;
      Bundle_Data : out Unbounded_String) return Operation_Status
   is
   begin
      if not Devcert_Secure_Files.Exists (Devcert_State.Leaf_Certificate_Path (Name))
        or else not Devcert_Secure_Files.Exists (Devcert_State.Leaf_Private_Key_Path (Name))
      then
         Bundle_Data := Null_Unbounded_String;
         return Unsupported;
      end if;

      declare
         Cert   : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.Leaf_Certificate_Path (Name));
         Key    : constant String :=
           Devcert_Secure_Files.Read (Devcert_State.Leaf_Private_Key_Path (Name));
         Status : constant CryptoLib.Certificates.Certificate_Status :=
           CryptoLib.Certificates.Generate_PKCS12
             (Cert, Key, Name, "", Bundle_Data);
      begin
         if Status = CryptoLib.Certificates.Ok then
            return Ok;
         else
            return Unsupported;
         end if;
      end;
   end Generate_PKCS12;
end Devcert_Crypto;
