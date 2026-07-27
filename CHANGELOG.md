# Changelog

## 0.1.0-dev

Initial development release.

* Ada 2022 runtime crate with the `devcert` executable.
* AUnit test crate for runtime, integration, and regression coverage.
* Ada tooling crate with style, manifest, catalog, tree, documentation,
  generated artifact, parity, release, and distribution checks.
* Local CA lifecycle, certificate issuance, trust-store planning, localized
  output, stable JSON, and release documentation.
* The message catalog is resolved relative to the executable
  (`<executable-directory>/../share/devcert`) before the working directory, so
  an installed `devcert` is localized from any directory. `DEVCERT_CATALOG` and
  `--catalog` keep precedence.
* The test suite resolves repository paths from its own executable, so it can be
  run from any working directory.
* Host-dependent file facts are asked of `hostkit`: a CA private key or metadata
  file readable by others is reported as unsafe permissions on macOS as well as
  Linux, where the previous `stat -c` probe answered only under GNU coreutils,
  and atomic writes end in a replacing rename instead of a delete followed by a
  rename.
* CI builds and tests on macOS and Windows as well as Linux.
* The host platform is answered by `hostkit` instead of sniffed from `OSTYPE`,
  which is a shell variable a spawned process never inherits: devcert read every
  macOS as a Linux and selected the `update-ca-certificates` backend on a
  machine whose trust store is the keychain.
* An unsafe CA root or `issued/` directory is reported on macOS as well, through
  `Hostkit.Fs.Directory_Accessible_By_Others`.
