# Testing

The automated test suite lives in `devcert_tests` and uses AUnit. Runtime code
does not depend on AUnit.

The suite is split by area, one package each: `Cli_Tests`, `Output_Tests`,
`Ca_Tests`, `Certificate_Tests` and `Trust_Tests`, with `Support` holding what
they share -- a disposable CA root, and whether this host's system store is one
a test may mutate. A new test goes with its area rather than onto the end of
one file.

The public-package coverage map is maintained in
`docs/test_coverage_map.md`.

`devcert_tools test-registration-check` fails if a test type is declared and
never added to the suite. Splitting the suite by area made that worth checking:
such a test compiles, never runs, and nothing says so.

The default suite currently contains 32 deterministic tests. Categories covered
by automated tests include:

* CLI contracts through stable exit-code, JSON envelope, duplicate option,
  CA-root and trust-store precedence, certificate option combinations, and
  no-mutation invalid invocation tests
* JSON control-character escaping, deterministic field ordering, output mode
  routing, terminal styling selection, and ANSI exclusion in JSON/plain output
* context and architecture package surface
* certificate requests, request cardinality limits, output names, and identity
  validation
* CA store, metadata, invalid material states, certificate/key mismatch,
  writer locking, permissions, and secure writes
* cryptolib adapter boundaries
* CSR and PKCS#12 error/status behavior
* end-to-end install, certificate issuance, inspection, doctor, and uninstall
  workflow against an isolated trust directory
* trust-store target parsing, logical selection policy, fingerprint-derived
  aliases, aggregate edge states, and isolated Linux trust-store mutation
* devcert localization policy, required catalog identifiers, locale/catalog
  precedence, malformed catalog fallback, and JSON stability
* security output invariants
* deterministic clock behavior

Repository paths are resolved through `Devcert_Test_Suite.Paths`, which derives
the repository root from the location of the suite executable. The suite
therefore produces the same result from any working directory, and is run as
`devcert_tests/bin/devcert_tests`.

Tests use temporary CA roots under the host's scratch directory --
`Devcert_Test_Suite.Paths.Scratch`, which asks `hostkit` rather than assuming
`/tmp`, a path Windows does not have -- and must not operate on the user's real
CA directory. Clock-dependent tests use `Devcert.Clock.Set_Test_Time` and
reset the clock after use. Trust-store tests exercise selection, planning, and
Linux install/remove mutation through an isolated anchor directory under `/tmp`
without mutating host trust stores.

Tests that mutate the system trust store run only where that store is a
directory of the suite's own, through `DEVCERT_LINUX_TRUST_DIR`. On macOS and
Windows `system` means the host's real keychain or certificate store, so the
suite skips those assertions rather than touching it; the same applies to
permission assertions on hosts whose directories carry no mode bits.

Host platform mutation tests remain separated from the default suite. They
require disposable host profiles, containers, virtual machines, or
administrator-controlled environments.
