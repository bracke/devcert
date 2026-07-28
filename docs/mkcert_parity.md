<!-- generated:devcert-parity -->
# mkcert Parity Matrix

What each column asserts:

* **Implemented** -- the feature exists in the runtime.
* **Suite** -- the automated AUnit suite exercises it. For a trust store that
  means its target selection, plan, fingerprint handling and state reporting;
  only the Linux anchor-directory backend is actually mutated, against a
  directory of the suite's own.
* **Host validation** -- it has been run against the real thing on a host, with
  the run recorded in [platform_evidence.md](platform_evidence.md). `Pending`
  means no such run exists; `Partial` means one was made and left something
  unexercised, which the evidence names; `n/a` marks a feature that does not
  touch a host trust store.
* **Documented** -- covered by the documentation.

| Feature | Implemented | Suite | Host validation | Documented |
| --- | --- | --- | --- | --- |
| CA root resolution | Implemented | Tested | n/a | Yes |
| CA creation | Implemented | Tested | n/a | Yes |
| CAROOT reporting | Implemented | Tested | n/a | Yes |
| issue localhost certificate | Implemented | Tested | n/a | Yes |
| issue DNS SAN certificate | Implemented | Tested | n/a | Yes |
| issue IP SAN certificate | Implemented | Tested | n/a | Yes |
| custom certificate output paths | Implemented | Tested | n/a | Yes |
| client certificate profile | Implemented | Tested | n/a | Yes |
| S/MIME certificate profile | Implemented | Tested | n/a | Yes |
| sign CSR | Implemented | Tested | n/a | Yes |
| PKCS#12 bundle | Implemented | Tested | n/a | Yes |
| install local CA | Implemented | Tested | Linux | Yes |
| uninstall local CA | Implemented | Tested | Linux | Yes |
| Linux system trust | Implemented | Tested | Linux | Yes |
| NSS trust | Implemented | Tested | Linux | Yes |
| Firefox trust | Implemented | Tested | Linux | Yes |
| Java trust | Implemented | Tested | Container | Yes |
| macOS trust | Implemented | Tested | macOS | Yes |
| Windows trust | Implemented | Tested | Partial | Yes |
| fingerprint-authoritative removal | Implemented | Tested | Linux | Yes |
| JSON output | Implemented | Tested | n/a | Yes |
| localized human output | Implemented | Tested | n/a | Yes |

`Linux` means the Debian and Ubuntu family through `update-ca-certificates`.
The other two Linux backends, `update-ca-trust` and `trust`, have no run of
their own; see the evidence file.

Every listed parity row must remain implemented, covered by the suite, and
documented for the release gate to pass. Host validation is recorded, not
gated: a run needs administrator rights on the platform in question, so it
cannot be part of any automated check.
