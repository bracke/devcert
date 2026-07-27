# devcert

`devcert` is an Ada binary crate for managing a local development certificate
authority, issuing development certificates, and installing or removing trust
anchors from supported local trust stores.

## Installation

Build from the repository root:

```text
alr build
```

The executable is written to `bin/devcert`.

## Quick Start

Trust a local CA, then issue a certificate for `localhost`:

```text
$ bin/devcert install
[*] system=installed: installed linux trust anchor for b3:bc:48:fb:...:89:ea

$ bin/devcert cert localhost 127.0.0.1
[*] certificate issued for localhost
```

`install` creates the CA if it does not exist yet and adds its root certificate
to the selected trust stores; `cert` writes the certificate and its private key
below the CA root's `issued/` directory:

```text
$HOME/.local/share/devcert/
├── rootCA.pem
├── rootCA-key.pem
├── ca-metadata.txt
└── issued/
    ├── localhost.pem
    └── localhost-key.pem
```

Point the development server at `issued/localhost.pem` and
`issued/localhost-key.pem`. Browsers on the machine accept them because the
root certificate is now trusted.

Check what devcert believes about its own state, and undo the trust when done:

```text
$ bin/devcert caroot
[*] /home/you/.local/share/devcert

$ bin/devcert doctor
[*] doctor: ca complete

$ bin/devcert uninstall
[*] system=installed: removed linux trust anchor for b3:bc:48:fb:...:89:ea
```

The `[*]` marker comes from the terminal styling layer. `--plain`, `--json`,
`--color=never`, and `NO_COLOR` all drop it.

Every command also speaks JSON, with a stable envelope:

```text
$ bin/devcert --json doctor
{"schema_version":1,"status":"success","command":"doctor","message":"doctor: ca complete"}
```

## Common Commands

Runtime command groups are `help`, `version`, `install`, `uninstall`,
`caroot`, `cert`, `inspect`, and `doctor`. `bin/devcert --help` lists the
options; [docs/cli.md](docs/cli.md) is the full reference.

Certificates are not limited to `localhost`: `cert` accepts several DNS names,
IPv4 and IPv6 addresses, and email identities in one invocation, and can issue
client or S/MIME profiles, sign a CSR, or emit a PKCS#12 bundle.

Repository checks are provided by the Ada tooling crate:

```text
cd devcert_tools
alr build
bin/devcert_tools release-check
```

## Supported Platforms

The supported trust-store targets are Linux system stores, NSS, Java, macOS,
and Windows. Platform behavior is documented in
[docs/trust_stores.md](docs/trust_stores.md).

## Documentation

Detailed documentation:

* [Installation](docs/installation.md)
* [CLI](docs/cli.md)
* [Coding style](docs/coding_style.md)
* [CA lifecycle](docs/ca_lifecycle.md)
* [Certificate policies](docs/certificate_policies.md)
* [Trust-store architecture](docs/trust_stores.md)
* [cryptolib contract](docs/cryptolib_contract.md)
* [Output](docs/output.md)
* [Localization](docs/localization.md)
* [JSON contract](docs/json_contract.md)
* [Security model](docs/security.md)
* [Testing](docs/testing.md)
* [Release process](docs/release_process.md)
* [mkcert parity](docs/mkcert_parity.md)
* [Platform validation](docs/platform_validation.md) and its
  [evidence](docs/platform_evidence.md)
* [Final acceptance](docs/final_acceptance.md)
