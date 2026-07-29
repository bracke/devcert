# Release Process

The release gate is `check_devcert`, as in the sibling crates:

```text
cd check_devcert
alr build
bin/check_devcert
```

It verifies the Alire-selected toolchain, the documentation a release depends
on, builds devcert and its suite, runs the suite, and then runs the
devcert-specific checks. Those live in the tooling crate, because they are
about devcert rather than about releasing:

```text
cd devcert_tools
alr build
bin/devcert_tools release-check
bin/devcert_tools dist
```

The release checklist requires:

* runtime build
* runtime tests
* tooling build
* tooling tests
* test build
* documentation checks
* style checks
* manifest checks
* catalog checks
* tree checks
* generated-artifact checks
* mkcert parity checks

The `tooling-tests` command is part of the Ada tooling executable and verifies
project-specific release mechanics such as manifest pin stripping and staged
manifest validation.

## Publish order

devcert is the last of five. Each crate depends on the ones above it, and Alire
resolves a published crate against published dependencies, so publishing devcert
first would publish something nobody can build:

```text
tarlib        (packaging tool only; no devcert dependency)
hostkit       what differs because the host differs
cryptolib     certificates, keys, PEM
truststores   the trust stores a host keeps -- depends on hostkit and cryptolib
devcert       depends on all but tarlib
```

The workspace builds through path pins, which hide this: everything resolves
locally whatever order it is in. A published crate has no pins -- the release
gate refuses a manifest that keeps them -- so the order only matters at the
point where getting it wrong is hardest to undo.

Release artifacts are staged below `dist/` and exclude local build products and
local Alire state. `dist` writes a deterministic `SHA256SUMS` manifest for the
staged source tree. Checksum generation is implemented in Ada and uses
`cryptolib`.
