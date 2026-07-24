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

The certificate boundary is `CryptoLib.Certificates`. It owns Ed25519 key
generation, X.509 certificate construction, PKCS#8 private-key encoding,
PKCS#10 CSR parsing for Ed25519 requests, certificate signing, and PFX
construction.
