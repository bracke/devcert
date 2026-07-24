# Trust-Store Architecture

Trust-store support is implemented through platform adapters with
fingerprint-authoritative installation and removal.

Trust targets can be selected explicitly:

```text
devcert install linux
devcert install java
devcert install nss
devcert uninstall java
```

## Linux

Supported mechanisms include distribution system CA stores where available.
On systems with `update-ca-certificates`, installation writes a fingerprinted
certificate file below `/usr/local/share/ca-certificates/` and runs
`update-ca-certificates --fresh`. Removal deletes the matching fingerprinted
file and reruns the update command. Privilege escalation is expected when
writing to system trust locations.

## macOS

The adapter uses the system keychain trust model and removes only certificates
matching the configured devcert CA fingerprint.

## Windows

The adapter uses the Windows certificate store and removes only matching
fingerprints.

## Java

Java trust stores are updated with `keytool`. By default devcert uses
`keytool -cacerts` with the conventional `changeit` store password. Tests and
custom deployments can set `DEVCERT_JAVA_KEYSTORE` to target a specific
keystore file instead of the system `cacerts` store. Store updates require the
appropriate store password and file permissions.

The Java adapter has been smoke-tested against a temporary keystore using
`DEVCERT_JAVA_KEYSTORE`.

## NSS

NSS trust stores are updated with `certutil`. Set `DEVCERT_NSS_DB` to a specific
NSS database directory; otherwise devcert tries `$HOME/.pki/nssdb`. The adapter
uses SQL database syntax and fingerprint-derived aliases.

## macOS and Windows

macOS uses the `security` command when available. Windows uses `certutil` when
available. Both adapters use fingerprint-derived operations and report missing
platform tools explicitly. They are implemented as live command adapters, but
require their native operating systems for end-to-end mutation tests.
