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
* `devcert_tools platform-check` gained `macos-system` and `windows-system`
  targets, and each target refuses to run on any host but its own.
* The local CA and the certificates it issues are NIST P-384 with
  ECDSA-SHA384 rather than Ed25519. NSS refuses to import an Ed25519
  certificate -- `certutil` answers `SEC_ERROR_ADDING_CERT` -- so the NSS trust
  store could never have worked, for Firefox or Chromium, whatever the adapter
  did.
* P-384 certificate requests are accepted as well as Ed25519 ones.
* The `update-ca-trust` backend finds the anchor directory rather than assuming
  Fedora's: Arch keeps it under `/etc/ca-certificates`, where every install had
  been failing as though it needed privileges.
* Removing a trust anchor that is not installed says so instead of reporting a
  removal that did not happen.
* The Windows trust store's refusal of an ordinary user is exercised, not
  assumed: `permission-required` and exit 7, from a local account holding one
  privilege and no group memberships. It was the last reporting path in the
  trust stores that had only ever been reasoned about.
* Every Java keystore on the host is installed into, not whichever `keytool`
  came first on PATH. A machine with two JDKs has two stores, and an anchor in
  one is not in the other. Aliases are deduplicated by resolved path, so one
  anchor in one file is reported once.
* Firefox profiles under Snap and Flatpak are found. Each packaging confines
  Firefox to its own profile directory, and Ubuntu has shipped it as a snap
  since 22.04 -- so `~/.mozilla` is empty on the commonest desktop there is, and
  an anchor installed only there went into nothing while the store reported
  success. Every root that exists is used, because a machine can have two.
* Trust stores moved to the `truststores` crate, which also reads them: what
  the host already trusts, as PEM a verifier can be pointed at. devcert issues
  certificates and asks that crate to install them. `DEVCERT_LINUX_TRUST_DIR`,
  `DEVCERT_NSS_DB` and `DEVCERT_JAVA_KEYSTORE` behave as before.
* Host facts are asked of `hostkit` rather than guessed from the environment:
  where devcert's own executable is (it took the directory part of `argv[0]`,
  which is a relative path when devcert is run as `./bin/devcert` and a
  different program of the same name when a PATH search resolves it -- either
  way the message catalogue is looked for in the wrong place), where the user's
  home directory is, where per-user application data lives, and which language
  the user reads. That last one matters on Windows, which sets none of `LC_ALL`,
  `LC_MESSAGES` or `LANG`: every Windows user read English whatever they had
  chosen.
* Trust-store commands run through `hostkit`, under a deadline. A tool that
  stops talking no longer stops devcert.
* Human-readable output is translated into 34 European languages, chosen by
  `DEVCERT_LOCALE`, `LC_ALL`, `LC_MESSAGES` or `LANG`. The translations are not
  reviewed by native speakers; machine-readable output does not move.
* Non-ASCII output is the UTF-8 it was written in. Alire's `-gnatW8` also sets
  the binder's run-time encoding, so `Ada.Text_IO` encoded every byte above 127
  a second time on the way out: an accented path or an internationalized domain
  name printed as mojibake, in English, long before there was anything to
  translate.
* Each trust store says what became of it, instead of the caller reading that
  back out of the sentence the store had just written. A denial was told apart
  from a broken store by searching the message for "requires permission", so
  translating one message would have changed the exit code a caller acts on
  without anything failing.
* A Java keystore that will not have us -- the JDK's own `cacerts` on a system
  install, unprivileged -- is reported as `permission-required` and exit 7,
  where it used to be a plain error. The keystore is named, resolved through the
  symlink a distribution puts `keytool` behind.
* A Java trust anchor devcert installed is recognised as its own. `keytool
  -list -rfc` names the alias and the entry type before the armour, and the PEM
  decoder began one line into the text, so devcert compared its CA against that
  preamble: a successful install was reported as a failure, and `uninstall` then
  refused to remove the anchor it had put there.
* Removing the CA from the Windows trust store removes it. `certutil` matches
  the SHA-1 hash the store indexes by, and handed devcert's SHA-256 identity it
  exited zero having deleted nothing, so `uninstall` reported a removal that had
  not happened. The removal is now asked for by that hash, and the store is read
  back afterwards rather than the exit status believed.
* Trust-store commands capture their output into the host's temporary
  directory instead of `/tmp`, spelled out. Windows has no such directory, so
  the spawn could not create the file it was told to capture into and every
  trust-store command there reported failure whatever the command itself did.
  A failure now also carries the tool's exit status.
* A trust store removal that succeeded says `removed` rather than `installed`.
* A macOS or Windows trust store that refuses an unprivileged caller is
  reported as `permission-required` and exit 7, the way Linux already reported
  it, rather than as a broken store. The system keychain belongs to root and the
  machine `Root` store to an administrator, so this is the ordinary case there,
  and the one thing the message did not say was that it has to run under `sudo`.
  Established by the first execution of the keychain adapter on a Mac; see
  [docs/platform_evidence.md](docs/platform_evidence.md).
* Identity validation, PEM comparison and PEM sniffing are asked of
  `cryptolib` rather than reimplemented: one set of rules decides what a
  certificate may contain, and it is the one that has to encode it.
* A PKCS#12 bundle can be opened by the tools that read one. Every bundle
  failed its own MAC check -- OpenSSL refused the password it was built with --
  because the password was widened to a BMPString twice before the MAC key was
  derived.
* The fingerprint devcert reports and derives anchor names from is the
  certificate's own, over its DER, as openssl and a browser's certificate
  manager show it. It was taken over the armoured text, so it matched nothing a
  person could compare it with and changed if the same certificate was
  re-wrapped. An existing CA root's metadata will no longer match: delete it and
  let devcert create one.
* The NSS store covers Firefox. `$HOME/.pki/nssdb` is the database Chromium
  reads and Firefox does not; devcert now also acts on every Firefox profile
  holding a `cert9.db`, reporting each database and staying
  fingerprint-authoritative per database on removal.
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
  one.
* The mode read behind `doctor`'s expected-mode reporting falls back to BSD
  `stat -f %Lp` where GNU `stat -c %a` is rejected, so it answers on macOS
  instead of silently reporting nothing.
* The test suite writes below the host's scratch directory rather than a
  hardcoded `/tmp`.
* Owner-only permissions are applied through `Hostkit.Fs.Make_Private` rather
  than by spawning `chmod`, so a CA root, private key, or metadata file is
  restricted even where no `chmod` is on `PATH`. Widening a mode, such as the
  world-readable CA certificate, remains a best-effort spawn.
