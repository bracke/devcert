# Localization

Human-readable terminal text is localized through the `messages` runtime, which
delegates locale handling to `i18n`. The default locale is `en`, stored in the
version-controlled source catalog at `config/messages/en.catalog` and shipped
as `share/devcert/messages.catalog`.

Required message identifiers include:

* `app.name`
* `cli.usage`
* `cli.commands`
* `cli.global_options`
* `error.unknown_command`
* `error.invalid_identity`
* `error.ca_unusable`
* `cert.issued`
* `doctor.ca_state`
* `json.schema`
* `release.passed`

Parameterized messages use the `{value}` argument. The runtime supplies this
argument through `Messages.Arguments`; user-visible output does not perform ad
hoc English string assembly in command code for migrated diagnostics.

When a message identifier is missing, `devcert` emits the stable identifier as
an emergency diagnostic rather than failing before an error can be reported.
