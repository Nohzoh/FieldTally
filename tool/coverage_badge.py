#!/usr/bin/env python3
"""Turns an lcov report into a shields.io endpoint file (§7.1).

Self-hosted on the project's own Pages site rather than sent to Codecov or
Coveralls: no third-party service, no token, and no report leaving the
project — which is the least an app arguing that it sends nothing anywhere
can do.

The percentage is decoration and is deliberately given no authority: there is
no threshold here and none in CI. Two bugs shipped in covered code during the
v1.0.0 cycle, so the number says which lines ran, not which behaviour was
verified. What is actionable is the list this prints on the way out: the files
no test touches at all.

    python3 tool/coverage_badge.py <lcov.info> <endpoint.json>
"""

import json
import sys
from pathlib import Path


def totals(lcov: str) -> tuple[int, int, list[str]]:
    """Lines hit, lines found, and the files nothing covers."""
    hit = found = 0
    uncovered: list[str] = []
    current = ""
    file_hit = 0

    for line in lcov.splitlines():
        if line.startswith("SF:"):
            current = line[3:]
            file_hit = 0
        elif line.startswith("LH:"):
            file_hit = int(line[3:])
            hit += file_hit
        elif line.startswith("LF:"):
            found += int(line[3:])
        elif line == "end_of_record" and current and file_hit == 0:
            uncovered.append(current)

    return hit, found, uncovered


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    lcov_path, endpoint_path = Path(sys.argv[1]), Path(sys.argv[2])
    hit, found, uncovered = totals(lcov_path.read_text(encoding="utf-8"))

    if found == 0:
        print(f"❌ {lcov_path} reports no lines at all", file=sys.stderr)
        return 1

    percent = round(hit * 100 / found)

    # One fixed colour, not a scale. A scale would grade the number, and the
    # point of the paragraph above is that the number does not deserve a grade.
    endpoint_path.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "label": "coverage",
                "message": f"{percent}%",
                "color": "blue",
            }
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"✅ {endpoint_path}: {percent}% ({hit}/{found} lines)")
    if uncovered:
        print(f"\n{len(uncovered)} file(s) no test covers:")
        for path in sorted(uncovered):
            print(f"  - {path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
