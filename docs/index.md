---
layout: default
title: Accueil
---

# FieldTally

**FieldTally** est une application mobile de suivi de statistiques
[Ingress](https://ingress.com), pensée pour le mobile et fonctionnant
**100 % en local** : aucun compte, aucun serveur, aucune donnée envoyée.

> ⚠️ **Projet en cours de construction.** Le dépôt ne contient pour l'instant
> que le squelette technique — il n'y a pas encore d'application installable.

## Non-affiliation

FieldTally est un outil **non-officiel, fan-made**, sans aucun lien avec
Niantic, Inc. « Ingress » ainsi que les noms de médailles et de compteurs sont
des marques et contenus de Niantic, Inc. Ce projet ne réutilise aucun asset
protégé.

## Ce qui existe déjà

- La [spécification v1 complète](spec/SPECIFICATION-v1.md) du projet.
- Le [registre des compteurs](registry/counters.json), source de vérité de la
  catégorisation, des libellés et (à terme) des seuils de palier.

## Contribuer

La contribution la plus utile — et la plus simple — est d'ajouter ou de
corriger une entrée dans `docs/registry/counters.json` quand un nouveau
compteur apparaît dans le jeu. Aucune connaissance de Dart n'est nécessaire :
voir [CONTRIBUTING.md](https://github.com/Nohzoh/FieldTally/blob/main/CONTRIBUTING.md).
