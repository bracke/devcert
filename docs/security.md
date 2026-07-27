# Security Model

`devcert` manages a local development CA. The CA private key remains in the
configured state directory and is never installed into operating system,
browser, Java, or NSS trust stores.

Private-key files and PKCS#12 bundles are written atomically and with owner-only
permissions where the platform supports them. Those permissions are applied
through `Hostkit.Fs.Make_Private`, which calls `chmod(2)` directly: the earlier
spawn of `chmod(1)` needed the tool on `PATH`, and where it was absent the write
went ahead and left the key with whatever permissions it was created with. The
write ends in a replacing rename through `hostkit`, which is a single step on
both POSIX and Windows;
`doctor` reports a CA whose private key or metadata is readable by anyone but
the owner as a CA state failure. That question is put to the host through
`Hostkit.Fs.Accessible_By_Others` rather than to a `stat` command, whose options
differ between GNU and BSD, so it holds on macOS as well as Linux. Windows
scopes access by ACL instead of mode bits, and the check declines to answer
there rather than guessing. Logs and JSON output must not
contain private keys, passwords, passphrases, PKCS#12 bytes, or other secrets.

Trust-store installation may require elevated privileges. Trust-store removal is
fingerprint-authoritative and does not rely on display names.

Limitations: certificates issued by a local development CA are intended for
development environments only and are not a substitute for public Web PKI. The
current PFX profile is integrity protected but unencrypted.
