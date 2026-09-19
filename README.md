# FieldTally

Ingress stats tracking, mobile-first and **fully local**: no account, no
server, nothing leaving your phone unless you send it yourself.

[![CI](https://github.com/Nohzoh/FieldTally/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Nohzoh/FieldTally/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/Nohzoh/FieldTally?label=release)](https://github.com/Nohzoh/FieldTally/releases/latest)
[![Licence: AGPL v3](https://img.shields.io/badge/licence-AGPL%20v3-blue)](LICENSE)
[![Coverage](https://img.shields.io/endpoint?url=https%3A%2F%2Fnohzoh.github.io%2FFieldTally%2Fcoverage.json)](https://nohzoh.github.io/FieldTally/coverage/)

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
  their original name — and says since when it has been watching, so an event
  that closed before your first snapshot reads as a stated unknown rather than
  a silence.
- Customisable dashboard, activity calendar, personal goals, local reminders,
  and an announcement when a snapshot crosses a badge tier, passes a further
  onyx multiple, or raises a level.
- Per-counter charts on their own scale, each with a line at what you are
  chasing: your goal if you set one, otherwise the next badge tier.
- Badge projections, with the medal you have reached drawn beside every
  counter that carries one. Onyx is not the end: past it the app counts in
  whole multiples, as the game does. Anomaly medals are understood too —
  ladders that stop being earnable, marked by a broken rim, whose thresholds
  arrive through the registry without an app update.
- A counter list you can search, narrow to the counters carrying a medal, and
  order by the badge you are closest to, with recent progress measured as a
  pace per day over a window you choose.
- Brings an **Agent Stats** history over. That site has no file to download,
  so the app takes its export page pasted as it comes — banner, pagination and
  column titles included — and reports what it could not read before saving
  anything. CSV export, shareable stats card as a PNG.
- Puts your totals next to another agent's, phone to phone, through the
  share sheet — no server, and what they send you is never written to your
  history.
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

No collection, no telemetry, no account. Two network requests in the whole of
v1, both `GET`s on public files served from GitHub Pages, both sending no
personal data and both switched off by the same setting: `counters.json` for
counter names and thresholds, and `latest.json` to say which release is the
newest — the app is sideloaded, so nothing else would. The full statement is on
the [privacy page](https://nohzoh.github.io/FieldTally/en/privacy).

## Licence

[GNU AGPL v3](LICENSE) — Copyright (C) 2026 Nohzoh.

FieldTally is free software: you may redistribute and modify it under the terms
of the GNU Affero General Public License, version 3. It comes with no warranty.

In practice the AGPL requires any modified version to stay under the same
licence — including, and this is what sets it apart from the GPL, when that
version is merely made available over a network rather than distributed. That
becomes relevant the day v2 adds a backend.
