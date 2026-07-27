# Platform Validation Evidence

Records of host trust-store validation runs, in the form required by
[platform_validation.md](platform_validation.md). Those runs mutate a real
trust store and need administrator rights, so they are performed by hand and
recorded here; the automated suite never touches a host store.

A platform with no entry below has not been validated. That is the honest
reading of an absent row, and it is the reason this file lists what has *not*
been run as plainly as what has.

## Linux System Store

| | |
| --- | --- |
| Date | 2026-07-27 |
| Operating system | TUXEDO OS 24.04.4 LTS, a Kubuntu derivative (`noble`) |
| Kernel | Linux 6.17.0-122035-tuxedo |
| Backend | `update-ca-certificates` (`trust` also present, but lower in precedence) |
| devcert commit | `5bfdb5f` |
| cryptolib commit | `dc9331b` |
| Command | `DEVCERT_RUN_PLATFORM_TRUST_TESTS=1 devcert_tools platform-check linux-system` |
| Result | Passed: the root certificate was installed into the host trust store and removed again |

Run by the maintainer, who holds the administrator rights the host store
requires. Independently confirmed afterwards by inspection of the host store:
no `devcert-*.crt` remains under `/usr/local/share/ca-certificates/`, and no
devcert anchor under `/etc/ssl/certs/`, so the removal completed rather than
merely reporting success.

"Linux" is not one target. The host is a Kubuntu derivative, so this validates
the Debian and Ubuntu family and the `update-ca-certificates` backend, which
devcert prefers when it is present. The other two Linux backends are untouched
by it: `update-ca-trust`, as used by Fedora and RHEL, and `trust`, as used by
Arch. Each needs its own run on a host that has it.

Not captured for this run: the command transcript, the before/after listing as
seen at the time, and the SHA-256 fingerprint of the root CA. `platform-check`
creates its CA root under the host's temporary directory and deletes it on the
way out, so the fingerprint is gone with it. A future run should keep the
transcript, which carries the fingerprint in the install and removal lines.

## macOS System Store

Not validated.

The keychain adapter could not be reached before `5bfdb5f`: the host was
detected by comparing `OSTYPE` to `darwin`, and `OSTYPE` is a shell variable a
spawned process does not inherit, so every macOS was treated as a Linux. The
adapter is on the default path there now and has never been executed on a Mac.
The CI matrix does not close this: it builds and runs the suite on macOS, but
skips every assertion that would mutate the system store. What closes it is a
run of `devcert_tools platform-check macos-system` on a Mac, recorded here.

## Windows System Store

Not validated.

`certutil` is reached through the same live command adapter as macOS. CI builds
and runs the suite on Windows and skips the mutating assertions there too.

## NSS And Java Stores

Not validated on any platform. The Java adapter has been smoke-tested against a
temporary keystore through `DEVCERT_JAVA_KEYSTORE`, which is not the same as a
run against a real store; see [trust_stores.md](trust_stores.md).
