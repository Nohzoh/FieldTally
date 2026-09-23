#!/usr/bin/env python3
"""Writes the Play Store release notes for one build, from the changelog.

Play takes one plain-text file per locale, named `whatsnew-<BCP 47 locale>`,
and refuses a file over 500 characters. The notes an agent reads in the store
and the notes the app shows after an update are the same notes, so they are
written once, in `app/assets/changelog.json`, and read from there rather than
retyped into the console.

The section headings come from the app's own translations, so the store page
says what the app says, in both languages.

    python3 tool/play_release_notes.py <versionCode> <directory>
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANGELOG = ROOT / "app/assets/changelog.json"
ARB = ROOT / "app/lib/l10n/app_{language}.arb"

# The languages the app is translated into, mapped to the locales the Play
# listing is written in. A language with no listing would upload notes Play
# silently ignores.
LOCALES = {"en": "en-US", "fr": "fr-FR"}

# Play's own limit, per locale. Enforced here rather than discovered halfway
# through an upload, when the tag already exists.
LIMIT = 500


def heading(language: str, key: str) -> str:
    arb = json.loads(ARB.with_name(ARB.name.format(language=language)).read_text(encoding="utf-8"))
    return arb[key]


def notes(entry: dict, language: str) -> str:
    lines = [entry["title"][language]]

    for section, key in (("features", "changelogNewHeading"), ("fixes", "changelogFixedHeading")):
        items = entry.get(section, {}).get(language, [])
        if not items:
            continue
        lines.append("")
        lines.append(heading(language, key))
        lines.extend(f"• {item}" for item in items)

    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    code, directory = sys.argv[1], Path(sys.argv[2])

    changelog = json.loads(CHANGELOG.read_text(encoding="utf-8"))
    entry = changelog.get(code)
    if entry is None:
        print(
            f"::error::{CHANGELOG.relative_to(ROOT)} has no entry for versionCode {code}. "
            "The release notes are written with the version bump, not afterwards.",
            file=sys.stderr,
        )
        return 1

    written = {}
    for language, locale in LOCALES.items():
        text = notes(entry, language)
        if len(text) > LIMIT:
            print(
                f"::error::The {language} notes for versionCode {code} are {len(text)} "
                f"characters and Play accepts {LIMIT}. Shorten them in "
                f"{CHANGELOG.relative_to(ROOT)}.",
                file=sys.stderr,
            )
            return 1
        written[locale] = text

    directory.mkdir(parents=True, exist_ok=True)
    for locale, text in written.items():
        (directory / f"whatsnew-{locale}").write_text(text + "\n", encoding="utf-8")
        print(f"{directory}/whatsnew-{locale} — {len(text)} characters")

    return 0


if __name__ == "__main__":
    sys.exit(main())
