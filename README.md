# FieldTally

Ingress stats tracking, mobile-first and **fully local**: no account, no
server, no data leaving your phone.

> **Status: early days.** Paste an export, review it, save it. The dashboard,
> charts and badge projections are still to come, and there is no installable
> release yet.

## Not affiliated with Niantic

FieldTally is an **unofficial, fan-made** tool with no connection to Niantic,
Inc. "Ingress", along with badge and counter names, are trademarks and content
of Niantic, Inc. This project uses no protected asset.

## What the app will do (v1)

- Add a snapshot by pasting the text Ingress Prime shares, or straight from the
  Android share sheet.
- Detect and **block** a partial period import (`WEEK` / `MONTH` / `NOW`) that
  would silently skew your history.
- Customisable dashboard, per-counter charts, activity heatmap, badge
  projections, personal goals and local notifications.
- CSV import from Agent Stats, CSV export, shareable stats card.

The full picture is in [`docs/spec/SPECIFICATION-v1.md`](docs/spec/SPECIFICATION-v1.md)
— note that the specification itself is written in French.

## Repository layout

```
app/        Flutter project (assets/, lib/, test/, tool/)
docs/       GitHub Pages site, specification and counter registry
tool/       non-Flutter tooling (registry validation)
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

## Privacy

No collection, no telemetry, no account. A single network request in the whole
of v1: reading the public `counters.json` file from GitHub Pages, sending no
personal data, and switchable off in the settings.

## Licence

[GNU AGPL v3](LICENSE) — Copyright (C) 2026 Nohzoh.

FieldTally is free software: you may redistribute and modify it under the terms
of the GNU Affero General Public License, version 3. It comes with no warranty.

In practice the AGPL requires any modified version to stay under the same
licence — including, and this is what sets it apart from the GPL, when that
version is merely made available over a network rather than distributed. That
becomes relevant the day v2 adds a backend.
