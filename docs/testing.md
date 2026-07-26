# Testing

The automated test suite lives in `devcert_tests` and uses AUnit. Runtime code
does not depend on AUnit.

The default suite currently contains 26 deterministic tests. Categories covered
by automated tests include:

* CLI contracts through stable exit-code and JSON envelope tests
* JSON control-character escaping and deterministic field ordering
* context and architecture package surface
* certificate requests, request cardinality limits, output names, and identity
  validation
* CA store, metadata, invalid material states, permissions, and secure writes
* cryptolib adapter boundaries
* CSR and PKCS#12 error/status behavior
* trust-store target parsing, logical selection policy, fingerprint-derived
  aliases, aggregate edge states, and isolated Linux trust-store mutation
* localization and JSON stability
* security output invariants
* deterministic clock behavior

Tests use temporary CA roots under `/tmp` and must not operate on the user's
real CA directory. Clock-dependent tests use `Devcert.Clock.Set_Test_Time` and
reset the clock after use. Trust-store tests exercise selection, planning, and
Linux install/remove mutation through an isolated anchor directory under `/tmp`
without mutating host trust stores.

Host platform mutation tests remain separated from the default suite. They
require disposable host profiles, containers, virtual machines, or
administrator-controlled environments.
