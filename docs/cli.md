# CLI

The executable name is `devcert`.

Supported top-level options:

* `--help`
* `--version`
* `--color=auto|always|never`
* `--plain`
* `--json`
* `--locale LOCALE`
* `--catalog FILE`
* `--ca-root DIRECTORY`

Required command groups:

* `help`
* `version`
* `install`
* `uninstall`
* `caroot`
* `cert`
* `inspect`
* `doctor`

`devcert cert NAME` is the certificate generation entry point. Bare identity
arguments without the `cert` command are rejected. Multiple DNS, IPv4, IPv6,
and email identities are parsed by the certificate request policy before any
cryptographic operation runs.

Certificate options:

* `--server`
* `--client`
* `--email`
* `--csr FILE`
* `--cert-file FILE`
* `--key-file FILE`
* `--pkcs12`
* `--p12-file FILE`
* `--p12-password-file FILE`
* `--p12-password-stdin`

Server, client, S/MIME, DNS SAN, IPv4 SAN, and IPv6 SAN profiles are issued
through `cryptolib`. CSR signing verifies the CSR signature, extracts the public
key and subject common name, and delegates certificate signing to `cryptolib`.
PKCS#12 generation is also delegated to `cryptolib`.

By default `cert` writes the issued certificate and private key below the active
CA root's `issued/` directory. Use `--cert-file` and `--key-file` to select
explicit output paths. CSR signing supports `--cert-file`; it rejects
`--key-file` because no private key is generated from a CSR.

When `--pkcs12` is combined with custom certificate or key paths, the bundle is
generated from the certificate and private key just issued by `cryptolib`; it
does not depend on the default `issued/` filenames also existing.

Command-line options override environment variables. Environment variables
override platform defaults.

Supported environment variables:

* `DEVCERT_CAROOT`
* `DEVCERT_TRUST_STORES`
* `DEVCERT_LOCALE`
* `DEVCERT_CATALOG`

`install` and `uninstall` accept `--trust-store NAME`. Supported names are
`system`, `nss`, and `java`; platform-specific aliases such as `linux`,
`macos`, and `windows` are also accepted by the current adapter layer.

Human-readable text is routed through the localization catalog. JSON output
contains stable `schema_version`, `status`, and `command` fields.

Stable exit codes:

* `0` success
* `1` general failure
* `2` usage error
* `3` CA state error
* `4` certificate request error
* `5` cryptographic error
* `6` trust-store error
* `7` permission error
* `8` partial success
* `9` unsupported platform or feature
* `10` localization error
