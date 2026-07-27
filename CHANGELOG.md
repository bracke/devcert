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
* A trust store that fails for want of privileges reports the permission exit
  code rather than the general trust-store one. The aggregate state flattened
  every failure into an error, so the commonest failure of all -- a system
  store wanting elevated privileges -- was indistinguishable from an unusable
  one. Exit code `10` is retired; nothing produced it and nothing should.
* The mode read behind `doctor`'s expected-mode reporting falls back to BSD
  `stat -f %Lp` where GNU `stat -c %a` is rejected, so it answers on macOS
  instead of silently reporting nothing.
* The test suite writes below the host's scratch directory rather than a
  hardcoded `/tmp`.
* Owner-only permissions are applied through `Hostkit.Fs.Make_Private` rather
  than by spawning `chmod`, so a CA root, private key, or metadata file is
  restricted even where no `chmod` is on `PATH`. Widening a mode, such as the
  world-readable CA certificate, remains a best-effort spawn.
