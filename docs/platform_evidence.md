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
| Linux system under SELinux enforcing | yes, Fedora 44 VM, `update-ca-trust` |
| NSS, including Firefox profiles | yes, on Linux |
| NSS in a Flatpak Firefox profile | yes, Flathub Firefox 153 on this host |
| NSS in a snap-confined Firefox profile | yes, Ubuntu 24.04 VM, Firefox snap 153 |
| NSS in a macOS Firefox profile | yes, `macos-15-intel` runner |
| NSS in a Windows Firefox profile | yes, `windows-latest` runner, with NSS's certutil |
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

An eighth came out of the Flatpak run. devcert searched
`~/.var/app/org.mozilla.firefox/.mozilla/firefox`; the Flathub Firefox keeps its
profiles under `config/mozilla/firefox`, because a flatpak hands the application
its own `XDG_CONFIG_HOME` and Firefox 153 writes there rather than into the
`~/.mozilla` the sandbox also offers it. The searched directory did not exist at
all, so a Flatpak Firefox was invisible and an anchor meant for it went nowhere
-- which is the failure the snap path had been added to fix, one directory over.
Validated against a profile Flathub Firefox created, with `certutil` reading the
database afterwards: installed into both profiles, then removed from both.

A ninth came out of the Windows run, and it was the tool rather than the path.
Windows ships a `certutil.exe` of its own in `System32` -- a different program
that happens to share NSS's name -- and it is the only one a runner has. devcert
asked `Locate ("certutil")` for both stores, which is right for the machine
`Root` store and was never right for NSS, so NSS was reported available on any
Windows at all and then handed arguments Microsoft's tool cannot read. What came
back was `nss=error: failed to install NSS trust anchor devcert-32c31d07... in
C:\Users\...\Profiles\ytycz9xq.default-release`, which names a store, a profile
and an anchor and is wrong about all three. It now asks which program answered, and
walks the rest of `PATH` when the first one is not NSS's -- a host with NSS
installed and its directory appended has both, Microsoft's in front. With NSS's
certutil present the anchor reaches the profile whichever order `PATH` is in,
and without it the answer is `nss=tool-missing: certutil is not installed`
rather than a fabricated refusal. Profile discovery on Windows was never the
problem: the runner found the profile under
`AppData\Roaming\Mozilla\Firefox\Profiles` on the first try.

## Not Validated

What devcert itself has not established, whatever the stores can do:

* **The 33 message translations.** Written for this catalogue and reviewed by no
  native speaker.
