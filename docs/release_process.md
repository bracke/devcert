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
* tooling build
* test build
* documentation checks
* style checks
* manifest checks
* catalog checks
* tree checks
* generated-artifact checks
* mkcert parity checks

Release artifacts are staged below `dist/` and exclude local build products and
local Alire state.
