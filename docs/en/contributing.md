---
layout: default
title: Contributing
lang_alt: /contribuer
---
{% include nav-en.html %}

# Contributing

## Declare a counter — no code needed

This is the most useful contribution, and it does not require being a developer.

When Niantic adds a counter — typically during an anomaly — the app tracks it
straight away, but under its original name and filed under "Other". Giving it a
name, a category and badge thresholds means adding one entry to one file:

[`docs/registry/counters.json`](https://github.com/Nohzoh/FieldTally/blob/main/docs/registry/counters.json)

Every install fetches this file on startup, so your correction reaches everyone
**without a new version of the app**. An automated check rejects the file if it
is malformed, so there is no way to break other people's app with it.

## Report an import problem

This is the project's fragile point: the Ingress share format is undocumented
and can change. If an import fails,
[open an issue](https://github.com/Nohzoh/FieldTally/issues/new) with an excerpt
of the shared text. Replace your agent name if you prefer — only the column
names are useful for diagnosis.

## Develop

The project is Flutter. To run it:

```sh
git clone https://github.com/Nohzoh/FieldTally.git
cd FieldTally/app
flutter pub get
flutter run
```

The checks that must pass before any proposal:

```sh
flutter analyze
flutter test
```

The details — code structure, commit conventions, what CI enforces — are in
[CONTRIBUTING.md](https://github.com/Nohzoh/FieldTally/blob/main/CONTRIBUTING.md).
Two rules worth knowing up front: **everything in the repository is in English**
(code, comments, commits, issues) except the translation files, and commits
follow Conventional Commits.

## Translate

The app exists in French and English. The strings live in
[`app/lib/l10n/`](https://github.com/Nohzoh/FieldTally/tree/main/app/lib/l10n),
one file per language. Adding a language means copying `app_en.arb` and
translating it — the Ingress community is international, and this contribution
needs no knowledge of the code.

## Licence

FieldTally is published under the **GNU AGPL v3**. Contributions are accepted
under that licence.
