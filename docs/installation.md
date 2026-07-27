# Installation

## Prerequisites

Alire and GNAT. `cryptolib` links against OpenSSL, so the OpenSSL development
headers must be present as well (`libssl-dev` on Debian and Ubuntu).

## Building

Build the runtime crate from the repository root:

```text
alr build
```

The executable is written to `bin/devcert`. The build's post-build actions also
bundle the generated `i18n` locale data into `share/i18n`.

The required runtime dependencies are `cryptolib`, `hostkit`, `i18n`,
`messages`, and `terminal_styles`. Tooling depends on `project_tools` and
`cryptolib`.
Development manifests pin them to sibling workspace crates. Release manifests
must not contain local path pins.

## Deploying

`devcert` reads two sets of data files at run time: the message catalog in
`share/devcert` and the locale data in `share/i18n`. Both are found relative to
the executable, at `<executable-directory>/../share`, so an installed tree must
keep them together:

```text
<prefix>/bin/devcert
<prefix>/share/devcert/messages.catalog
<prefix>/share/i18n/...
```

Copying `bin/devcert` somewhere on its own leaves it able to run, but human
output degrades to bare message identifiers such as `error.unknown_command`,
because no catalog is found. `DEVCERT_CATALOG` and `--catalog` override the
lookup for a catalog kept elsewhere; `I18N_DATA_DIR` does the same for the
locale data.

Putting `<prefix>/bin` on `PATH` is enough — devcert resolves its own program
name through `PATH` before looking beside itself, so the data files are found
whatever the working directory.
