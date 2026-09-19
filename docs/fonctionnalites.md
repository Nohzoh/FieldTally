---
layout: default
title: Fonctionnalités
lang_alt: /en/features
---
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
- **Ce qu'un relevé a enregistré** : taper un relevé dans l'historique ouvre ce
  qu'il porte que le précédent n'avait pas, compteur par compteur, sur
  l'intervalle réel entre les deux. Un compteur qui n'a pas bougé n'y figure
  pas, et un compteur absent de l'un des deux relevés n'y figure pas non plus :
  ne pas avoir été rapporté n'est pas la même chose que ne pas avoir bougé.

Sous la catégorie **Événements**, l'app dit depuis quand elle regarde. L'export
Ingress est cumulatif, donc tout compteur qu'il porte arrive complet — mais la
colonne d'un événement finit par en disparaître. Un événement clos avant ton
premier relevé n'est donc nulle part, et l'app le dit plutôt que de laisser son
silence passer pour une médaille que tu n'aurais pas gagnée.

## Projections et objectifs

La **prochaine médaille** affiche ce qu'il te reste et une date estimée à ton
rythme récent — au choix sur les sept ou les trente derniers jours. Quand ton
rythme est nul ou que l'échéance dépasse plusieurs années, l'app le dit au lieu
d'inventer une date.

L'onyx n'est pas la fin. Passé le dernier palier, l'app compte en multiples de
celui-ci, comme le jeu : combien de fois entières tu l'as dépassé, et ce qu'il
reste jusqu'à la suivante.

**L'année en revue** relit une année de ton historique : ce qui a le plus
bougé, les médailles franchies et quand l'app les a vues, ton mois le plus
chargé. Entièrement sur ton téléphone, sans serveur — et avec ses réserves
dites plutôt que tues : si ton historique ne remonte pas au 1er janvier, elle
le dit, et elle rappelle ta plus longue période sans relevé, parce qu'un récap
bâti sur un historique troué décrit ce que tu as enregistré, pas ce que tu as
fait.

**À portée** classe tes médailles par le temps qu'elles demanderaient, tous
compteurs confondus. Ce n'est pas la même question que celle de la plus proche :
un compteur à 95 % d'onyx peut être à quatre cents jours, et un à 60 % à trois
jours. Une médaille n'y apparaît que si ton rythme récent permet une estimation
honnête — et une échelle de saison dont la date limite tombe avant n'y apparaît
pas du tout.

Les **médailles d'anomalie** — la Global Op et la médaille de saison d'une
campagne — se reconnaissent à leur jante brisée au lieu d'être pleine : elles
cessent d'être gagnables à une date, et l'app le sait. Celle de la Global Op
porte en plus un plot en haut. Leurs seuils arrivent par le registre plutôt que
par une mise à jour de l'app, si bien qu'une campagne qui démarre est prise en
compte sans rien installer.

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
de courbes superposées. Rien de tout cela n'existe sans serveur, et la v1 n'en a
pas — c'est précisément ce qui lui permet de ne rien demander et de ne rien
collecter. La comparaison en présence, elle, existe : deux téléphones dans la
même pièce n'ont besoin de personne.

Pas de version iOS non plus, ni de lecture automatique d'une capture d'écran.
Ces deux-là ne tiennent pas au serveur : la première demande un compte
développeur payant et un passage par l'App Store, la seconde n'aurait d'intérêt
que si le partage de texte du jeu venait à disparaître.

Ce qui manque, et ce qui est envisagé, se suit dans les
[issues](https://github.com/Nohzoh/FieldTally/issues).
