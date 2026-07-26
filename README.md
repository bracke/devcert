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

```text
bin/devcert --help
bin/devcert version
bin/devcert --json version
```

## Common Commands

Runtime command groups are `help`, `version`, `install`, `uninstall`,
`caroot`, `cert`, `inspect`, and `doctor`.

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
* [Final acceptance](docs/final_acceptance.md)
