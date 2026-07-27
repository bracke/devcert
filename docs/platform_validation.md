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

## macOS System Store

The macOS CI job packages its own build, so a Mac does not have to build the
whole workspace to be validated. Take it from a run of the `ci` workflow:

```text
gh run download --name devcert-macos-x86_64
tar -xzf devcert-macos-x86_64.tar.gz
cd devcert-macos-x86_64
```

The archive carries `bin/devcert` with the `share/` tree it reads, plus
`devcert_tools` and `devcert.gpr`, which is how the check finds the root. macOS
may quarantine a downloaded binary; `xattr -dr com.apple.quarantine .` clears
it. The build is x86_64, because `gnat_native` has no aarch64-darwin binary, so
on Apple silicon it runs under Rosetta.

Then, on a disposable account or machine:

```text
DEVCERT_RUN_PLATFORM_TRUST_TESTS=1 \
  devcert_tools platform-check macos-system
```

The same sequence as the Linux target, against the keychain through the
`security` command. Adding the root certificate to the system keychain asks for
authentication, so run it where that can be answered.

Each target refuses to run anywhere but on its own host: the system store is
whatever the machine underfoot has, so running the macOS check on Linux would
mutate the Linux store and record the result as macOS. The host is taken from
`hostkit`, which no environment variable can talk into the wrong answer.

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
