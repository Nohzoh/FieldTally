#!/usr/bin/env python3
"""Write what the newest published release is, for the app to read (#34).

FieldTally is installed by sideload, so an agent running 1.2.0 has no way of
learning that 1.8.0 exists: Android tells them nothing, and there is no store
to do it for us.

The app already fetches one file from the project site at startup — the counter
registry (SS3.1.4). This adds a second, tiny one beside it, so detection needs no
new mechanism and no new permission.

Generated at deploy time rather than committed, exactly like `docs/coverage.json`
next to it. Two reasons:

  * the source of truth is the git tag the release workflow creates, and a
    committed file would be a second place to keep in step with it;
  * nothing has to push to `main` from CI. Pull requests are the only way in,
    and a bot commit would be an exception carved for a two-line file.

The cost is that Pages has to rebuild after a release for the file to catch up,
which is why `release.yml` dispatches it once the tag exists.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

# `v1.8.0`, and nothing else. A tag that does not parse is not a release this
# file should ever advertise.
TAG = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")


def tags() -> list[str]:
    out = subprocess.run(
        ["git", "tag", "--list", "v*"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return [line.strip() for line in out.splitlines() if TAG.match(line.strip())]


def newest(candidates: list[str]) -> str | None:
    """Highest by version number, never by tag date.

    A tag can be recreated, and `--sort=-creatordate` would then hand an older
    version to every installed app at once.
    """
    if not candidates:
        return None
    return max(candidates, key=lambda t: tuple(int(p) for p in TAG.match(t).groups()))


def build_code(tag: str) -> int | None:
    """The `versionCode` that tag shipped, read from the file it tagged.

    The app compares build codes rather than version names: the code is what
    Android itself orders updates by, and comparing it needs no semver parsing
    on the device.
    """
    try:
        pubspec = subprocess.run(
            ["git", "show", f"{tag}:app/pubspec.yaml"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    except subprocess.CalledProcessError:
        return None

    match = re.search(r"^version:\s*\d+\.\d+\.\d+\+(\d+)\s*$", pubspec, re.MULTILINE)
    return int(match.group(1)) if match else None


def main() -> int:
    destination = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/latest.json")

    tag = newest(tags())
    if tag is None:
        # A checkout with no tags is a normal state — a fork, or a shallow
        # clone that fetched none. Writing nothing is better than writing a
        # file that claims there is no release.
        print("no release tag found; leaving", destination, "alone")
        return 0

    code = build_code(tag)
    if code is None:
        print(f"{tag} carries no readable build code; leaving {destination} alone")
        return 0

    payload = {
        "version": tag[1:],
        "build": code,
        "url": f"https://github.com/Nohzoh/FieldTally/releases/tag/{tag}",
    }

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {destination}: {payload['version']} (build {code})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
