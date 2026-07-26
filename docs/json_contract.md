# JSON Contract

JSON output is deterministic, schema versioned, and free of secrets.

The current schema version is `1`. Object keys are emitted in stable order.
Secret-bearing values such as private keys, passwords, passphrases, and PKCS#12
contents are never written to JSON output.

Every JSON document contains:

```json
{
  "schema_version": 1,
  "status": "...",
  "command": "..."
}
```

Field names are never localized. Human-readable messages may appear in `message`
or `error`, but automation must key off `schema_version`, `status`, `command`,
exit code, and stable field names.
