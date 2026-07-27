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

The CA and the certificates it issues use NIST P-384 with ECDSA-SHA384. Not a
preference: NSS refuses to import an Ed25519 certificate at all, so a CA built
that way is trusted by no browser, whatever the trust-store adapters do.
`CryptoLib.Certificates.Create_Local_CA` takes the key algorithm and devcert
asks for P-384; a leaf follows the CA's own key, because it has to be
verifiable by whatever accepts the CA.

CSRs are read and verified as Ed25519 requests only. Signing one with a P-384
CA works -- the CA signs what it was handed -- but verifying an ECDSA request
would need a verifier `cryptolib` does not have yet.

The certificate boundary is `CryptoLib.Certificates`. It owns Ed25519 and
P-384 key generation, X.509 certificate construction, PKCS#8 private-key encoding,
PKCS#10 CSR parsing for Ed25519 requests, certificate signing, and PFX
construction.
