# Platform Validation

Native trust-store mutation tests require disposable systems or user profiles.
They are intentionally separate from the default AUnit suite.

Completed runs are recorded in
[platform_evidence.md](platform_evidence.md), which also states which platforms
have not been validated.

## Required Evidence

For each platform run, record:

* operating system and version;
* devcert commit;
* cryptolib commit;
* command transcript;
* before/after trust-store state;
* SHA-256 fingerprint of the devcert root CA;
* uninstall verification showing the fingerprint is absent.

## Linux System Store

Run in a disposable container or virtual machine for each supported backend:

```text
DEVCERT_RUN_PLATFORM_TRUST_TESTS=1 \
  devcert_tools platform-check linux-system
```

The command creates a temporary CA root, installs it into the detected Linux
system trust backend, validates the CA state, uninstalls the root certificate,
and removes the temporary CA root. It is opt-in because it mutates the host
trust store and may require elevated privileges.

Validate `update-ca-certificates`, `update-ca-trust`, and `trust anchor`
backends where available.

## NSS

Use a disposable NSS SQL database:

```text
DEVCERT_NSS_DB=/tmp/devcert-nssdb \
  devcert --ca-root /tmp/devcert-platform-nss install --trust-store nss
DEVCERT_NSS_DB=/tmp/devcert-nssdb \
  devcert --ca-root /tmp/devcert-platform-nss uninstall --trust-store nss
```

Verify the fingerprint with `certutil -L -d sql:/tmp/devcert-nssdb -a`.

## Java

Use a temporary keystore:

```text
DEVCERT_JAVA_KEYSTORE=/tmp/devcert-cacerts \
  devcert --ca-root /tmp/devcert-platform-java install --trust-store java
DEVCERT_JAVA_KEYSTORE=/tmp/devcert-cacerts \
  devcert --ca-root /tmp/devcert-platform-java uninstall --trust-store java
```

Verify with `keytool -list -rfc`.

## macOS

Run from a disposable macOS user or VM:

```text
devcert --ca-root /tmp/devcert-platform-macos install --trust-store system
devcert --ca-root /tmp/devcert-platform-macos uninstall --trust-store system
```

Verify the fingerprint with `security find-certificate` or equivalent
Keychain inspection.

## Windows

Run from a disposable Windows user profile or VM:

```text
devcert --ca-root %TEMP%\devcert-platform-windows install --trust-store system
devcert --ca-root %TEMP%\devcert-platform-windows uninstall --trust-store system
```

Verify the current-user root store before and after removal with `certutil`.
