# JSON Contract

JSON output is deterministic, schema versioned, and free of secrets.

The current schema version is `1`. Object keys are emitted in stable order.
Secret-bearing values such as private keys, passwords, passphrases, and PKCS#12
contents are never written to JSON output.
