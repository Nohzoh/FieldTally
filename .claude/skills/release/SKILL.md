---
name: release
description: Cut a FieldTally release — close the milestone, bump the version, tag, watch the workflow, and verify the published APK. Use when asked to release, to tag a version, or to prepare the next release.
---

# Cutting a release

The pipeline is `.github/workflows/release.yml`. It triggers on a `v*` tag or a
manual dispatch, holds the signing key, and is never triggered by a pull
request. Keystore setup and the human-facing procedure are in
[`docs/release.md`](../../../docs/release.md) — this file is the operating
procedure.

All `gh` calls go through `./scripts/gh` from the repository root.

## 1. Close the milestone

Work is batched: issues land in a backlog, a subset goes into the **Next
Release** milestone, and the milestone is renamed to the version when it ships.

```sh
./scripts/gh issue list --milestone "Next Release" --state open
```

Anything still open either gets finished, or moved out of the milestone with
the reason said out loud. Do not ship a milestone with open issues silently.

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
person reading the dialog. Two groups, `features` and `fixes`, each a plain
list of short sentences in the same register as the release notes.

Same commit as the version bump. Bundled at build time, never fetched: the app
promises to work with no network, and a screen that only appears after an
update must not depend on being online.

## 4. Check the ground is solid

```sh
cd app && flutter analyze && flutter test
./scripts/gh pr list          # nothing unexpected still open
git log --oneline -1          # main, up to date with origin
```

A release built on anything but a clean, pushed `main` is a release nobody can
reproduce.

## 5. Release

The workflow does the tagging. Dispatch it with the version, without the
leading `v`:

```sh
./scripts/gh workflow run release.yml -f version=X.Y.Z
```

It refuses immediately if that version disagrees with `app/pubspec.yaml` —
which is what catches a dispatch fired before the bump was merged. It then
builds, proves the APK carries the real signing key, and only then creates
the tag and publishes. Nothing is tagged for a release that failed to build.

`-f dry_run=true` stops after the signing check, at a downloadable artifact:
no tag, no release. Use it when the question is whether signing works.

Dispatching without `dry_run` is the irreversible step: it produces a public
tag and a public signed APK. Confirm with the user before firing it unless
they have already said to go ahead.

The tag is annotated but unsigned, created by `github-actions[bot]`. Only the
Android signing key lives in the workflow, deliberately, so what proves a
release genuine is the APK's certificate — printed in the job summary and
published on the install page — rather than the tag. A tag pushed by hand
still works and can be signed the usual way:

```sh
git tag -s vX.Y.Z -m "FieldTally X.Y.Z" && git push origin vX.Y.Z
```

## 6. Watch the workflow

Use a Monitor on the run rather than polling. The workflow refuses to continue
if the secrets are missing or if the APK turns out to be debug-signed — both
failures are loud by design.

## 7. Verify the published artefact

Never report a release as done on the strength of a green workflow. Download
what the public downloads and check it:

```sh
curl -sL -o /tmp/published.apk \
  "https://github.com/Nohzoh/FieldTally/releases/download/vX.Y.Z/fieldtally-X.Y.Z.apk"
"$ANDROID_HOME"/build-tools/*/apksigner verify --print-certs /tmp/published.apk
```

Expect exactly:

```
certificate DN: CN=FieldTally, ...
certificate SHA-256 digest: 9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
```

That fingerprint is published on the install page, so a mismatch is a broken
promise to every user, not a detail. Then install that APK on the emulator and
open Settings → About: it must name the version and the release commit.

`keytool -printcert -jarfile` is useless here — `minSdk` is 26, so the APK
carries a v2/v3 signature and no v1 JAR signature, and keytool reports a
correctly signed APK as unsigned.

## 8. Afterwards

- Rename the milestone to the version, and create a fresh empty **Next
  Release**.
- Re-read anything that claims a state the release changed: the site's home
  page, the README, the install page.
- Tell the user the fingerprint and the commit the build carries.

## Traps already paid for

- **The keystore password is single.** PKCS12 ignores a separate key password;
  `keytool` warns and drops it. Two different passwords fail much later, at
  packaging, with `Given final block not properly padded`.
- **Gradle falls back to the debug key** when `android/key.properties` is
  absent, silently. A debug-signed APK installs perfectly well and can never be
  replaced by a later update — which is why step 6 is not optional.
- **A different signing key means no update path.** Anyone who installed a
  debug build must uninstall before installing a release, losing their local
  database. Tell them to export their CSV first.
