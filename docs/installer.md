---
layout: default
title: Installer FieldTally
lang_alt: /en/install
---
# Installer FieldTally

Il y a deux façons d'installer FieldTally : depuis le **Play Store**, en
rejoignant le test fermé, ou en installant le fichier `.apk` **à la main**. La
première est plus simple et gère les mises à jour toute seule ; la seconde ne
demande aucun compte Google.

**Il te faut :** un téléphone Android 8.0 ou plus récent. Il n'y a pas encore
de version iOS.

## Depuis le Play Store

L'app est en **test fermé** : la fiche n'est visible que par les personnes
inscrites comme testeurs. Trois étapes, dans cet ordre.

1. **Rejoins le groupe [FieldTally](https://groups.google.com/g/fieldtally)**
   avec le compte Google de ton téléphone. Le lien te propose de le rejoindre,
   un clic suffit, il n'y a personne à attendre.
2. **Inscris-toi comme testeur** sur
   [cette page](https://play.google.com/apps/testing/io.nohzoh.fieldtally) et
   accepte le test.
3. **Installe depuis la fiche Play**, comme n'importe quelle application.

Si la fiche s'affiche comme indisponible, c'est presque toujours l'étape 1 qui
manque, ou un compte Google différent de celui utilisé sur le téléphone. Les
messages du groupe redonnent ces mêmes liens une fois que tu l'as rejoint.

Les mises à jour arrivent ensuite toutes seules, comme pour tes autres
applications, et aucun des avertissements de la section suivante ne s'affiche.

## À la main, avec le fichier APK

C'est ce qu'Android appelle du « sideload ». C'est normal et sans danger, mais
le téléphone va te poser deux questions inhabituelles. Les voici dans l'ordre,
avec ce qu'il faut répondre.

### 1. Télécharger le fichier

Ouvre la [page des versions](https://github.com/Nohzoh/FieldTally/releases/latest)
et appuie sur le fichier qui se termine par **`.apk`**.

Le navigateur peut afficher « Ce type de fichier peut endommager votre
appareil ». C'est un message générique qu'Android affiche pour **tout** fichier
APK, quel qu'il soit. Appuie sur **Télécharger quand même**.

### 2. Autoriser l'installation

Ouvre le fichier téléchargé. Android affiche :

> Pour votre sécurité, votre téléphone n'est pas autorisé à installer des
> applications inconnues provenant de cette source.

Appuie sur **Paramètres**, active **Autoriser depuis cette source**, puis
reviens en arrière. Cette autorisation ne concerne que l'application depuis
laquelle tu as téléchargé le fichier (ton navigateur), et tu peux la retirer
ensuite.

### 3. L'avertissement Play Protect

C'est l'écran qui fait peur, et le seul où l'on risque d'abandonner :

> **Appli bloquée pour protéger votre appareil**
>
> Play Protect n'a jamais vu d'appli de ce développeur auparavant. Elle n'est
> peut-être pas sûre.

**Ce message ne signifie pas qu'un problème a été détecté.** Ce que Play Protect
ne connaît pas, c'est la **clé de signature** : il regroupe les applications par
clé, et celle de FieldTally est récente, donc jamais vue sur beaucoup
d'appareils. Une application malveillante et une application parfaitement saine
déclenchent exactement le même écran. Le verdict s'atténuera de lui-même à
mesure que l'app sera installée.

**Le seul bouton visible est « OK », et il annule l'installation.** Pour
continuer, appuie d'abord sur **« Plus de détails »** : l'option permettant
d'installer quand même apparaît en dessous. Son libellé exact varie selon la
version d'Android.

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

  C'est la même clé que celle utilisée pour le Play Store : les deux façons
  d'installer donnent bien la même application.

### Mettre à jour

Télécharge le nouvel APK depuis la même page et installe-le par-dessus. Tes
données sont conservées. **N'utilise que les APK publiés ici** : une mise à jour
signée avec une autre clé sera refusée par Android, ce qui est précisément le
but de la signature.

L'app te dit quand une version est sortie : les Réglages la nomment et ouvrent
sa page. Elle l'apprend en lisant un petit fichier public sur le site du projet,
sous le même réglage *Mettre à jour en ligne* que le registre des compteurs, et
n'envoie rien.

**Elle n'installe jamais rien d'elle-même.** Il faudrait pour cela demander à
Android le droit d'installer des applications, et une app dont tout l'argument
est qu'elle ne fait presque rien n'a pas à élargir ce qu'elle peut faire pour
t'épargner deux gestes. Tu télécharges et installes comme la première fois.

Si tu veux une vraie automatisation,
[Obtainium](https://github.com/ImranR98/Obtainium) suit les releases GitHub et
s'occupe de la détection, du téléchargement et de l'installation.

## Premier lancement

Quelle que soit la façon dont tu l'as installée : ouvre FieldTally, puis dans
Ingress : écran de stats → **Partager** → **FieldTally**. Ton premier relevé est
enregistré, et l'app commence à construire ton historique.

Tu arrives d'Agent Stats ? Copie le tableau de sa page d'export et colle-le
dans menu → **Relevés** → **Importer depuis Agent Stats**. Le bandeau et la
pagination peuvent venir avec, ils sont ignorés.

## Désinstaller

Comme n'importe quelle application. Tout est supprimé avec elle, puisque rien
n'existe ailleurs — pense à faire un export CSV avant si tu veux garder ton
historique.
