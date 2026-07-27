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

## Linux System Store: update-ca-trust

| | |
| --- | --- |
| Date | 2026-07-28 |
| Operating systems | `fedora:latest` and `archlinux:latest`, in rootless podman |
| Binary | The `devcert-linux-x86_64` artifact, built on TUXEDO OS |
| devcert commit | `b55545a` plus the two fixes this run produced |
| Result | Passed on both, after two bugs this run found |

Fedora writes the anchor to `/etc/pki/ca-trust/source/anchors/`, Arch to
`/etc/ca-certificates/trust-source/anchors/`; both then run `update-ca-trust`.
On Arch, `trust list` shows the anchor while it is installed and does not once
it is removed. A second removal reports there is nothing to remove and exits 0.

Two bugs, both found here rather than by reasoning:

* The `update-ca-trust` backend hardcoded Fedora's anchor directory, so on Arch
  every install wrote into a directory that does not exist -- and reported it
  as wanting privileges, exit 7, which is a plausible enough answer that it
  could have stood for a long time.
* Removal said `removed ... anchor` and exited 0 when nothing of ours was
  there, including immediately after an install that had failed.

Not covered: the third Linux backend. `trust anchor` is only selected where
neither `update-ca-certificates` nor `update-ca-trust` exists, and Arch -- the
distribution it was meant for -- ships `update-ca-trust` as well, so that path
went unexercised again. Whether any distribution reaches it is an open
question.


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
and runs the suite on Windows and skips the mutating assertions there too. What
closes it is a run of `devcert_tools platform-check windows-system` on Windows,
recorded here.

## NSS Databases

| | |
| --- | --- |
| Date | 2026-07-28 |
| Operating system | TUXEDO OS 24.04.4 LTS, a Kubuntu derivative (`noble`) |
| Kernel | Linux 6.17.0-122035-tuxedo |
| Tool | `certutil`, `libnss3-tools` 2:3.98-1ubuntu0.2 |
| devcert commit | `c8b4ca3` |
| cryptolib commit | `b98e524` |
| Databases | A disposable `HOME`: a shared `.pki/nssdb` and one Firefox |
| | profile, both created with `certutil -N --empty-password` |
| Result | Passed: installed into both, removed from both, and a |
| | second removal was a no-op rather than a failure |

The transcript, in order: `install --trust-store nss` reported
`installed NSS trust anchor devcert-2036333c…` for each database and exited 0;
`certutil -L` listed the anchor in both; `uninstall --trust-store nss` reported
`removed …` for each and exited 0; `certutil -L` then listed it in neither; a
second `uninstall` reported `no NSS trust anchor … in …` for each and still
exited 0.

This run is the reason the CA is P-384. The same sequence against an Ed25519
CA failed at the first step: `certutil` answers `SEC_ERROR_ADDING_CERT` and
refuses to import such a certificate at all, so the NSS store had never been
able to work -- for Firefox or for Chromium -- whatever the adapter did. An
RSA certificate imported into the same database, which is how the key, rather
than the database or the tool, was identified as the cause.

What it does not cover: the databases were disposable ones created for the
run, not the profiles a person browses with, and no browser was launched
against the result. It covers the adapter and the certificate NSS will accept,
not the experience of visiting a site.

## Java Keystores

Not validated. The adapter has been smoke-tested against a temporary keystore
through `DEVCERT_JAVA_KEYSTORE`, which is not a run against a real store.
