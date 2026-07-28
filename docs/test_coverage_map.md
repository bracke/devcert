# Test Coverage Map

This map records the public devcert surface covered by the AUnit suite.

## CLI And Dispatch

Packages: `Devcert.CLI`, `Devcert.Commands*`.

Coverage: executable parser errors, no-mutation failures, certificate workflow,
install workflow, `caroot` reporting a root without creating it, and the
refusal of `--key-file` with `--csr` -- asserted through the diagnostic rather
than the exit code, because an incomplete CSR fails either way.

Every command group is exercised through the executable rather than by calling
its package: `Devcert.CLI`, `Devcert.Commands.*` and `Devcert.Output.*` have no
unit-level tests.

## Context And Results

Packages: `Devcert.Context`, `Devcert.Results`, `Devcert.Errors`.

Coverage: architecture surface and stable status checks.

## CA Lifecycle

Packages: `Devcert.CA_Store`, `Devcert_State`, `Devcert.Locks`.

Coverage: missing, incomplete, invalid metadata/material, key mismatch,
permissions, and writer locking.

## Chain Verification

Package: `Devcert_Crypto`, through `openssl`.

Coverage: an issued leaf verifies against the CA that signed it and not against
one that did not, and the fingerprint devcert reports is the one `openssl`
reports for the same certificate. Skipped aloud where the host has no `openssl`.

## Certificate Policy

Packages: `Devcert.Certificate_Requests`, `Devcert.Certificate_Policies`,
`Devcert.Identities`.

Coverage: a PKCS#12 bundle read back with the password it was built with, and
refused with another -- through `openssl` where the host has it, skipped aloud
where it does not. DNS, IP, email, duplicates, limits, output names, and profile
selection.

## Crypto Adapter

Package: `Devcert_Crypto`.

Coverage: CA creation, issuance, CSR error mapping, PKCS#12, and
key/certificate matching.

## Trust Stores

Packages: `Devcert_Trust_Stores`, `Devcert.Trust_Stores*`.

Coverage: selection, aliases, aggregate states, and isolated Linux mutation.

## Output

Packages: `Devcert.Output*`, `Devcert_JSON`.

Coverage: JSON schema, escaping, field stability, plain/terminal routing, and
ANSI exclusion.

## Localization

Packages: `Devcert_Messages`, `Devcert.Locale`.

Coverage: required IDs, locale precedence, catalog precedence, and malformed
catalog fallback.

## Filesystem Safety

Package: `Devcert_Secure_Files`.

Coverage: atomic text/raw writes, overwrite behavior, permissions, temp
cleanup, and owner-only access. The exposure assertions run only where the host
expresses the question in mode bits, which the suite asks the host rather than
assumes.

## External Platform Coverage

Opt-in system mutation checks are provided by `devcert_tools platform-check`
for `linux-system`, `macos-system` and `windows-system`, each of which refuses
to run on any host but its own. They are not part of the default release gate
because they mutate the host trust store.

Remaining coverage requiring external environments:

* macOS Keychain mutation
* Windows current-user certificate store mutation
* distribution-specific Linux CA store mutation evidence
* real NSS SQL database mutation, shared and per Firefox profile
* real Java keystore mutation
