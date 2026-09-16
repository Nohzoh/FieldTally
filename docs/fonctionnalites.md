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
  l'ordre du jeu, avec recherche, tri et filtres. Les compteurs liés à une
  médaille portent son emblème, et le palier atteint est écrit à côté — et la
  liste peut être réduite à ces seuls compteurs, ou triée par la médaille dont
  tu es le plus proche. La progression récente se mesure en rythme par jour
  sur une durée que tu choisis, si bien que des compteurs relevés à des
  rythmes différents deviennent comparables.
- **Détail d'un compteur** : graphique sur la semaine, le mois ou tout
  l'historique, avec un trait à ce que tu vises — ton objectif si tu en as
  fixé un, sinon la prochaine médaille. Plus un calendrier d'activité et le
  nom exact de la colonne d'export pour retrouver le compteur dans le jeu.

## Projections et objectifs

La **prochaine médaille** affiche ce qu'il te reste et une date estimée à ton
rythme récent — au choix sur les sept ou les trente derniers jours. Quand ton
rythme est nul ou que l'échéance dépasse plusieurs années, l'app le dit au lieu
d'inventer une date.

L'onyx n'est pas la fin. Passé le dernier palier, l'app compte en multiples de
celui-ci, comme le jeu : combien de fois entières tu l'as dépassé, et ce qu'il
reste jusqu'à la suivante.

Tu peux fixer un **objectif personnel** sur n'importe quel compteur, avec ou
sans échéance, et voir si ton rythme actuel t'y mène. Sur le graphique,
l'échelle s'étire pour tenir l'objectif même quand ça écrase la courbe contre
le bas : cet écrasement est justement l'information, il te dit d'un coup d'œil
que ce que tu vises est très loin.

## Rappels

Deux notifications, planifiées sur l'appareil et rien d'autre :

- un rappel quand tu n'as rien enregistré depuis un certain temps (délai
  réglable) ;
- une annonce quand un relevé te fait franchir un palier de médaille, dépasser
  le dernier une fois de plus, ou monter d'un niveau.

Désactivées tant que tu ne les as pas activées.

## Partager et exporter

- Une **carte de stats** en image, avec ta progression sur la période de ton
  choix, prête à publier.
- Un **export CSV** de tout l'historique, pour le garder ailleurs ou changer de
  téléphone.
- Une **comparaison avec un agent à côté de toi** : tu lui envoies tes totaux par
  le partage Android, son application met vos chiffres côte à côte, compteur par
  compteur. Sans serveur, et ce qu'il t'envoie n'entre jamais dans ton historique.

## Ce qui n'existe pas encore

Pas de compte, pas de classement entre agents, pas de comparaison à distance ni
de courbes superposées, pas de version iOS aboutie, pas de lecture automatique
d'une capture d'écran. Rien de tout cela n'est possible sans serveur, et la v1
n'en a pas. La comparaison en présence, elle, existe : deux téléphones dans la
même pièce n'ont besoin de personne. Voir la [feuille de route]({{ '/feuille-de-route' | relative_url }}).
