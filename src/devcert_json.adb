with Ada.Strings.Unbounded;

with Devcert_Core;

package body Devcert_JSON is
   use Ada.Strings.Unbounded;

   function Escape (Text : String) return String is
      Result : Unbounded_String;
   begin
      for C of Text loop
         case C is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when ASCII.LF =>
               Append (Result, "\n");
            when ASCII.CR =>
               Append (Result, "\r");
            when ASCII.HT =>
               Append (Result, "\t");
            when others =>
               if Character'Pos (C) < 32 then
                  Append (Result, "?");
               else
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape;

   function Error (Command : String; Message : String) return String is
   begin
      return "{""schema_version"":"
        & Devcert_Core.Json_Schema_Version
        & ",""status"":""error"",""command"":"""
        & Escape (Command)
        & """,""error"":"""
        & Escape (Message)
        & """}";
   end Error;

   function Status (Command : String; Message : String) return String is
   begin
      return "{""schema_version"":"
        & Devcert_Core.Json_Schema_Version
        & ",""status"":""success"",""command"":"""
        & Escape (Command)
        & """,""message"":"""
        & Escape (Message)
        & """}";
   end Status;

   function Artifact
     (Command : String;
      Name    : String;
      Value   : String) return String is
   begin
      return "{""schema_version"":"
        & Devcert_Core.Json_Schema_Version
        & ",""status"":""success"",""command"":"""
        & Escape (Command)
        & ""","""
        & Escape (Name)
        & """:"""
        & Escape (Value)
        & """}";
   end Artifact;
end Devcert_JSON;
