---
name: release
description: Cut a FieldTally release — close the milestone, bump the version, tag, watch the workflow, and verify the signed App Bundle it produces for the Play Store. Use when asked to release, to tag a version, or to prepare the next release.
---

# Cutting a release

The pipeline is `.github/workflows/release.yml`. It triggers on a `v*` tag or a
manual dispatch, holds the signing key, and is never triggered by a pull
request. Keystore setup and the human-facing procedure are in
[`docs/release.md`](../../../docs/release.md) — this file is the operating
procedure.

GitHub operations below are written as `gh` commands because that is what a
maintainer runs. An agent in the sandbox has no token for it and uses the GitHub
MCP tools instead — see `CLAUDE.md`, which also covers what cannot be run here
at all.

## 1. Close the milestone

Work is batched: issues land in a backlog, a subset goes into the **Next
Release** milestone, and the milestone is renamed to the version when it ships.

```sh
gh issue list --milestone "Next Release" --state open
```

Anything still open either gets finished, or moved out of the milestone with
the reason said out loud. Do not ship a milestone with open issues silently.

Then read the pull requests merged since the last tag, not the milestone alone.
Every change **to the app** is supposed to answer to an issue (#125, narrowed by
#144), so for those the two should agree — and where they do not, the missing
issue is the defect. Open it rather than letting the work go unmentioned.

A pull request that touched only documentation, the site or tooling needs no
issue and will legitimately be absent from the milestone. It is not a defect;
mention it in the notes only if a user would notice the difference.

The bump written in the next two steps is the exception (#127), so do not go
looking for its issue: it is the changelog entry, and cannot be missing from
itself.

## 2. Decide the version

`app/pubspec.yaml` carries `version: <name>+<code>`.

- **The build code must strictly increase.** Android refuses an update whose
  `versionCode` is not higher, and there is no recovering from a released one
  that is too high.
- The code means "the Nth release" — one increment per release. It is
  deliberately not a PR or issue number: a release is a point on `main`, not a
  pull request, and issues share GitHub's counter. Traceability to the source
  comes from the commit shown in the About screen.
- The name follows semver against what actually changed.

Bump it in its own commit on a branch, through a pull request like anything
else.

## 3. Write the changelog entry

`app/assets/changelog.json`, keyed by the `versionCode` just decided above.
Written by hand in both languages, from the milestone's issues — but not from
their titles: those are English and written for contributors, not for the
person reading the dialog.

Three parts. A `title`, one line summing the release up — that is the whole of
what the dialog after an update shows (#112), so it is the sentence that gets
read. Then `features` and `fixes`, each a plain list of short sentences in the
same register as the release notes; those are for Settings → About, and for
anyone with no network.

A release that forgets its headline fails `changelog_test`, in both languages.

Same commit as the version bump. Bundled at build time, never fetched: the app
promises to work with no network, and a screen that only appears after an
update must not depend on being online.

## 4. Check the ground is solid

```sh
cd app
dart run tool/sync_registry_seed.dart --check
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze && flutter test
cd .. && python3 tool/validate_registry.py
gh pr list                    # nothing unexpected still open
git log --oneline -1          # main, up to date with origin
```

These are the checks CI replays, in its order. `CLAUDE.md` has the full list,
including the two generated-file checks this abbreviates.

A release built on anything but a clean, pushed `main` is a release nobody can
reproduce.

## 5. Release

The workflow does the tagging. Dispatch it with the version, without the
leading `v`:

```sh
gh workflow run release.yml -f version=X.Y.Z
```

It refuses immediately if that version disagrees with `app/pubspec.yaml` —
which is what catches a dispatch fired before the bump was merged. It then
builds the App Bundle, proves it carries the real signing key, and only then
creates the tag. Nothing is tagged for a release that failed to build, and
nothing is published to GitHub: the app reaches people through the Play Store
(#198).

`-f dry_run=true` stops after the signing check, at the same artifact, with no
tag. Use it when the question is whether signing works — or to produce a bundle
for Play without tagging.

The job's last step sends the bundle to the closed-testing track as a draft
release, with notes generated from `app/assets/changelog.json`. It is skipped
by a dry run, and by `-f publish_to_play=false` on a real one.

Dispatching without `dry_run` is the irreversible step, and doubly so now: it
produces a public tag, and it hands Play a `versionCode` that Play will never
accept again. Confirm with the user before firing it unless they have already
said to go ahead.

The tag is annotated but unsigned, created by `github-actions[bot]`. Only the
Android signing key lives in the workflow, deliberately, so what proves a build
genuine is its certificate — printed in the job summary and published on the
install page — rather than the tag. A tag pushed by hand still works and can be
signed the usual way:

```sh
git tag -s vX.Y.Z -m "FieldTally X.Y.Z" && git push origin vX.Y.Z
```

## 6. Watch the workflow

Use a Monitor on the run rather than polling. The workflow refuses to continue
if the secrets are missing or if the bundle turns out to be debug-signed — both
failures are loud by design.

## 7. Verify what was built, then what shipped

Never report a release as done on the strength of a green workflow.

The certificate is printed in full by the "Verify the bundle is not
debug-signed" step, and summarised in the job summary. Expect
`CN=FieldTally` and:

```
9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
```

That fingerprint is published on the install page, so a mismatch is a broken
promise to every user, not a detail. On a machine with the bundle downloaded,
`keytool -printcert -jarfile fieldtally-X.Y.Z.aab` says the same thing — a
bundle carries the v1 JAR signature `keytool` reads.

Then the part no workflow can answer: what people install is what the Play
Console rolled out. The upload happens by itself, but it lands as a draft, so
ask the user to confirm the version is live before calling the release done.

If the Play step failed while the rest went green, say so plainly: the tag is
real and the store has nothing. The bundle is in the run's artifact and the
upload has to be finished by hand, because that `versionCode` can be sent to
Play only once.

## 8. Afterwards

- Rename the milestone to the version, and create a fresh empty **Next
  Release**.
- Re-read anything that claims a state the release changed: the site's home
  page, the README, the install page — **in both languages**. The site carries
  a full English mirror under `docs/en/`, and nothing checks that the two stay
  in step. Twice now a correction landed in French only, once leaving the
  English pages telling agents to download a file that does not exist (#137).
- Tell the user the fingerprint and the commit the build carries.

## Traps already paid for

- **The changelog key and the faked build number collide.** `changelog.json` is
  keyed by `versionCode`, and `settings_screen_test` fakes one. When the fake
  matches a real entry, the test's premise quietly inverts. It was correct for
  six releases and wrong on the seventh; the fake is now `9999`.
- **The registry ships faster than the code.** The registry is fetched at
  startup (§3.1.4), so a registry change reaches installed apps at their next
  launch while code waits for a release. Data only newer code can read must
  ship *after* that release, never in the same breath.

- **The keystore password is single.** PKCS12 ignores a separate key password;
  `keytool` warns and drops it. Two different passwords fail much later, at
  packaging, with `Given final block not properly padded`.
- **Gradle falls back to the debug key** when `android/key.properties` is
  absent, silently. A debug-signed build installs perfectly well and can never
  be replaced by a later update, and Play rejects it against the app signing
  key — which is why step 6 is not optional.
- **A different signing key means no update path.** Anyone who installed a
  debug build must uninstall before installing a release, losing their local
  database. Tell them to export their CSV first.
