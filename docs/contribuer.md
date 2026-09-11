---
layout: default
title: Contribuer
lang_alt: /en/contributing
---
{% include nav-fr.html %}

# Contribuer

## Déclarer un compteur — sans écrire de code

C'est la contribution la plus utile, et elle ne demande pas d'être développeur.

Quand Niantic ajoute un compteur — typiquement pendant une anomalie — l'app le
suit immédiatement, mais sous son nom d'origine et dans la catégorie « Autres ».
Pour lui donner un nom, une catégorie et des seuils de médaille, il suffit
d'ajouter une entrée dans un seul fichier :

[`docs/registry/counters.json`](https://github.com/Nohzoh/FieldTally/blob/main/docs/registry/counters.json)

Ce fichier est téléchargé par toutes les installations au démarrage : ta
correction arrive chez tout le monde **sans nouvelle version de l'app**. Une
vérification automatique refuse le fichier s'il est malformé, donc il n'y a
aucun risque de casser l'app des autres.

## Signaler un problème d'import

C'est le point de fragilité du projet : le format de partage d'Ingress n'est pas
documenté et peut changer. Si l'import échoue,
[ouvre une issue](https://github.com/Nohzoh/FieldTally/issues/new) avec un
extrait du texte partagé. Remplace ton nom d'agent si tu veux — seuls les noms
de colonnes sont utiles pour diagnostiquer.

## Développer

Le projet est en Flutter. Pour le lancer :

```sh
git clone https://github.com/Nohzoh/FieldTally.git
cd FieldTally/app
flutter pub get
flutter run
```

Les tests, qui doivent passer avant toute proposition :

```sh
flutter analyze
flutter test
```

Le détail — structure du code, conventions de commit, ce que la CI vérifie — est
dans
[CONTRIBUTING.md](https://github.com/Nohzoh/FieldTally/blob/main/CONTRIBUTING.md).
Deux règles à connaître d'avance : **tout est en anglais dans le dépôt** (code,
commentaires, commits, issues) sauf les fichiers de traduction, et les commits
suivent la convention *Conventional Commits*.

## Traduire

L'app existe en français et en anglais. Les textes vivent dans
[`app/lib/l10n/`](https://github.com/Nohzoh/FieldTally/tree/main/app/lib/l10n),
un fichier par langue. Ajouter une langue revient à copier `app_en.arb` et à le
traduire — la communauté Ingress est internationale, et c'est une contribution
qui ne demande aucune connaissance du code.

## Licence

FieldTally est publié sous **GNU AGPL v3**. Toute contribution est reçue sous
cette licence.
