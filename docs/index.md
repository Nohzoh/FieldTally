---
layout: default
title: FieldTally
lang_alt: /en/
---
{% include nav-fr.html %}

# FieldTally

**Suis tes statistiques Ingress sur ton téléphone, sans compte et sans serveur.**
Tout reste sur l'appareil : aucune inscription, aucune donnée envoyée nulle part.

> ⚠️ **Non-officiel.** FieldTally est un outil de fan, sans aucun lien avec
> Niantic, Inc. « Ingress », ainsi que les noms de médailles et de compteurs,
> sont des marques et du contenu de Niantic, Inc. Ce projet n'utilise aucun
> visuel protégé.

<p>
<img src="{{ '/assets/screenshots/dashboard.png' | relative_url }}" alt="Tableau de bord : quatre compteurs épinglés avec leur valeur, leur progression et une courbe" width="240">
<img src="{{ '/assets/screenshots/detail.png' | relative_url }}" alt="Détail d'un compteur : graphique sur toute la période et projection de la prochaine médaille" width="240">
<img src="{{ '/assets/screenshots/share-card.png' | relative_url }}" alt="Carte de stats partageable en image" width="240">
</p>

## Comment ça marche

1. Dans Ingress, ouvre ton écran de stats et appuie sur **Partager**.
2. Choisis **FieldTally** dans la liste. Le texte arrive directement dans l'app.
3. Vérifie l'aperçu et enregistre. C'est tout.

Chaque relevé est daté et conservé. Au fil du temps, l'app te montre ta
progression compteur par compteur, avec une courbe à l'échelle de chaque
compteur plutôt qu'un graphique unique illisible.

## Ce qu'elle t'apporte

- **Un tableau de bord** avec les quelques compteurs que *tu* as choisis.
- **Un graphique par compteur**, sur sa propre échelle.
- **Une projection de médaille** : combien il te reste, et à quelle date à ton
  rythme récent — ou rien du tout quand ton rythme ne permet pas d'estimation
  honnête.
- **Des objectifs personnels** et des **rappels** planifiés sur l'appareil.
- **Une carte de stats** en image, prête à publier.
- **Un export CSV** de tout ton historique, à tout moment.

[Voir toutes les fonctionnalités]({{ '/fonctionnalites' | relative_url }}) ·
[Installer l'app]({{ '/installer' | relative_url }})

## Pourquoi pas simplement Agent Stats ?

FieldTally n'a pas vocation à remplacer Agent Stats, et peut lire son export
pour que tu récupères ton historique existant. La différence tient en trois
points : tout reste sur ton téléphone, chaque compteur a sa propre échelle, et
l'app refuse d'enregistrer un relevé partiel (« cette semaine » au lieu du
cumul) qui fausserait ton historique sans que tu t'en aperçoives.
