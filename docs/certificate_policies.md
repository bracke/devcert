# Certificate Policies

`devcert` owns certificate request policy. `cryptolib` owns key generation,
encoding, signing, CSR parsing, and PKCS#12 generation.

Development certificates are issued from the local CA as X.509 v3 Ed25519
certificates with explicit subject alternative names. The implemented cryptolib
profiles support server certificates, DNS SANs, IPv4 SANs, IPv6 SANs, client
certificates, S/MIME email certificates, CSR signing, and PKCS#12 bundles. CSR
signing accepts a PKCS#10 Ed25519 CSR, verifies the CSR signature, extracts the
subject common name and public key, and signs a leaf certificate for that public
key.

`devcert` recognizes server, client, and S/MIME request modes and delegates
issuance for each mode to the matching cryptolib profile API. Client
certificates use the client authentication EKU. S/MIME certificates use an
email subject alternative name and the email protection EKU.

PKCS#12 generation is delegated to `cryptolib`. The current PFX profile contains
a key bag, certificate bag, and SHA-1 MacData with 2048 PKCS#12 KDF iterations.
The bags are not encrypted. Bundles can be generated from stored leaf artifacts
or from the certificate and private key PEM produced by the current issuance
operation, so custom output paths do not bypass the cryptolib-backed bundle
path. No certificate profile logic may duplicate cryptographic implementation
details inside `devcert`.
