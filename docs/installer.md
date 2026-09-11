---
layout: default
title: Installer FieldTally
lang_alt: /en/install
---
{% include nav-fr.html %}

# Installer FieldTally

FieldTally n'est pas sur le Play Store. Tu installes un fichier `.apk`
directement, ce qu'Android appelle du « sideload ». C'est normal et sans
danger, mais le téléphone va te poser deux questions inhabituelles. Les voici
dans l'ordre, avec ce qu'il faut répondre.

**Il te faut :** un téléphone Android 8.0 ou plus récent. Il n'y a pas encore
de version iOS.

## 1. Télécharger le fichier

Ouvre la [page des versions](https://github.com/Nohzoh/FieldTally/releases/latest)
et appuie sur le fichier qui se termine par **`.apk`**.

Le navigateur peut afficher « Ce type de fichier peut endommager votre
appareil ». C'est un message générique qu'Android affiche pour **tout** fichier
APK, quel qu'il soit. Appuie sur **Télécharger quand même**.

## 2. Autoriser l'installation

Ouvre le fichier téléchargé. Android affiche :

> Pour votre sécurité, votre téléphone n'est pas autorisé à installer des
> applications inconnues provenant de cette source.

Appuie sur **Paramètres**, active **Autoriser depuis cette source**, puis
reviens en arrière. Cette autorisation ne concerne que l'application depuis
laquelle tu as téléchargé le fichier (ton navigateur), et tu peux la retirer
ensuite.

## 3. L'avertissement Play Protect

C'est l'écran qui fait peur, et c'est le plus important à comprendre :

> Play Protect ne reconnaît pas le développeur de cette application.

**Ce message ne signifie pas qu'un problème a été détecté.** Play Protect
affiche cela pour toute application qui n'est pas distribuée par le Play Store,
simplement parce qu'elle ne vient pas de là. Une application malveillante et une
application parfaitement saine déclenchent exactement le même écran.

Appuie sur **Installer quand même** (parfois derrière « Plus de détails »).

Ce que tu peux vérifier par toi-même, et qui vaut mieux qu'une promesse :

- **Le code source est public**, en entier, sous licence AGPL v3.
- **L'APK est construit par GitHub Actions** à partir de ce code, pas sur une
  machine privée. Le journal de construction de chaque version est consultable.
- **Chaque version est signée** avec la même clé. Son empreinte SHA-256 est :

  ```
  9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
  ```

  Elle est affichée dans le journal de construction de chaque version. Si un
  jour un APK prétendument FieldTally porte une autre empreinte, il ne vient
  pas d'ici.

## 4. Premier lancement

Ouvre FieldTally, puis dans Ingress : écran de stats → **Partager** →
**FieldTally**. Ton premier relevé est enregistré, et l'app commence à
construire ton historique.

Tu arrives d'Agent Stats ? Ton export CSV existant est lisible tel quel :
menu → **Relevés** → **Importer depuis Agent Stats**.

## Mettre à jour

Télécharge le nouvel APK depuis la même page et installe-le par-dessus. Tes
données sont conservées. **N'utilise que les APK publiés ici** : une mise à jour
signée avec une autre clé sera refusée par Android, ce qui est précisément le
but de la signature.

## Désinstaller

Comme n'importe quelle application. Tout est supprimé avec elle, puisque rien
n'existe ailleurs — pense à faire un export CSV avant si tu veux garder ton
historique.
