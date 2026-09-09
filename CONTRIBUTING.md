# Contribuer à FieldTally

## La contribution la plus utile : déclarer un compteur

Quand une anomalie démarre, Ingress ajoute de nouveaux compteurs à l'export.
L'app les suit **automatiquement** — mais ils s'affichent sous leur nom brut,
dans la catégorie « Autres », tant que personne ne les a déclarés.

Les déclarer proprement demande de modifier **un seul fichier**, sans écrire
une ligne de Dart : [`docs/registry/counters.json`](docs/registry/counters.json).

Une entrée ressemble à ça :

```json
"orion_tokens": {
  "export_header": "Orion Tokens",
  "category": "events",
  "order": 6,
  "label": { "en": "Orion Tokens", "fr": "Jetons Orion" }
}
```

- `export_header` doit être **exactement** le nom de la colonne dans l'export
  Ingress — c'est par lui que l'app fait la correspondance.
- `category` doit être une des clés déclarées dans `categories` en haut du
  fichier ; on reprend la catégorisation de l'écran de stats du jeu.
- `order` positionne le compteur à l'intérieur de sa catégorie.
- `tiers` est optionnel — n'ajoute des seuils de palier que si tu les connais
  de source sûre, et par valeurs strictement croissantes.

Avant d'ouvrir la PR :

```bash
python3 tool/validate_registry.py
cd app && dart run tool/sync_registry_seed.dart
```

Le second régénère `app/assets/counters_registry_seed.json`, la copie de
secours embarquée dans l'app. **Ne l'édite jamais à la main** : la CI vérifie
qu'il correspond bien au fichier de `docs/`.

## Contribuer au code

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

Ces trois commandes doivent passer — la CI les rejoue sur chaque PR, plus un
build APK de debug.

### Organisation du code (§5.2 de la spec)

```
lib/
  data/           parsing (texte Ingress, CSV), accès Drift, repositories
  domain/         modèles métier, calculs (diffs, projections)
  presentation/   écrans, widgets, providers Riverpod
  core/           constantes, thème, i18n
```

Principe directeur : la logique métier (parsing, projections) ne dépend jamais
de l'UI, et les écrans ne parlent qu'à des repositories — pour qu'ajouter un
backend en v2 ne demande pas de réécrire l'interface.

### Fixtures de test

Les échantillons d'export vivent dans `app/test/fixtures/`. **Aucune fixture ne
doit contenir un pseudo Ingress réel ni des valeurs traçables jusqu'à un compte
identifiable.** Avant de committer un nouvel échantillon : pseudo remplacé par
un nom générique, date neutralisée, et toutes les valeurs numériques
multipliées par un même facteur d'échelle (ce qui préserve les proportions et
les zéros, donc l'intérêt du fixture pour les tests).

## Signaler un problème

Deux templates d'issue existent : un pour « le parsing ne fonctionne pas »
(pense à anonymiser ton extrait), un pour « ajouter ou corriger un compteur ».

## Licence

En contribuant, tu acceptes que ta contribution soit publiée sous licence
[GNU AGPL v3](LICENSE), comme le reste du projet.
