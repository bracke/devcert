with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with CryptoLib.Certificates;

with Devcert.Clock;
with Devcert.Locks;
with Devcert_Crypto;
with Devcert_Secure_Files;

package body Devcert.CA_Store is
   use Ada.Strings.Unbounded;
   use type Devcert_Crypto.Operation_Status;

   function State_Image (State : CA_State) return String is
   begin
      case State is
         when Missing =>
            return "missing";
         when Complete =>
            return "complete";
         when Incomplete =>
            return "incomplete";
         when Unsafe_Permissions =>
            return "unsafe-permissions";
         when Invalid_Metadata =>
            return "invalid-metadata";
         when Invalid_Certificate =>
            return "invalid-certificate";
         when Invalid_Private_Key =>
            return "invalid-private-key";
         when Certificate_Key_Mismatch =>
            return "certificate-key-mismatch";
         when Unsupported_Format =>
            return "unsupported-format";
      end case;
   end State_Image;

   function Metadata_For (Certificate : String) return String is
   begin
      return "format-version=1" & ASCII.LF
        & "managed-by=devcert" & ASCII.LF
        & "created-at=" & Devcert.Clock.Now & ASCII.LF
        & "key-algorithm=P-384" & ASCII.LF
        & "certificate-fingerprint="
        & Devcert_Crypto.SHA256_Fingerprint (Certificate)
        & ASCII.LF;
   end Metadata_For;

   function Metadata_Matches (Metadata : String; Certificate : String) return Boolean is
      Needle : constant String :=
        "certificate-fingerprint="
        & Devcert_Crypto.SHA256_Fingerprint (Certificate);
   begin
      return Ada.Strings.Fixed.Index (Metadata, "format-version=1") /= 0
        and then Ada.Strings.Fixed.Index (Metadata, "managed-by=devcert") /= 0
        and then Ada.Strings.Fixed.Index (Metadata, "created-at=") /= 0
        and then Ada.Strings.Fixed.Index (Metadata, "key-algorithm=") /= 0
        and then Ada.Strings.Fixed.Index (Metadata, Needle) /= 0;
   end Metadata_Matches;

   function Looks_Like_Certificate (Text : String) return Boolean is
   begin
      return CryptoLib.Certificates.Contains_Certificate (Text);
   end Looks_Like_Certificate;

   function Looks_Like_Private_Key (Text : String) return Boolean is
   begin
      return CryptoLib.Certificates.Contains_Private_Key (Text);
   end Looks_Like_Private_Key;

   function Evaluate return CA_State is
      Has_Cert : constant Boolean := Devcert_Secure_Files.Exists (Certificate_Path);
      Has_Key  : constant Boolean := Devcert_Secure_Files.Exists (Private_Key_Path);
      Has_Meta : constant Boolean := Devcert_Secure_Files.Exists (Metadata_Path);
      Has_Issued : constant Boolean :=
        Devcert_Secure_Files.Exists (Devcert_State.Issued_Directory);
   begin
      if not Has_Cert and then not Has_Key and then not Has_Meta
        and then not Has_Issued
      then
         return Missing;
      elsif not Has_Cert or else not Has_Key or else not Has_Meta
        or else not Has_Issued
      then
         return Incomplete;
      --  Two questions, not one. Has_Permissions asserts the expected mode and
      --  can only answer where a GNU `stat` is on PATH; Accessible_By_Others
      --  asks the host directly whether the secrets are exposed, which is the
      --  invariant that matters and which also holds on macOS.
      elsif not Devcert_Secure_Files.Has_Permissions (Root, "700")
        or else not Devcert_Secure_Files.Has_Permissions (Private_Key_Path, "600")
        or else not Devcert_Secure_Files.Has_Permissions (Certificate_Path, "644")
        or else not Devcert_Secure_Files.Has_Permissions (Metadata_Path, "600")
        or else not Devcert_Secure_Files.Has_Permissions
          (Devcert_State.Issued_Directory, "700")
        or else Devcert_Secure_Files.Accessible_By_Others (Private_Key_Path)
        or else Devcert_Secure_Files.Accessible_By_Others (Metadata_Path)
        or else Devcert_Secure_Files.Directory_Accessible_By_Others (Root)
        or else Devcert_Secure_Files.Directory_Accessible_By_Others
          (Devcert_State.Issued_Directory)
      then
         return Unsafe_Permissions;
      end if;

      declare
         Certificate : constant String := Devcert_Secure_Files.Read (Certificate_Path);
         Private_Key : constant String := Devcert_Secure_Files.Read (Private_Key_Path);
         Metadata    : constant String := Devcert_Secure_Files.Read (Metadata_Path);
      begin
         if not Looks_Like_Certificate (Certificate) then
            return Invalid_Certificate;
         elsif not Looks_Like_Private_Key (Private_Key) then
            return Invalid_Private_Key;
         elsif not Metadata_Matches (Metadata, Certificate) then
            return Invalid_Metadata;
         elsif Devcert_Crypto.Private_Key_Matches_Certificate
           (Certificate, Private_Key) /= Devcert_Crypto.Ok
         then
            return Certificate_Key_Mismatch;
         else
            return Complete;
         end if;
      end;
   exception
      when others =>
         return Unsupported_Format;
   end Evaluate;

   function Create return CA_State is
      Certificate : Unbounded_String;
      Private_Key : Unbounded_String;
      Lock_Path   : constant String := Root & "/.devcert-create.lock";
      use type Devcert.Locks.Lock_Result;
   begin
      if Devcert.Locks.Acquire (Lock_Path) /= Devcert.Locks.Acquired then
         return Incomplete;
      end if;

      if Devcert_Crypto.Create_CA (Certificate, Private_Key) /= Devcert_Crypto.Ok then
         Devcert.Locks.Release (Lock_Path);
         return Unsupported_Format;
      end if;

      Devcert_Secure_Files.Ensure_Directory (Root, "700");
      Devcert_Secure_Files.Ensure_Directory
        (Devcert_State.Issued_Directory, "700");
      Devcert_Secure_Files.Atomic_Write (Certificate_Path, To_String (Certificate));
      Devcert_Secure_Files.Atomic_Write
        (Private_Key_Path, To_String (Private_Key), Secret => True);
      Devcert_Secure_Files.Atomic_Write
        (Metadata_Path,
         Metadata_For (Devcert_Secure_Files.Read (Certificate_Path)),
         Secret => True);
      Devcert.Locks.Release (Lock_Path);
      return Evaluate;
   exception
      when others =>
         Devcert.Locks.Release (Lock_Path);
         raise;
   end Create;

   function Ensure return CA_State is
      State : constant CA_State := Evaluate;
   begin
      if State = Missing then
         return Create;
      else
         return State;
      end if;
   end Ensure;
end Devcert.CA_Store;
