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

* `DEVCERT_CAROOT` — CA root directory
* `DEVCERT_HOME` — CA root directory, consulted only when `DEVCERT_CAROOT` is
  unset
* `DEVCERT_TRUST_STORES` — default trust-store selection
* `DEVCERT_LOCALE` — locale for human output
* `DEVCERT_CATALOG` — message catalog file
* `DEVCERT_LINUX_TRUST_DIR` — isolated Linux anchor directory, see
  [trust_stores.md](trust_stores.md)
* `DEVCERT_NSS_DB` — NSS database directory
* `DEVCERT_JAVA_KEYSTORE` — Java keystore file

With none of the CA root variables set, the CA root is
`$HOME/.local/share/devcert`, or the `%USERPROFILE%` equivalent.

`NO_COLOR` suppresses styling under `--color=auto`; `LC_ALL`, `LC_MESSAGES`,
and `LANG` supply the locale when `DEVCERT_LOCALE` is unset.

`install` and `uninstall` select trust stores either positionally or by option,
and both accept a comma-separated list:

```text
devcert install system
devcert install --trust-store system,nss,java
```

Supported names are `system`, `nss`, and `java`; platform-specific aliases such
as `linux`, `macos`, and `windows` are also accepted by the current adapter
layer.

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

## Diagnosing Failures

`devcert doctor` is the diagnostic entry point. It reports the state of the CA
root — missing, incomplete, unusable material, or unsafe permissions — and
exits with the CA state code when the CA cannot be used.

What the non-zero exits usually mean:

* `2` usage error — an unknown command or option, a missing option value, a
  repeated option, or bare identity arguments without the `cert` command. The
  diagnostic names the offending token.
* `3` CA state error — run `doctor`. A CA root whose permissions have been
  loosened, or whose certificate and key no longer match, reports here.
* `4` certificate request error — an identity that is not a DNS name, IPv4 or
  IPv6 address, or email address; too many identities; or an option
  combination the profile rejects, such as `--key-file` with `--csr`.
* `5` cryptographic error — the operation reached `cryptolib` and failed there.
* `6` trust-store error — see the per-store states in the command output.
  `tool-missing` means the platform tool is absent: `certutil` for NSS,
  `keytool` for Java, `security` on macOS. `permission-required` means the
  store needs elevated privileges; rerun with the privileges the platform
  expects.
* `8` partial success — some selected stores succeeded and others did not. The
  output lists every store with its own state.
Codes `7` and `10` are reserved and are not produced by the current runtime.
A missing or malformed catalog does not fail: human output falls back to bare
message identifiers so that the real error can still be reported. See
[installation.md](installation.md) for where the catalog is expected.
