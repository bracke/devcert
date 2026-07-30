# AGENTS.md

Guidance for AI agents working in the `devcert` crate. **This file is the
canonical copy** and applies to every AI coding tool; `CLAUDE.md` imports it so
Claude Code sees the same text. Edit this file, not that one.

## What this is

`devcert` is a local development certificate authority and certificate tool: it
issues a CA, issues certificates from it, and installs the CA into the host's
trust stores. The `devcert` executable is the product; `src/` and `app/` are its
code.

It is a *consumer* crate, not a primitive one. The cryptography is
`cryptolib`'s, the trust-store handling is `truststores`', and the
host-dependent file and process facts are `hostkit`'s. When something needs a
new primitive, it belongs in the crate that owns that job — this one should
stay about certificates and the workflow around them.

`docs/` is not decoration. Eighteen files carry contracts the code is expected
to keep — `cryptolib_contract.md`, `json_contract.md`, `trust_stores.md`,
`mkcert_parity.md`, `localization.md`, `security.md` and the rest — and the
release gate checks several of them against the source. Change behaviour,
change the document that describes it.

## Build, test, release

- Toolchain: Alire GNAT 15, pinned **exactly** — the manifest says
  `gnat_native = "=15.2.1"`, not a range. Validate with
  `alr exec -- gnatls --version`; the release gate refuses anything else. Do
  not run system `gnat*`, `gprbuild`, `gnatprove` or `gnatdoc` from `PATH`.
- Build: `alr build`.
- Tests: `(cd devcert_tests && alr build) && ./devcert_tests/bin/devcert_tests`
  — AUnit, currently 39 tests.
- **Release gate**: `(cd check_devcert && alr build) && check_devcert/bin/check_devcert`.
  This is the one to run before calling a change done. It verifies the
  toolchain, checks the documentation a release depends on, builds devcert and
  its suite, runs the suite, and then runs the devcert-specific checks in the
  tooling crate.
- Tooling: `(cd devcert_tools && alr build)`, then
  `devcert_tools/bin/devcert_tools <command>`. Twelve commands: `style-check`,
  `release-check`, `manifest-check`, `catalog-check`, `tree-check`,
  `generated-artifact-check`, `dist`, `documentation`,
  `test-registration-check`, `parity-check`, `tooling-tests`, and
  `platform-check <linux-system|macos-system|windows-system>`. `release-check`
  and `dist` are the two a release runs; the rest are worth reading before
  writing a check that already exists.
- `docs/release_process.md` spells the sequence out and is the authority if it
  disagrees with this file.

## Style and warnings

- Ada 2022, 3-space indent, **100 columns** — `-gnatyM100`, not the 120 some
  sibling crates use.
- **`devcert.gpr` carries `-gnatwa` and `-gnatwe` itself**, so every warning is
  an error in every build profile. That is stricter than crates which take
  their warning switches from the Alire profile and only fail under
  `--validation`: here a warning breaks `alr build` outright, and there is no
  profile in which it does not. Both the runtime and the suite are clean under
  `alr build --validation -- -f`; keep them so.

## When you change behaviour

Update the `docs/` file that describes it, adjust or add tests in
`devcert_tests`, and run the release gate. Because the cryptography is
`cryptolib`'s, a change that needs a primitive to behave differently is a
change to that crate first — and one that will need its suite, its preflight
and its other consumers checked before this one can rely on it.
