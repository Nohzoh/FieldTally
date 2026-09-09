# FieldTally

Suivi de statistiques **Ingress**, mobile-first et **100 % local** : pas de
compte, pas de serveur, aucune donnée envoyée.

> **Statut : squelette.** Le dépôt contient la structure du projet, la stack
> figée et le registre des compteurs. Le parsing des exports, les écrans et les
> garde-fous d'import arrivent à l'itération suivante. Il n'y a pas encore
> d'application installable.

## Non-affiliation

FieldTally est un outil **non-officiel, fan-made**, sans aucun lien avec
Niantic, Inc. « Ingress », les noms de médailles et de compteurs sont des
marques et contenus de Niantic, Inc. Ce projet n'utilise aucun asset protégé.

## Ce que fera l'app (v1)

- Ajouter un relevé en collant le texte de partage d'Ingress Prime, ou
  directement depuis la feuille de partage Android.
- Détecter et **bloquer** un import de période partielle (`WEEK` / `MONTH` /
  `NOW`) qui fausserait silencieusement l'historique.
- Tableau de bord personnalisable, graphique par compteur, heatmap d'activité,
  projections de paliers, objectifs personnels et notifications locales.
- Import CSV depuis Agent Stats, export CSV, carte de stats partageable.

Le détail complet est dans [`docs/spec/SPECIFICATION-v1.md`](docs/spec/SPECIFICATION-v1.md).

## Structure du dépôt

```
app/        projet Flutter (assets/, lib/, test/, tool/)
docs/       site GitHub Pages + spécification + registre des compteurs
tool/       outillage hors-Flutter (validation du registre)
scripts/    outillage local (wrapper gh scopé au projet)
.github/    workflows, templates d'issue, dependabot
```

## Le registre des compteurs

`docs/registry/counters.json` est la **source de vérité** de la catégorisation,
des libellés et des seuils de palier. Ce n'est **pas** la liste des compteurs
supportés : l'app suit tout compteur qu'elle rencontre dans un export, même
inconnu. Le registre ne fait qu'ajouter le confort (catégorie, libellé traduit,
projections).

Il est publié sur GitHub Pages et récupéré par l'app au démarrage, ce qui
permet de déclarer un nouveau compteur d'anomalie par une simple PR, sans
publier de nouvelle version de l'app.

## Démarrer en local

Prérequis : Flutter 3.44+ (canal stable) et le SDK Android.

```bash
cd app
flutter pub get
flutter test
flutter run
```

Régénérer la copie de secours embarquée du registre après avoir modifié
`docs/registry/counters.json` :

```bash
cd app && dart run tool/sync_registry_seed.dart
python3 tool/validate_registry.py   # depuis la racine
```

## Confidentialité

Aucune collecte, aucune télémétrie, aucun compte. Une seule requête réseau dans
toute la v1 : la lecture du fichier public `counters.json` sur GitHub Pages,
sans transmettre la moindre donnée personnelle, et désactivable dans les
préférences.

## Licence

[MIT](LICENSE).
