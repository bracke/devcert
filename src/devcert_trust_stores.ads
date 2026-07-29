with Truststores;

--  The trust stores devcert installs into live in their own crate now: what a
--  host keeps its certificate authorities in, and how a program is allowed to
--  touch them, is useful to any program that has to verify a chain itself --
--  and none of it is about devcert.
--
--  This name stays so the commands read as they did. Devcert.Trust_Setup is
--  what tells the crate about devcert's own environment variables.
package Devcert_Trust_Stores renames Truststores;
