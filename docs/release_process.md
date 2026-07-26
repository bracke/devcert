# Release Process

Release candidates are produced by the Ada tooling crate:

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

Release artifacts are staged below `dist/` and exclude local build products and
local Alire state. `dist` writes a deterministic `SHA256SUMS` manifest for the
staged source tree. Checksum generation is implemented in Ada and uses
`cryptolib`.
