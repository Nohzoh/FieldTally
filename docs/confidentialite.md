---
layout: default
title: Confidentialité
lang_alt: /en/privacy
---
{% include nav-fr.html %}

# Confidentialité

Cette page est courte parce qu'il n'y a pas grand-chose à dire. Elle sera
réécrite le jour où ce ne sera plus vrai.

## Ce que FieldTally ne fait pas

- Pas de compte, pas d'inscription, pas d'identifiant.
- Pas de serveur : il n'existe aucune base de données FieldTally ailleurs que
  sur ton téléphone.
- Pas de statistiques d'usage, pas de traceur publicitaire, pas de rapport de
  plantage automatique.
- Aucune donnée personnelle transmise à qui que ce soit, y compris à l'auteur
  du projet.

## Où vivent tes données

Dans une base de données locale, à l'intérieur de l'espace privé de
l'application sur ton téléphone. Aucune autre application n'y a accès. La
désinstallation efface tout.

Tes données ne sortent que quand tu le demandes explicitement : un export CSV ou
une carte en image que tu partages toi-même, vers la destination que tu choisis.
FieldTally ne sait pas où tu les envoies et n'en garde pas de copie.

## La seule requête réseau

L'app télécharge, au démarrage et au plus une fois par jour, un fichier public
hébergé sur GitHub Pages :

```
https://nohzoh.github.io/FieldTally/registry/counters.json
```

Ce fichier contient les noms, catégories et seuils de médailles des compteurs.
Il permet de nommer correctement un nouveau compteur sans attendre une mise à
jour de l'app.

En détail, pour que ce soit vérifiable plutôt que promis :

- C'est un **GET** sur un fichier statique. Rien n'est envoyé, ni relevé, ni
  identifiant, ni donnée d'usage.
- GitHub, qui héberge le fichier, voit cette requête comme n'importe quel
  serveur web voit une visite — adresse IP et type de client. C'est inévitable
  dès qu'un téléchargement a lieu, et c'est la raison pour laquelle il est
  désactivable.
- **Tu peux la couper** : Réglages → *Mettre à jour en ligne*. L'app fonctionne
  alors entièrement hors-ligne, avec la copie du fichier embarquée dans l'APK.
  Aucune fonctionnalité n'est perdue ; seuls les compteurs ajoutés après la
  version installée resteront sous leur nom d'origine.

## Les notifications

Les rappels et les annonces de médaille sont planifiés **par ton téléphone**,
localement. Il n'y a pas de notification push, donc pas de serveur qui saurait
quand te réveiller. Elles sont désactivées tant que tu ne les actives pas.

## Ingress et Niantic

FieldTally ne se connecte pas à Ingress et ne communique pas avec Niantic. Elle
lit un texte que tu lui transmets depuis la fonction de partage du jeu.

## Si ça change

Ajouter un serveur, des comptes ou un outil de mesure d'audience rendrait cette
page fausse. Le jour où cela arrivera, elle sera réécrite avant, pas après, et
l'historique de ce site permet de vérifier ce qu'elle disait avant.
