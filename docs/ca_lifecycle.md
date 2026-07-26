# CA Lifecycle

The local CA lifecycle consists of creation, inspection, trust installation,
trust removal, rotation, and deletion. CA material is kept in the configured
CA root directory and is never copied into a trust store.

The CA root contains:

```text
rootCA.pem
rootCA-key.pem
ca-metadata.txt
issued/
```

`rootCA.pem`, `rootCA-key.pem`, and `ca-metadata.txt` are written atomically.
The metadata file records the format version, manager, creation marker, key
algorithm, and SHA-256 certificate fingerprint. The certificate and private key
remain the source of truth; issued certificate records are never required for
certificate validation.

POSIX permissions are enforced where supported:

```text
CA root:       0700
rootCA.pem:    0644
rootCA-key.pem 0600
ca-metadata:   0600
issued/:       0700
```

`doctor` reports unsafe CA permissions as a CA state failure.

Trust installation and removal are fingerprint-authoritative: trust-store
adapters operate on the CA certificate fingerprint rather than display names.
