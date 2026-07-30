# Platform Validation Evidence

The trust stores devcert installs into belong to the `truststores` crate, and so
do the records of validating them against real hosts. The transcripts -- Linux
with its three backends, NSS and Firefox, the macOS keychain, the Windows
machine `Root` store, and Java -- are in that crate's
`docs/platform_evidence.md`.

Summarised, as of 2026-07-29:

| Store | Validated |
| --- | --- |
| Linux system (`update-ca-certificates`, `update-ca-trust`) | yes |
| Linux system (`trust anchor`) | yes, Ubuntu 24.04 with p11-kit and no `ca-certificates` |
| NSS, including Firefox profiles | yes, on Linux |
| macOS keychain | yes, macOS 14.8.7 |
| Windows machine `Root` | yes, and the refusal an ordinary user gets |
| Java keystore | yes, both the configured and the JDK's own |

Six features were found never to have worked in the course of those runs, each
behind a test that had checked the shape of an answer rather than asking the
thing that would have to accept it: the NSS store, the PKCS#12 MAC, the
fingerprint, the macOS denial report, Windows removal, and the Java
verification.

A seventh came out of the `trust anchor` run. p11-kit stores the anchor and then
runs a compat extractor to rewrite the bundle files; Debian and Ubuntu package
no such extractor, so `trust` exits 2 having done exactly what was asked. devcert
believed that exit code and reported `system=error` for a certificate the host
had just begun to trust -- and reported the same on the way out, for a removal
that had happened. Underneath it, `System_Anchors` decided a host trusted nothing
because Ubuntu ships `/etc/ssl/certs/ca-certificates.crt` as a zero-length file
and the code tested whether the path existed rather than whether it held
anything. Both now ask p11-kit, which answers on that host whatever the exit
code says, and the store decides. This is the same lesson as the other six: the
tool's word is not the store's state.

## Not Validated

What devcert itself has not established, whatever the stores can do:

* **Firefox on macOS and Windows.** Profile discovery was validated on Linux;
  the profile root differs on the other two and only the Linux one has been
  walked.
* **Firefox under Snap or Flatpak.** Both roots are searched now, and the suite
  proves the snap path is found by relocating the home directory -- but no run
  has installed an anchor into a real snap-confined profile and watched Firefox
  accept it.
* **SELinux enforcing.** The Fedora container ran permissive; enforcing needs a
  virtual machine, because a container shares the host kernel and this host runs
  AppArmor.
* **The 34 message translations.** Written for this catalogue and reviewed by no
  native speaker.
