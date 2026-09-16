# Working on FieldTally

Notes for an agent working in this repository. `CONTRIBUTING.md` holds the
conventions and is the source of truth for them; this file holds what a fresh
session cannot see and would otherwise rediscover the hard way — the shape of
the sandbox, and the traps already paid for.

Everything here was learned by getting it wrong once.

## The sandbox

Sessions run in an ephemeral container, not on the maintainer's machine. Three
things follow.

**The clone is shallow.** `git log` will show a commit that looks like the
repository's root and is not. This has already produced a false claim published
in an issue *and* in a pull request body — that a feature "arrives in the root
commit, which predates anything recorded" — when the real root is `cf41c12`,
much earlier, and `git fetch --unshallow` was all it took to see it. Unshallow
before making any claim about history, and never date a change from `git log`
alone.

**`./scripts/gh` does not work here.** It reads a token from `.secrets/`, which
is not in the container. Every GitHub operation — issues, pull requests, merges,
workflow runs, check status — goes through the GitHub MCP tools. `git` over
HTTPS works normally: fetch, push, and branches are fine.

**There is no Android SDK, no emulator, and no device.** `apksigner`, `aapt` and
`adb` are absent, and nothing can be installed or run. What this costs, and what
to do instead, is under *Verifying a release* below. The proxy also blocks
`github.io` and `ingress.com`, so the published site and Niantic's pages cannot
be fetched from here — ask for the text rather than guessing at it.

`flutter` is at `/opt/flutter/bin`. It is not on `PATH` by default.

## Tests lie about layout

`flutter test` forces the **Ahem** test font: every glyph is a filled em square.
Text therefore lays out far wider than it ever will on a phone, and a widget
test can overflow where the real screen does not.

A visual defect seen only under `flutter test` is **not** a defect until it is
seen on a device. One has already been reported as real and turned out not to
reproduce. Say "unconfirmed, seen only under the test font" and let the
maintainer check on their phone.

This is also why text in the rendered contact sheets is unreadable blocks.

## The commands CI actually runs

Two jobs. `python3 tool/validate_registry.py` runs on its own from the
repository root; the rest run from `app/`, in this order, and the first failure
hides the ones after it:

```sh
dart run tool/sync_registry_seed.dart --check
dart run build_runner build && git diff --exit-code      # generated code
git diff --exit-code pubspec.lock
dart format --output=none --set-exit-if-changed lib test tool   # since #97
flutter analyze
flutter test
```

`flutter test` takes several minutes in this container. `dart format` is not
optional and not cosmetic: running it late once reformatted **51 untouched
files** and the whole change had to be redone by hand to keep the diff readable.
Format first, then edit.

## Two data paths, and the order between them

The counter registry is served from GitHub Pages and fetched at startup
(§3.1.4). Code is not. So:

> **A registry change reaches an installed app at its next launch. Code reaches
> it only in a release.**

Data that only newer code can read must therefore ship **after** that code is
published, never before. Getting this backwards sends thresholds to apps that
cannot interpret them. It also cuts the other way, and usefully: a wrong
threshold or a corrected date is a registry edit, not a release.

Editing the registry means `docs/registry/counters.json` — never
`app/assets/counters_registry_seed.json`, which is generated and CI-checked.
Regenerate with `dart run tool/sync_registry_seed.dart` from `app/`, validate
with `python3 tool/validate_registry.py` from the root.

## Sourcing badge thresholds

A wrong threshold produces a wrong projection date **in silence**, which is
worse than no projection at all. So a threshold is quoted from an announcement
or it is not added; and a value that had to be inferred says so, in the commit
and in the pull request, so it can be corrected later.

Test fixtures are not evidence. `CONTRIBUTING.md` requires every fixture value
to be multiplied by a fixed scaling factor, so a fixture number that happens to
sit just above a threshold proves nothing. One nearly went in as confirmation.

## Prove a test fails

Adding a test that passes proves nothing about what it protects. Revert the fix,
watch the test go red, restore it. This is not ceremony:

- A guard written to stop an emblem exemption from widening was **tautological**.
  Only falsification showed it: giving a permanent badge an end date excused it
  from the coverage rule and nothing complained.
- A `now >= 2` floor in the milestone detector was found to be **dead** because
  removing it failed zero tests — `was != null` already implied it.
- A `#98` group went on passing after its premise stopped being true, because
  the counter it called "undrawn" had since been drawn.

When a test *should* fail and does not, that is the finding.

## Editing by script

Anchored `str.replace` in a throwaway script is fine, and often better than
hand-editing a large file. **Every replacement gets an `assert` on the match
count.** Two silently did nothing once, on a branch based on stale main, and the
change looked applied. The formatter also reflows code, so an anchor copied from
memory may no longer match the file — the assert is what tells you.

## Conventions that bite

- Everything is in **English** except l10n content (`app/lib/l10n/*.arb` and the
  `label` fields of the registry). No user-visible string is hard-coded in a
  widget.
- Conventional Commits. Squash-merging means the **pull request title** becomes
  the commit message, so the title follows the convention too.
- Commits are signed, and pull requests are the only way into `main`.
- Do not create a pull request, merge, or dispatch a release unless asked.

## Releases

The procedure lives in the `release` skill (`.claude/skills/release/`) and the
human-facing setup in `docs/release.md`. Two things about it belong here because
they are environment facts rather than procedure.

### Verifying a release

The skill's `apksigner` invocation cannot run here. Parse the APK Signing Block
directly instead — it needs nothing but Python:

1. find the magic `APK Sig Block 42` before the central directory;
2. read the v2 block, id `0x7109871a`;
3. SHA-256 the X.509 certificate in DER.

Expect `CN=FieldTally` and
`9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85`. That
fingerprint is published on the install page, so a mismatch is a broken promise
to every user.

With no emulator, "install it and open About" becomes: read `versionName` from
the manifest, grep the release commit out of `libapp.so`, read the bundled
`changelog.json` and `counters_registry_seed.json` out of the APK, and
cross-check the whole thing against the asset digest GitHub publishes. Download
what the public downloads — never report a release done on a green workflow
alone.

### The changelog and the build number

`app/assets/changelog.json` is keyed by `versionCode`. `settings_screen_test`
fakes a build number, and when that fake collides with a real changelog key the
test's premise ("this build has no notes bundled") silently becomes false. It
was correct for six releases and wrong on the seventh. The fake is now `9999`;
keep it out of the real range.
