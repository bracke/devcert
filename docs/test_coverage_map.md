# Test Coverage Map

This map records the public devcert surface covered by the AUnit suite.

| Area | Public Packages | Current Coverage |
| --- | --- | --- |
| CLI and dispatch | `Devcert.CLI`, `Devcert.Commands*` | executable parser errors, no-mutation failures, cert workflow, install workflow |
| Context and results | `Devcert.Context`, `Devcert.Results`, `Devcert.Errors` | architecture surface and stable status checks |
| CA lifecycle | `Devcert.CA_Store`, `Devcert_State`, `Devcert.Locks` | missing, incomplete, invalid metadata/material, key mismatch, permissions, writer lock |
| Certificate policy | `Devcert.Certificate_Requests`, `Devcert.Certificate_Policies`, `Devcert.Identities` | DNS, IP, email, duplicates, limits, output names, profile selection |
| Crypto adapter | `Devcert_Crypto` | CA creation, issuance, CSR error mapping, PKCS#12, key/certificate match |
| Trust stores | `Devcert_Trust_Stores`, `Devcert.Trust_Stores*` | selection, aliases, aggregate states, isolated Linux mutation |
| Output | `Devcert.Output*`, `Devcert_JSON` | JSON schema, escaping, field stability, plain/terminal routing, ANSI exclusion |
| Localization | `Devcert_Messages`, `Devcert.Locale` | required IDs, locale precedence, catalog precedence, malformed catalog fallback |
| Filesystem safety | `Devcert_Secure_Files` | atomic text/raw writes, overwrite behavior, permissions, temp cleanup |

Remaining coverage requiring external environments:

* macOS Keychain mutation
* Windows current-user certificate store mutation
* distribution-specific Linux CA store mutation
* real NSS SQL database mutation
* real Java keystore mutation
