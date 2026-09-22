---
layout: default
title: Installer FieldTally
lang_alt: /en/install
---
# Installer FieldTally

FieldTally s'installe depuis le **Play Store**. L'app y est en **test fermé** :
la fiche n'est visible que par les personnes inscrites comme testeurs, et s'y
inscrire prend trois étapes, dans cet ordre.

**Il te faut :** un téléphone Android 8.0 ou plus récent, et le compte Google
que tu utilises dessus. Il n'y a pas encore de version iOS.

## 1. Rejoindre le groupe

Ouvre le [groupe FieldTally](https://groups.google.com/g/fieldtally) avec le
compte Google de ton téléphone. La page te propose de le rejoindre, un clic
suffit, il n'y a personne à attendre.

C'est l'étape que personne ne devine, et Play ne te montrera rien tant qu'elle
n'est pas faite. Le groupe sert aussi à annoncer ce qui change et à recevoir
tes retours.

## 2. S'inscrire comme testeur

Ouvre la [page d'inscription](https://play.google.com/apps/testing/io.nohzoh.fieldtally)
et accepte le test. Les mêmes liens sont republiés dans les messages du groupe
une fois que tu l'as rejoint.

## 3. Installer

La fiche Play s'ouvre depuis cette même page, et l'installation se passe comme
pour n'importe quelle application.

**Si la fiche s'affiche comme indisponible**, c'est presque toujours l'étape 1
qui manque, ou un compte Google différent de celui utilisé sur le téléphone.
Play met parfois quelques minutes à prendre l'inscription en compte.

## Mettre à jour

Rien à faire : Play s'en occupe comme pour tes autres applications. L'app ne va
rien chercher de son côté et ne te réclame aucune manipulation.

## Tu avais installé le fichier APK ?

Les versions distribuées à la main avant l'arrivée sur le Play Store portent le
même certificat de signature que celles que Play installe. L'installation depuis
Play se fait donc par-dessus la tienne, et ton historique est conservé.

Si Play refuse malgré tout de reprendre l'installation existante, il faut
désinstaller d'abord — pense alors à faire un export CSV avant, puisque tout
part avec l'application.

## Premier lancement

Ouvre FieldTally, puis dans Ingress : écran de stats → **Partager** →
**FieldTally**. Ton premier relevé est enregistré, et l'app commence à
construire ton historique.

Tu arrives d'Agent Stats ? Copie le tableau de sa page d'export et colle-le
dans menu → **Relevés** → **Importer depuis Agent Stats**. Le bandeau et la
pagination peuvent venir avec, ils sont ignorés.

## Ce que tu peux vérifier

- **Le code source est public**, en entier, sous licence AGPL v3.
- **L'application est construite par GitHub Actions** à partir de ce code, pas
  sur une machine privée. Le journal de construction de chaque version est
  consultable, et il refuse de continuer si la signature n'est pas la bonne.
- **La clé de signature est celle du projet**, la même depuis la première
  version. Son empreinte SHA-256 est :

  ```
  9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
  ```

## Désinstaller

Comme n'importe quelle application. Tout est supprimé avec elle, puisque rien
n'existe ailleurs — pense à faire un export CSV avant si tu veux garder ton
historique.
