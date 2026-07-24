# Certificate Policies

Development certificates are issued from the local CA as X.509 v3 Ed25519
certificates with explicit subject alternative names. Required profiles include
localhost server certificates, DNS SANs, and CSR signing. CSR signing accepts a
PKCS#10 Ed25519 CSR, extracts the subject common name and public key, and signs
a leaf certificate for that public key.

PKCS#12 generation is delegated to `cryptolib`. The current PFX profile contains
a key bag, certificate bag, and SHA-1 MacData with 2048 PKCS#12 KDF iterations.
The bags are not encrypted. No certificate profile logic may duplicate
cryptographic implementation details inside `devcert`.
