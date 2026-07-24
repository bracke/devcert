# Security Model

`devcert` manages a local development CA. The CA private key remains in the
configured state directory and is never installed into operating system,
browser, Java, or NSS trust stores.

Private-key files and PKCS#12 bundles are written atomically and with owner-only
permissions where the platform supports them. Logs and JSON output must not
contain private keys, passwords, passphrases, PKCS#12 bytes, or other secrets.

Trust-store installation may require elevated privileges. Trust-store removal is
fingerprint-authoritative and does not rely on display names.

Limitations: certificates issued by a local development CA are intended for
development environments only and are not a substitute for public Web PKI. The
current PFX profile is integrity protected but unencrypted.
