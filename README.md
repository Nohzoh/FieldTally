# FieldTally

Ingress stats tracking, mobile-first and **fully local**: no account, no
server, no data leaving your phone.

**[Install it](https://nohzoh.github.io/FieldTally/en/install) ·
[Website](https://nohzoh.github.io/FieldTally/en/) ·
[Site en français](https://nohzoh.github.io/FieldTally/)**

## Not affiliated with Niantic

FieldTally is an **unofficial, fan-made** tool with no connection to Niantic,
Inc. "Ingress", along with badge and counter names, are trademarks and content
of Niantic, Inc. This project uses no protected asset.

## What the app does

- Adds a snapshot from the text Ingress Prime shares — through the Android
  share sheet or pasted by hand — mapping every column **by name**, never by
  position, so a counter added or moved by Niantic breaks nothing.
- **Refuses** a partial period import (`WEEK` / `MONTH` / `NOW`) and **warns**
  when a counter goes backwards: the two mistakes that silently corrupt a
  history.
- Tracks **every** counter it meets, including ones it has never seen, under
  their original name.
- Customisable dashboard, per-counter charts on their own scale, activity
  calendar, badge projections, personal goals, local reminders.
- CSV import from Agent Stats, CSV export, shareable stats card as a PNG.
- Light and dark themes, optional faction colouring, French and English.

The full picture is in [`docs/spec/SPECIFICATION-v1.md`](docs/spec/SPECIFICATION-v1.md)
— note that the specification itself is written in French.

## Repository layout

```
app/        Flutter project (assets/, lib/, test/, tool/)
docs/       GitHub Pages site, specification and counter registry
tool/       non-Flutter tooling (registry validation, icon generation)
scripts/    local tooling
.github/    workflows, issue templates, dependabot
```

## The counter registry

`docs/registry/counters.json` is the **source of truth** for categories,
labels and badge thresholds. It is **not** the list of supported counters: the
app tracks every counter it meets in an export, even an unknown one. The
registry only adds comfort — category, translated label, projections.

It is published on GitHub Pages and fetched by the app at startup, so a new
anomaly counter can be declared with a single pull request, without shipping a
new version of the app.

## Language

Everything in this repository is written in English — code, comments, commits,
issues and pull requests — so that anyone in the Ingress community can
contribute. User-facing text lives in the localisation files
(`app/lib/l10n/*.arb`) and in the `label` fields of the counter registry; those
carry French and English.

## Running it locally

Requirements: Flutter 3.44+ (stable channel) and the Android SDK.

```bash
cd app
flutter pub get
flutter test
flutter run
```

After editing `docs/registry/counters.json`, regenerate the bundled fallback
copy and validate the file:

```bash
cd app && dart run tool/sync_registry_seed.dart
python3 tool/validate_registry.py   # from the repository root
```

## Releases

Every release is built by GitHub Actions from this source and signed with the
same key, whose SHA-256 fingerprint is printed in each build log:

```
9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
```

The procedure is in [`docs/release.md`](docs/release.md).

## Privacy

No collection, no telemetry, no account. A single network request in the whole
of v1: reading the public `counters.json` file from GitHub Pages, sending no
personal data, and switchable off in the settings. The full statement is on the
[privacy page](https://nohzoh.github.io/FieldTally/en/privacy).

## Licence

[GNU AGPL v3](LICENSE) — Copyright (C) 2026 Nohzoh.

FieldTally is free software: you may redistribute and modify it under the terms
of the GNU Affero General Public License, version 3. It comes with no warranty.

In practice the AGPL requires any modified version to stay under the same
licence — including, and this is what sets it apart from the GPL, when that
version is merely made available over a network rather than distributed. That
becomes relevant the day v2 adds a backend.
