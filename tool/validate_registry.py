#!/usr/bin/env python3
"""Valide docs/registry/counters.json avant tout déploiement (spec §3.1.4, §7.3).

C'est le seul rempart contre une PR qui casserait la catégorisation pour tous
les utilisateurs d'un coup : ce fichier est récupéré au démarrage par toutes
les installations de l'app.

Vérifie : JSON valide, clés de compteur bien formées, catégories dans la liste
autorisée, pas de doublon (clé ou en-tête d'export), seuils de palier croissants.

    python3 tool/validate_registry.py [chemin]
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
        return [f"illisible ou JSON invalide : {exc}"]

    if not isinstance(doc, dict):
        return ["la racine doit être un objet JSON"]

    for field in ("schema_version", "updated_at", "categories", "counters"):
        if field not in doc:
            errors.append(f"champ racine manquant : {field}")
    if errors:
        return errors

    # --- Catégories ---
    categories = doc["categories"]
    if not isinstance(categories, list) or not categories:
        return ["'categories' doit être une liste non vide"]

    allowed: set[str] = set()
    seen_order: dict[int, str] = {}
    for i, cat in enumerate(categories):
        where = f"categories[{i}]"
        if not isinstance(cat, dict):
            errors.append(f"{where} : doit être un objet")
            continue
        key = cat.get("key")
        if not isinstance(key, str) or not KEY_RE.match(key):
            errors.append(f"{where} : clé de catégorie mal formée ({key!r})")
            continue
        if key in allowed:
            errors.append(f"{where} : catégorie en doublon ({key!r})")
        allowed.add(key)
        order = cat.get("order")
        if not isinstance(order, int):
            errors.append(f"{where} : 'order' doit être un entier")
        elif order in seen_order:
            errors.append(
                f"{where} : 'order' {order} déjà utilisé par {seen_order[order]!r}"
            )
        else:
            seen_order[order] = key
        label = cat.get("label")
        if not isinstance(label, dict) or not label.get("en") or not label.get("fr"):
            errors.append(f"{where} : 'label' doit contenir 'en' et 'fr' non vides")

    # --- Compteurs ---
    counters = doc["counters"]
    if not isinstance(counters, dict):
        return errors + ["'counters' doit être un objet"]

    headers: dict[str, str] = {}
    for key, entry in counters.items():
        where = f"counters.{key}"
        if not KEY_RE.match(key):
            errors.append(f"{where} : clé mal formée (attendu snake_case)")
        if not isinstance(entry, dict):
            errors.append(f"{where} : doit être un objet")
            continue

        for field in REQUIRED:
            if field not in entry:
                errors.append(f"{where} : champ manquant '{field}'")

        header = entry.get("export_header")
        if not isinstance(header, str) or not header.strip():
            errors.append(f"{where} : 'export_header' doit être une chaîne non vide")
        elif header in headers:
            errors.append(
                f"{where} : 'export_header' {header!r} déjà utilisé par "
                f"{headers[header]!r} — un en-tête d'export ne peut désigner "
                f"qu'un seul compteur"
            )
        else:
            headers[header] = key

        category = entry.get("category")
        if category not in allowed:
            errors.append(
                f"{where} : catégorie inconnue ({category!r}) — "
                f"autorisées : {sorted(allowed)}"
            )

        if not isinstance(entry.get("order"), int):
            errors.append(f"{where} : 'order' doit être un entier")

        label = entry.get("label")
        if not isinstance(label, dict) or not label.get("en") or not label.get("fr"):
            errors.append(f"{where} : 'label' doit contenir 'en' et 'fr' non vides")

        if "periodized" in entry and not isinstance(entry["periodized"], bool):
            errors.append(f"{where} : 'periodized' doit être un booléen")

        # Seuils de palier (§3.6) : optionnels, mais strictement croissants.
        tiers = entry.get("tiers")
        if tiers is not None:
            if not isinstance(tiers, list) or not tiers:
                errors.append(f"{where} : 'tiers' doit être une liste non vide")
                continue
            values = []
            for j, tier in enumerate(tiers):
                if not isinstance(tier, dict):
                    errors.append(f"{where}.tiers[{j}] : doit être un objet")
                    continue
                name, value = tier.get("name"), tier.get("value")
                if not isinstance(name, str) or not name:
                    errors.append(f"{where}.tiers[{j}] : 'name' manquant")
                if not isinstance(value, (int, float)) or isinstance(value, bool):
                    errors.append(f"{where}.tiers[{j}] : 'value' doit être un nombre")
                else:
                    values.append(value)
            if values != sorted(set(values)) or len(values) != len(set(values)):
                errors.append(
                    f"{where} : les seuils de palier doivent être strictement "
                    f"croissants (reçu : {values})"
                )

    # Chaque catégorie déclarée doit servir, sauf le fourre-tout 'other' qui est
    # la catégorie de repli côté app pour les compteurs pas encore enrichis.
    used = {e.get("category") for e in counters.values() if isinstance(e, dict)}
    for unused in sorted(allowed - used - {"other"}):
        errors.append(f"catégorie déclarée mais inutilisée : {unused!r}")

    return errors


def main() -> int:
    default = Path(__file__).resolve().parent.parent / "docs/registry/counters.json"
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else default

    errors = validate(path)
    if errors:
        print(f"❌ {path} : {len(errors)} erreur(s)", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    doc = json.loads(path.read_text(encoding="utf-8"))
    print(
        f"✅ {path} valide — {len(doc['counters'])} compteurs, "
        f"{len(doc['categories'])} catégories."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
