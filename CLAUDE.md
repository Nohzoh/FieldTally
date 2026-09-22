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

## Seeing the site

`docs/` has had its own layout and stylesheet since #139, so a change there has
to be looked at rather than reasoned about. The proxy blocks `github.io`, so
the published site cannot be fetched from here — building it locally is the
only way to see it at all.

Ruby is already installed and on `PATH`. Jekyll is not:

```sh
gem install jekyll                        # 4.4.1 at the time of writing
export PATH=/opt/rbenv/versions/3.3.6/bin:$PATH   # where the binstub lands
jekyll build --source docs --destination /tmp/site
```

**Serve it over HTTP. A preview opened as `file://` shows an unstyled page**,
and that has already been mistaken for a broken stylesheet. The cause is not
the CSS: `relative_url` emits root-absolute paths — `/assets/css/site.css` —
which `file://` resolves against the filesystem root. `python3 -m http.server`
from the destination directory is enough.

`--baseurl ''` is harmless but does nothing locally: `_config.yml` declares no
`baseurl`, because `actions/jekyll-build-pages` injects the real one. So the
local build links `/assets/…` where the published site links `/FieldTally/…`.
That is expected, not a defect to chase.

Then look at it at phone size, which is the size that matters:

```python
# pip install playwright — but never `playwright install`: the browsers are
# already under PLAYWRIGHT_BROWSERS_PATH.
b = p.chromium.launch(
    executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome')
ctx = b.new_context(viewport={'width': 390, 'height': 844},
                    device_scale_factor=2)
page = ctx.new_page()
page.emulate_media(color_scheme='dark')   # the only way to see the dark palette
page.goto(url, wait_until='networkidle')
page.screenshot(path=…, full_page=True)
```

`document.documentElement.scrollHeight` is worth printing alongside: #139's
first draft rendered the home page at 3999 CSS pixels because three screenshots
sat at full width each, and the number said so before the image did.

The local build is **not** the published one. GitHub builds with
`ghcr.io/actions/jekyll-build-pages`, which emits an `assets/css/style.css`
that the local build does not — nothing references it, but it is a reminder
that the two differ. And as with the test font above, the render here is
evidence, not a verdict: the maintainer reads this site on a phone.

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
- **Every change to the app answers to an issue** (#125, narrowed by #144).
  The app is `app/` — code, assets, l10n — plus the release workflow. The pull
  request names it: `Closes #N` when it finishes the issue, `Refs #N` when it is
  one step of it. Open the issue first; when work has already landed without
  one, open it after the fact rather than leaving the gap. The reason is the
  changelog and nothing else: notes are written from the milestone, so an app
  change with no issue is invisible when they are written.
- **That issue needs the Next Release milestone too, by merge time.** Existing
  is not enough — notes are written *from the milestone*, so an issue still
  sitting in the backlog when its pull request merges to `main` is as invisible
  as having no issue at all. Assign the **Next Release** milestone to it
  yourself when you open the issue or merge the change; do not wait for the
  maintainer to triage it in later. Renaming a milestone to a shipped version
  and opening the next empty **Next Release** is the maintainer's call, made at
  release time (release skill, step 8) — never do that yourself.
- **Documentation, the site, skills and tooling do not need one** (#144). An
  issue there is welcome when the change has a *why* worth keeping apart from
  the diff, and optional otherwise. The counter registry is on this side as
  well: it reaches installed apps by itself, never through a release, so it
  never appears in release notes.
- **The release bump is excepted even though it touches the app** (#127): the
  commit that sets the version and writes that release's changelog entry, with
  any site page the release made stale. It cannot go missing from the notes,
  because it *is* the notes.
- Do not create a pull request, merge, or dispatch a release unless asked.

## Releases

The procedure lives in the `release` skill (`.claude/skills/release/`) and the
human-facing setup in `docs/release.md`. Two things about it belong here because
they are environment facts rather than procedure.

### Verifying a release

Nothing is published to GitHub any more (#198): the release produces a tag and
an App Bundle attached to the run as an artifact, and the app reaches people
through the Play Store. Two consequences for an agent here.

**The artifact cannot be downloaded from this container.** The signed URL
points at Azure blob storage, which the proxy refuses. What can be read is the
job log: the "Verify the bundle is not debug-signed" step prints the whole
certificate, fingerprint included. Expect `CN=FieldTally` and
`9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85`. That
fingerprint is published on the install page, so a mismatch is a broken promise
to every user.

**A green workflow is not a shipped release.** It means a bundle exists and
carries the right key. What people install is what the Play Console rolled out,
which only the maintainer can confirm today — so report the build as built, and
the release as done only once they say it is live.

### The changelog and the build number

Release notes are written from the milestone, which is the whole reason for the
issue rule above: app work with no issue is invisible to them. It has already
cost one — an emblem reached `main` untracked and would have gone unmentioned.
Read the merged pull requests since the last tag as well. If one touched `app/`
and has no issue, that is the defect, not the changelog's — the bump excepted.
If it touched only documentation or tooling, it needs no issue (#144) and
belongs in the notes only if a user would notice it.

`app/assets/changelog.json` is keyed by `versionCode`. `settings_screen_test`
fakes a build number, and when that fake collides with a real changelog key the
test's premise ("this build has no notes bundled") silently becomes false. It
was correct for six releases and wrong on the seventh. The fake is now `9999`;
keep it out of the real range.
