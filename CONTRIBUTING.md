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

### Badge emblems

A counter that carries `tiers` also gets an emblem beside it in the list, drawn
in [`app/lib/presentation/widgets/medal_icon.dart`](app/lib/presentation/widgets/medal_icon.dart).
They are the project's own drawings, deliberately not Niantic's artwork, and
they share a grammar worth keeping: a pin means a place, a bracketed frame
means a scan, a filled dot means a node.

**A glyph says what the counter measures, and the counter is its `export_header`
— never its key.** The keys are Ingress badge names, and some of them lie about
what they count: Illuminator counts mind units, Mind Controller counts control
fields. Drawing from the key put those two emblems on each other's counters
until #129.

The **rim** carries a second grammar, independent of the glyph. A badge that can
always be earned gets an unbroken ring; a ladder that stops being earnable — an
anomaly medal, which the registry dates with `ends_at` — gets a ring broken into
four arcs, and the Global Op of a season's pair gets a stud seated in the gap at
twelve o'clock. Put a classification on the rim rather than in the glyph: at list
size the glyph has barely seventeen pixels to say what a counter measures, and
none to spare. `medal_icon_test` checks the rims against the registry's own
`ends_at` in both directions, so the drawing and the data cannot drift apart. Adding badge thresholds to a counter
without adding its emblem fails `test/presentation/medal_icon_test.dart`, in
both directions.

To look at them:

```bash
cd app && flutter test tool/medal_sheet_test.dart
```

That writes a contact sheet to `app/build/design/`, light and dark, at list
size and large. Judge a new emblem at **list size**: that is where two
silhouettes that looked distinct when large turn out to be the same drawing.

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

## One issue per change

Every change that reaches `main` answers to an issue, and the pull request names
it — `Closes #N` when it finishes the issue, `Refs #N` when it is one step of
it. This holds for documentation and tooling as much as for features: the
release notes are written from the milestone, so work with no issue simply goes
unmentioned.

The one exception is the **release bump** — the commit that sets the version and
writes that release's changelog entry, along with any site page the release made
stale. That commit cannot go missing from the notes, because it is the notes.

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
dart format lib test tool
flutter analyze
flutter test
```

These must pass — CI replays them on every pull request, plus a debug APK build
and three consistency checks (bundled registry seed, generated code,
`pubspec.lock`).

**Run the formatter.** The repository is `dart format` clean and CI checks it,
so a pull request that skips it fails before anything else is looked at. Most
editors do this on save; if yours does not, the command above is the whole of
it.

The repository was formatted in one pass, in `e1bc959`, and that commit is
listed in `.git-blame-ignore-revs`. GitHub honours the file on its own; locally
it takes one command, once per clone:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

It matters less than it sounds: `git blame` already attributes 99.8 % of
`app/lib` past that commit on its own, because its diff matches a re-indented
line to the one it came from. The file is there for the residue — lines the
formatter genuinely created by splitting one in two — and for the next commit
of this kind, should there be one.

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

## Working with an AI agent

[`CLAUDE.md`](CLAUDE.md) holds what an agent needs beyond this file: the shape
of the sandbox it runs in, the commands CI actually runs, and the traps this
project has already paid for once. It is written for an agent, but the traps are
worth a read for anyone — several of them are about this repository rather than
about tooling.

## Reporting a problem

Two issue templates exist: one for "parsing does not work" (remember to
anonymise your sample), one for "add or fix a counter".

## Licence

By contributing, you agree that your contribution is published under the
[GNU AGPL v3](LICENSE), like the rest of the project.
