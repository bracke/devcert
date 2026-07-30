# Localization

Human-readable terminal text is localized through the `messages` runtime, which
delegates locale handling to `i18n`. The default locale is `en`, stored in the
version-controlled source catalog at `config/messages/messages.catalog` and
shipped as `share/devcert/messages.catalog`.

## Languages

The catalog carries the 24 official EU languages -- Bulgarian, Croatian, Czech,
Danish, Dutch, English, Estonian, Finnish, French, German, Greek, Hungarian,
Irish, Italian, Latvian, Lithuanian, Maltese, Polish, Portuguese, Romanian,
Slovak, Slovenian, Spanish, Swedish -- and Albanian, Belarusian, Bosnian,
Icelandic, Macedonian, Norwegian Bokmål, Russian, Serbian, Turkish and
Ukrainian.

### What has been checked without a native speaker

Three things, none of which judges a translation:

* **Structural.** Every translated key has an English original and keeps its
  `{value}` argument; nothing carries an ASCII apostrophe, which ICU reads as an
  escape and which would swallow the placeholder after it. Enforced by
  `devcert_tools catalog-check`.
* **Verbatim tokens.** A command name, an option, `PKCS#12`, `CSR` or `devcert`
  itself must survive translation: they are what a user types, and a translated
  `--color` is a word the program rejects. Also enforced by `catalog-check`.
* **Language identification.** Each locale's text was put to a detector
  (`lingua`, 2026-07-30) to catch the error no structural rule can see -- fluent
  text, correctly placeheld, in the wrong language, which is what copying a
  neighbouring locale and adjusting a few words leaves behind. All 33 identified
  as their own language, 31 of them at full confidence.

* **Terminology, against a reviewed corpus.** KDE's Kleopatra is a certificate
  manager whose translations are reviewed by the people who speak the language,
  so the word it uses for *certificate* is the word that community uses. In 29
  of the 33 languages, ours is the same word (2026-07-30).

  The four that are not are questions rather than errors. Belarusian cannot be
  compared: KDE's own file is two thirds untranslated, 1226 empty strings of
  1942. Albanian differs by one letter -- KDE writes `çertifikatë`, ours writes
  `certifikatë`, and the second is the standard spelling, so a native speaker
  should pick. Maltese and Serbian have no Kleopatra translation at all.

Two caveats from the language run. Bosnian scores 0.64 against Croatian and Serbian, and
shares 18 of its 25 strings with Croatian -- which is what those languages do,
but it is where a reviewer should start. And the detector does not know Maltese
at all, so `mt` is unverified by this method.

**These translations have not been reviewed by native speakers.** They were
written for this catalog and are the least trustworthy part of the output: read
an exit code, not a sentence, when it matters. Corrections are one line each.

A locale carries only the keys it translates. The runtime falls back
`de-AT` -> `de` -> `en`, so an untranslated key comes out in English rather
than as a key name, and a new language can be added a message at a time.

These stay English in every locale, because something reads them:

* `app.name` -- the program's name
* `json.schema` -- a value, not prose
* `inspect.ca`, `inspect.ca_missing` -- field syntax (`ca=`, `path=`)
* `doctor.ca_complete`, `doctor.ca_state` -- status lines this project's own
  tooling greps
* `release.passed` -- release tooling output
* `cli.global_options_paths` -- option syntax with no prose in it

JSON output keeps its structure in every locale; the `message` and `error`
fields carry the localized prose, and `schema_version`, `status` and `command`
do not change.

To force English regardless of the host: `DEVCERT_LOCALE=en`, which takes
precedence over `LC_ALL`, `LC_MESSAGES` and `LANG`.

Where none of those is set, the host is asked directly through
`Hostkit.Host.Native_Locale`. That is the ordinary case on Windows, which keeps
the user's language in the system rather than in the environment: without it
every Windows user reads English whatever they chose.

## Text Encoding

The catalog is UTF-8 and devcert prints the bytes it read. That needs the
binder's wide-character encoding left at `-Wb`: Alire's generated switches
include `-gnatW8`, and the binder takes its run-time method from the same
place, which makes `Ada.Text_IO` encode every byte above 127 on the way out.
Text that was already UTF-8 then came out doubled -- `ü` as `Ã¼` -- which
applied to an accented path or an internationalized domain name long before
there was anything to translate. `devcert.gpr` sets `-Wb`; the test suite
checks that no doubled lead byte reaches the output.

The catalog is resolved in this order, so an installed executable is localized
from any working directory:

1. `--catalog` or `DEVCERT_CATALOG`
2. `<executable-directory>/../share/devcert/messages.catalog`
3. `<executable-directory>/share/devcert/messages.catalog`
4. `share/devcert/messages.catalog` under the working directory, then one level
   above it

A program name without a directory part is resolved through `PATH` before the
executable-relative entries are tried.

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
