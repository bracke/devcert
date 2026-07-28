# cryptolib Contract

All cryptographic operations are delegated to `cryptolib`.

`devcert` may request:

* local CA key and certificate creation
* leaf certificate issuance
* CSR parsing and signing
* PKCS#12 generation
* fingerprint calculation

`devcert` must not contain duplicate crypto primitives, key serialization
implementations, or certificate signing implementations.

Nor duplicate rules about what a certificate may contain. Whether a string is a
DNS name, an IP address or an email address is asked of
`CryptoLib.Certificates.Valid_DNS_Name`, `Valid_IP_Address` and
`Valid_Email_Address`; whether two PEM texts hold the same certificate, of
`Same_Certificate`; and whether a file holds a certificate or a private key, of
`Contains_Certificate` and `Contains_Private_Key`. `devcert` validates
identities early, because it owns the diagnostics and the exit codes, but it
validates by asking rather than by keeping a second copy of the rules -- which
could accept an identity that then failed to encode, or refuse one that would
have.

What stays here: which identities a command accepts, in what combination, and
what it says when it refuses one.

The CA and the certificates it issues use NIST P-384 with ECDSA-SHA384. Not a
preference: NSS refuses to import an Ed25519 certificate at all, so a CA built
that way is trusted by no browser, whatever the trust-store adapters do.
`CryptoLib.Certificates.Create_Local_CA` takes the key algorithm and devcert
asks for P-384; a leaf follows the CA's own key, because it has to be
verifiable by whatever accepts the CA.

CSRs are read and verified as either Ed25519 or P-384 requests; which one a
request is shows in the request itself, so the caller does not declare it. The
subject's key and the CA's need not agree: a CSR brings its own key and the CA
signs what it was handed.

The certificate boundary is `CryptoLib.Certificates`. It owns Ed25519 and
P-384 key generation, X.509 certificate construction, PKCS#8 private-key encoding,
PKCS#10 CSR parsing and signature verification, certificate signing, and PFX
construction.
