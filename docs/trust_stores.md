# Trust-Store Architecture

Trust-store support is implemented through platform adapters with
fingerprint-authoritative installation and removal.

The host platform is taken from `Hostkit.Host.Current`, which each supported
operating system answers for itself. It is not detected from the environment:
`OSTYPE` is a shell variable that a spawned process does not inherit, so a
check for it read every macOS as a Linux and selected the
`update-ca-certificates` backend on a machine whose trust store is the
keychain.

Trust stores are selected by logical store name. Supported logical names are:

* `system`
* `nss`
* `java`

Duplicate names are ignored after normalization and ordering remains
deterministic. Platform aliases such as `linux`, `macos`, and `windows` map to
the logical `system` store.

Trust targets can be selected explicitly:

```text
devcert install system
devcert install java
devcert install --trust-store system,nss,java
devcert uninstall java
```

`DEVCERT_TRUST_STORES` accepts the same comma-separated store syntax. Commands
that affect multiple stores report every selected store. Mixed success returns
the stable partial-success exit code.

Stable trust-store states include `unsupported`, `available`, `installed`,
`not-installed`, `tool-missing`, `permission-required`, `partial`, and `error`.

## Linux

Supported mechanisms include distribution system CA stores where available.
On systems with `update-ca-certificates`, installation writes a fingerprinted
certificate file below `/usr/local/share/ca-certificates/` and runs
`update-ca-certificates --fresh`. Removal deletes the matching fingerprinted
file and reruns the update command. Privilege escalation is expected when
writing to system trust locations.

For deterministic integration tests, `DEVCERT_LINUX_TRUST_DIR` selects an
isolated anchor directory backend. In that mode devcert stages
`devcert-<fingerprint>.crt` below the configured directory, performs no system
refresh command, and still refuses removal unless the staged public certificate
matches the active root certificate.

## macOS

The adapter uses the system keychain trust model and removes only certificates
matching the configured devcert CA fingerprint. The command adapter uses
structured arguments and does not invoke shell pipelines.

## Windows

The adapter uses the Windows certificate store and removes only matching
fingerprints. The command adapter uses structured arguments and does not invoke
shell pipelines.

## Java

Java trust stores are updated with `keytool`. By default devcert uses
`keytool -cacerts` with the conventional `changeit` store password. Tests and
custom deployments can set `DEVCERT_JAVA_KEYSTORE` to target a specific
keystore file instead of the system `cacerts` store. Store updates require the
appropriate store password and file permissions.

The Java adapter has been smoke-tested against a temporary keystore using
`DEVCERT_JAVA_KEYSTORE`.

## NSS

NSS trust stores are updated with `certutil`. The adapter uses SQL database
syntax and fingerprint-derived aliases.

There is no single NSS database. `$HOME/.pki/nssdb` is the shared one Chromium
reads; Firefox reads none of it and keeps a `cert9.db` of its own in every
profile. A certificate installed only into the shared database is therefore
trusted by Chromium and by no Firefox on the machine. devcert acts on all of
them: the shared database, plus each profile directory holding a `cert9.db`
under

```text
$HOME/.mozilla/firefox                                    (Linux)
$HOME/Library/Application Support/Firefox/Profiles        (macOS)
%APPDATA%\Mozilla\Firefox\Profiles                        (Windows)
```

Every database is reported separately, and the store counts as installed only
when all of them took it. Removal stays fingerprint-authoritative per database:
a profile that does not carry the anchor is skipped, and one whose stored
certificate differs is refused rather than overwritten.

`DEVCERT_NSS_DB` names one database instead of all of them, which is what the
platform runs use to stay off real profiles.

Removal is fingerprint-authoritative. Linux file-based backends compare the
stored public certificate with the active CA certificate before deleting a
fingerprint-derived file. Java and NSS adapters read the alias target back from
the store and compare the stored public certificate before deleting the alias.
macOS and Windows deletion commands are invoked with the normalized certificate
fingerprint rather than with a subject or nickname.

## macOS and Windows

macOS uses the `security` command when available. Windows uses `certutil` when
available. Both adapters use fingerprint-derived operations and report missing
platform tools explicitly. They are implemented as live command adapters, but
require their native operating systems for end-to-end mutation tests.

Platform validation commands and required evidence are documented in
`docs/platform_validation.md`.
