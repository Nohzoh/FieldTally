---
layout: default
title: Fonctionnalités
lang_alt: /en/features
---
{% include nav-fr.html %}

# Fonctionnalités

## Ajouter un relevé

Depuis Ingress, **Partager** ton écran de stats et choisir FieldTally : le texte
arrive dans l'app, qui te montre ce qu'elle a compris avant d'enregistrer quoi
que ce soit. Tu peux aussi coller le texte à la main.

L'app lit les colonnes **par leur nom**, pas par leur position. Quand Niantic
ajoute ou déplace un compteur, rien ne casse et rien ne se décale.

**Un compteur inconnu n'est pas perdu.** Il est suivi sous son nom d'origine et
rangé dans « Autres » jusqu'à ce que quelqu'un le déclare — ce qui se fait par
une simple contribution, sans attendre une mise à jour de l'app.

## Deux garde-fous à l'import

Copier « This Week » au lieu du cumul depuis toujours est l'erreur la plus
facile à commettre, et la plus pénible : elle écrase ton historique avec des
chiffres minuscules.

- L'app **refuse** un relevé qui se déclare comme une période partielle.
- Elle **prévient** quand un compteur recule par rapport au relevé précédent,
  en te disant lequel et de combien. À toi de décider.

## Voir sa progression

- **Tableau de bord** : les compteurs que tu épingles, avec leur valeur, leur
  progression depuis le relevé précédent et une courbe de tendance.
- **Tous les compteurs** : la liste complète, groupée par catégorie et dans
  l'ordre du jeu, avec recherche et tri.
- **Détail d'un compteur** : graphique sur la semaine, le mois ou tout
  l'historique, calendrier d'activité, et le nom exact de la colonne d'export
  pour retrouver le compteur dans le jeu.

## Projections et objectifs

La **prochaine médaille** affiche ce qu'il te reste et une date estimée à ton
rythme récent — au choix sur les sept ou les trente derniers jours. Quand ton
rythme est nul ou que l'échéance dépasse plusieurs années, l'app le dit au lieu
d'inventer une date.

Tu peux fixer un **objectif personnel** sur n'importe quel compteur, avec ou
sans échéance, et voir si ton rythme actuel t'y mène.

## Rappels

Deux notifications, planifiées sur l'appareil et rien d'autre :

- un rappel quand tu n'as rien enregistré depuis un certain temps (délai
  réglable) ;
- une annonce quand un relevé te fait franchir un palier de médaille.

Désactivées tant que tu ne les as pas activées.

## Partager et exporter

- Une **carte de stats** en image, avec ta progression sur la période de ton
  choix, prête à publier.
- Un **export CSV** de tout l'historique, pour le garder ailleurs ou changer de
  téléphone.

## Ce qui n'existe pas encore

Pas de compte, pas de classement entre agents, pas de comparaison avec
quelqu'un d'autre, pas de version iOS aboutie, pas de lecture automatique d'une
capture d'écran. Rien de tout cela n'est possible sans serveur, et la v1 n'en a
pas. Voir la [feuille de route]({{ '/feuille-de-route' | relative_url }}).
