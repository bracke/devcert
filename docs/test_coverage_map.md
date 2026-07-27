# Test Coverage Map

This map records the public devcert surface covered by the AUnit suite.

## CLI And Dispatch

Packages: `Devcert.CLI`, `Devcert.Commands*`.

Coverage: executable parser errors, no-mutation failures, certificate workflow,
and install workflow.

## Context And Results

Packages: `Devcert.Context`, `Devcert.Results`, `Devcert.Errors`.

Coverage: architecture surface and stable status checks.

## CA Lifecycle

Packages: `Devcert.CA_Store`, `Devcert_State`, `Devcert.Locks`.

Coverage: missing, incomplete, invalid metadata/material, key mismatch,
permissions, and writer locking.

## Certificate Policy

Packages: `Devcert.Certificate_Requests`, `Devcert.Certificate_Policies`,
`Devcert.Identities`.

Coverage: DNS, IP, email, duplicates, limits, output names, and profile
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

An opt-in Linux system mutation check is provided by
`devcert_tools platform-check linux-system` and `macos-system`, each of which
refuses to run on any host but its own. It is not part of the default
release gate because it mutates the host trust store.

Remaining coverage requiring external environments:

* macOS Keychain mutation
* Windows current-user certificate store mutation
* distribution-specific Linux CA store mutation evidence
* real NSS SQL database mutation
* real Java keystore mutation
