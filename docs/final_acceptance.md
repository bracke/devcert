<!-- generated:devcert-acceptance -->
# Final Acceptance

This file records the normative acceptance gates for `devcert`.

Runtime:

* Alire binary crate builds
* executable is named `devcert`
* runtime implementations are complete

Cryptography:

* cryptographic operations are delegated to `cryptolib`
* facts that differ because the host differs -- which host this is, whether a
  path is readable by others, restricting one to its owner, and the replacing
  rename an atomic write ends in -- are delegated to `hostkit`, never sniffed
  from the environment and never spawned as a POSIX tool
* certificate profiles, CSR signing, and PKCS#12 generation are supported
  through `CryptoLib.Certificates`

Trust stores:

* Linux, NSS, Java, macOS, and Windows adapters are represented by deterministic
  fingerprint-authoritative adapter plans

Output:

* human-readable text is localized through `messages`, backed by `i18n`
* terminal styling uses `terminal_styles`
* JSON output is deterministic and schema versioned

Security:

* atomic writes and safe permissions are enforced
* secrets are excluded from logs and JSON
* CA private keys are never installed into trust stores

Testing:

* AUnit, integration, regression, and adapter tests pass

Tooling:

* repository tooling is Ada-only and located in `devcert_tools`
* reusable mechanics are delegated to `project_tools`
* release checksums are generated through `cryptolib`

Documentation:

* project, platform, security, release, and mkcert parity docs are complete
