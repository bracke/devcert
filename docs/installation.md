# Installation

Install Alire and GNAT, then build the runtime crate from the repository root:

```text
alr build
```

The required runtime dependencies are `cryptolib`, `i18n`, and
`terminal_styles`. Development manifests pin them to sibling workspace crates.
Release manifests must not contain local path pins.
