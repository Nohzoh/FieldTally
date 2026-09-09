# Contributing to FieldTally

## Language

Everything in this repository is written in **English**: code, identifiers,
comments, commit messages, issues and pull requests. The one exception is
localisation content — the `.arb` files under `app/lib/l10n/` and the `label`
fields of `docs/registry/counters.json` — which carries the text shown to
users, in French and English.

Practical consequence: **no user-visible string is hard-coded in a widget.**
Every displayed string goes through the localisation layer, even while a single
language is active.

## The most useful contribution: declaring a counter

When an anomaly starts, Ingress adds new counters to the export. The app tracks
them **automatically** — but they show under their raw name, in the "Other"
category, until someone declares them.

Declaring them properly means editing **a single file**, without writing a line
of Dart: [`docs/registry/counters.json`](docs/registry/counters.json).

An entry looks like this:

```json
"orion_tokens": {
  "export_header": "Orion Tokens",
  "category": "events",
  "order": 6,
  "label": { "en": "Orion Tokens", "fr": "Jetons Orion" }
}
```

- `export_header` must be **exactly** the column name in the Ingress export —
  that is what the app matches on.
- `category` must be one of the keys declared under `categories` at the top of
  the file; we mirror the categories of the in-game stats screen.
- `order` positions the counter inside its category.
- `tiers` is optional — only add badge thresholds you know from a reliable
  source, in strictly increasing order.

Before opening the pull request:

```bash
python3 tool/validate_registry.py
cd app && dart run tool/sync_registry_seed.dart
```

The second command regenerates `app/assets/counters_registry_seed.json`, the
fallback copy bundled into the app. **Never edit it by hand**: CI checks that it
matches the file under `docs/`.

## Commit messages

The project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): imperative subject, lowercase, no trailing period

Free-form body, separated by a blank line, explaining the why.
```

Types in use: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`,
`chore`, `style`, `revert`. The scope is optional and names the area touched:
`registry`, `parser`, `app`, `docs`, `ci`…

```
feat(parser): map export columns by header name
fix(registry): correct the category of anomaly_unique_hacks
ci: validate the registry before deploying Pages
```

A breaking change is marked with a `!` before the colon (`feat(db)!: …`) and a
`BREAKING CHANGE:` paragraph in the body.

This convention is not cosmetic: the release pipeline (§7.2 of the spec)
generates its changelog from the commits. If you squash-merge, remember that
GitHub uses the **pull request title** as the commit message — so that title
has to follow the convention too.

## Signed commits

Commits must be signed. The project uses **SSH** signing rather than GPG: less
setup, and enough for GitHub to show *Verified*.

Generate a dedicated signing key (separate from your authentication key), then
add it to your GitHub account under **Settings → SSH and GPG keys → New SSH
key**, making sure to pick **Key type: Signing Key** (not *Authentication Key*,
which verifies no signature).

```bash
ssh-keygen -t ed25519 -f ~/.ssh/fieldtally_signing_ed25519 -C "fieldtally-signing-key"

git config gpg.format ssh
git config user.signingkey ~/.ssh/fieldtally_signing_ed25519.pub
git config commit.gpgsign true
git config tag.gpgsign true
```

So that `git log --show-signature` can verify signatures locally, declare the
trusted keys:

```bash
echo "your@email ssh-ed25519 AAAA..." >> ~/.ssh/allowed_signers
git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

The address on the left must be the one on your commits (`git config
user.email`), otherwise local verification fails even though GitHub shows
*Verified*.

## Contributing code

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

These three must pass — CI replays them on every pull request, plus a debug APK
build and three consistency checks (bundled registry seed, generated code,
`pubspec.lock`).

### Code layout (§5.2 of the spec)

```
lib/
  data/           parsing (Ingress text, CSV), Drift access, repositories
  domain/         business models, computations (diffs, projections)
  presentation/   screens, widgets, Riverpod providers
  core/           constants, theme, routing
  l10n/           .arb translation files
```

The guiding rule: business logic (parsing, projections) never depends on the
UI, and screens only ever talk to repositories — so that adding a backend in v2
does not mean rewriting the interface. A corollary of the language rule: the
domain returns structured facts, never sentences; the wording lives in
`lib/presentation/messages.dart`.

### Test fixtures

Export samples live in `app/test/fixtures/`. **No fixture may contain a real
Ingress codename or values traceable to an identifiable account.** Before
committing a new sample: replace the codename with a generic one, neutralise
the date, and multiply every numeric value by one fixed scaling factor (which
preserves proportions and zeros, hence the fixture's value for testing).

## Reporting a problem

Two issue templates exist: one for "parsing does not work" (remember to
anonymise your sample), one for "add or fix a counter".

## Licence

By contributing, you agree that your contribution is published under the
[GNU AGPL v3](LICENSE), like the rest of the project.
