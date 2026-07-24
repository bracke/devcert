# CA Lifecycle

The local CA lifecycle consists of creation, inspection, trust installation,
trust removal, rotation, and deletion. CA material is kept in the configured
devcert state directory and is never copied into a trust store.

Trust installation and removal are fingerprint-authoritative: trust-store
adapters operate on the CA certificate fingerprint rather than display names.
