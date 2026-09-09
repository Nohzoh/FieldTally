#!/usr/bin/env python3
"""Validates docs/registry/counters.json before any deployment (§3.1.4, §7.3).

This is the only thing standing between a malformed pull request and broken
categorisation for every user at once: the file is fetched at startup by every
install of the app.

Checks: valid JSON, well-formed counter keys, categories from the allowed list,
no duplicates (key or export header), strictly increasing badge thresholds.

    python3 tool/validate_registry.py [path]
"""

import json
import re
import sys
from pathlib import Path

KEY_RE = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*$")
REQUIRED = ("export_header", "category", "order", "label")


def validate(path: Path) -> list[str]:
    errors: list[str] = []

    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"unreadable or invalid JSON: {exc}"]

    if not isinstance(doc, dict):
        return ["the root must be a JSON object"]

    for field in ("schema_version", "updated_at", "categories", "counters"):
        if field not in doc:
            errors.append(f"missing root field: {field}")
    if errors:
        return errors

    # --- Categories ---
    categories = doc["categories"]
    if not isinstance(categories, list) or not categories:
        return ["'categories' must be a non-empty list"]

    allowed: set[str] = set()
    seen_order: dict[int, str] = {}
    for i, cat in enumerate(categories):
        where = f"categories[{i}]"
        if not isinstance(cat, dict):
            errors.append(f"{where}: must be an object")
            continue
        key = cat.get("key")
        if not isinstance(key, str) or not KEY_RE.match(key):
            errors.append(f"{where}: malformed category key ({key!r})")
            continue
        if key in allowed:
            errors.append(f"{where}: duplicate category ({key!r})")
        allowed.add(key)
        order = cat.get("order")
        if not isinstance(order, int):
            errors.append(f"{where}: 'order' must be an integer")
        elif order in seen_order:
            errors.append(
                f"{where}: 'order' {order} already used by {seen_order[order]!r}"
            )
        else:
            seen_order[order] = key
        label = cat.get("label")
        if not isinstance(label, dict) or not label.get("en") or not label.get("fr"):
            errors.append(f"{where}: 'label' must carry non-empty 'en' and 'fr'")

    # --- Counters ---
    counters = doc["counters"]
    if not isinstance(counters, dict):
        return errors + ["'counters' must be an object"]

    headers: dict[str, str] = {}
    for key, entry in counters.items():
        where = f"counters.{key}"
        if not KEY_RE.match(key):
            errors.append(f"{where}: malformed key (snake_case expected)")
        if not isinstance(entry, dict):
            errors.append(f"{where}: must be an object")
            continue

        for field in REQUIRED:
            if field not in entry:
                errors.append(f"{where}: missing field '{field}'")

        header = entry.get("export_header")
        if not isinstance(header, str) or not header.strip():
            errors.append(f"{where}: 'export_header' must be a non-empty string")
        elif header in headers:
            errors.append(
                f"{where}: 'export_header' {header!r} already used by "
                f"{headers[header]!r} — one export header can only name "
                f"one counter"
            )
        else:
            headers[header] = key

        category = entry.get("category")
        if category not in allowed:
            errors.append(
                f"{where}: unknown category ({category!r}) — "
                f"allowed: {sorted(allowed)}"
            )

        if not isinstance(entry.get("order"), int):
            errors.append(f"{where}: 'order' must be an integer")

        label = entry.get("label")
        if not isinstance(label, dict) or not label.get("en") or not label.get("fr"):
            errors.append(f"{where}: 'label' must carry non-empty 'en' and 'fr'")

        if "periodized" in entry and not isinstance(entry["periodized"], bool):
            errors.append(f"{where}: 'periodized' must be a boolean")

        # Badge thresholds (§3.6): optional, but strictly increasing.
        tiers = entry.get("tiers")
        if tiers is not None:
            if not isinstance(tiers, list) or not tiers:
                errors.append(f"{where}: 'tiers' must be a non-empty list")
                continue
            values = []
            for j, tier in enumerate(tiers):
                if not isinstance(tier, dict):
                    errors.append(f"{where}.tiers[{j}]: must be an object")
                    continue
                name, value = tier.get("name"), tier.get("value")
                if not isinstance(name, str) or not name:
                    errors.append(f"{where}.tiers[{j}]: missing 'name'")
                if not isinstance(value, (int, float)) or isinstance(value, bool):
                    errors.append(f"{where}.tiers[{j}]: 'value' must be a number")
                else:
                    values.append(value)
            if values != sorted(set(values)) or len(values) != len(set(values)):
                errors.append(
                    f"{where}: badge thresholds must be strictly increasing "
                    f"(got: {values})"
                )

    # Every declared category must be used, except the catch-all 'other',
    # which is the app-side fallback for counters not yet enriched.
    used = {e.get("category") for e in counters.values() if isinstance(e, dict)}
    for unused in sorted(allowed - used - {"other"}):
        errors.append(f"declared but unused category: {unused!r}")

    return errors


def main() -> int:
    default = Path(__file__).resolve().parent.parent / "docs/registry/counters.json"
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else default

    errors = validate(path)
    if errors:
        print(f"❌ {path}: {len(errors)} error(s)", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    doc = json.loads(path.read_text(encoding="utf-8"))
    print(
        f"✅ {path} is valid — {len(doc['counters'])} counters, "
        f"{len(doc['categories'])} categories."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
