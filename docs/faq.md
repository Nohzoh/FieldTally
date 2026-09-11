---
layout: default
title: FAQ
lang_alt: /en/faq
---
{% include nav-fr.html %}

# Questions fréquentes

## Pourquoi l'app n'est-elle pas sur le Play Store ?

Publier sur le Play Store demande un compte développeur payant, une fiche à
maintenir et des délais de validation à chaque mise à jour. Pour une v1 écrite
sur du temps libre, ça n'en valait pas la peine. Ce n'est pas exclu plus tard.

En attendant, [l'installation manuelle]({{ '/installer' | relative_url }}) prend deux minutes, et la
page explique les avertissements d'Android au fur et à mesure.

## Mes données sont-elles envoyées quelque part ?

Non. Pas de compte, pas de serveur, pas de statistiques d'usage, pas de rapport
de plantage. Tes relevés vivent dans une base de données sur ton téléphone et
n'en sortent que si tu le décides — un export CSV ou une carte à partager que
tu envoies toi-même.

Une seule nuance, et elle est dite en entier sur la page
[Confidentialité]({{ '/confidentialite' | relative_url }}) : au démarrage, l'app télécharge un fichier
public listant les noms et catégories des compteurs. C'est une lecture, elle
n'envoie rien sur toi, et elle se désactive dans les réglages.

## L'ajout de mes stats ne marche pas

Trois causes possibles, dans l'ordre de fréquence :

**Le texte n'est pas celui de l'écran de stats.** Il faut le partage depuis
l'écran de stats d'Ingress, pas une capture d'écran ni un autre écran. L'app ne
lit pas les images.

**Tu as partagé une période partielle.** Si tu étais sur l'onglet `WEEK` ou
`MONTH`, l'app refuse le relevé : enregistrer une semaine à la place du cumul
écraserait ton historique. Repasse sur `ALL TIME` et recommence.

**Le format a changé.** C'est le risque principal du projet : Niantic ne
documente pas ce format et peut le modifier sans prévenir. Si le message d'erreur
parle de colonnes manquantes,
[ouvre une issue](https://github.com/Nohzoh/FieldTally/issues/new) avec un
extrait du texte partagé — tu peux remplacer ton nom d'agent par autre chose,
seuls les noms de colonnes comptent.

## Un compteur manque, ou s'affiche en anglais dans une catégorie « Autres »

C'est le comportement prévu, pas un bug. L'app suit **tous** les compteurs
qu'elle trouve, y compris ceux qu'elle ne connaît pas — elle les affiche
simplement sous leur nom d'origine, en attendant que quelqu'un les déclare.

Cette déclaration se fait dans un seul fichier public,
[`counters.json`](https://github.com/Nohzoh/FieldTally/blob/main/docs/registry/counters.json),
et l'app va la chercher au démarrage. Autrement dit : un nouveau compteur
d'anomalie peut être nommé et catégorisé pour tout le monde **sans nouvelle
version de l'app**. C'est la contribution la plus utile que tu puisses faire.

## Les noms de compteurs ne sont pas les mêmes que dans le jeu

Le jeu affiche les noms de compteurs en anglais, même quand son interface est
en français. FieldTally les traduit. Pour retrouver la correspondance, ouvre le
compteur : son écran de détail affiche le **nom de colonne à l'export**, qui est
le nom exact du jeu.

## Je change de téléphone, je perds tout ?

Fais un export CSV avant (menu → **Relevés** → export). Sur le nouveau
téléphone, l'import lit ce fichier. Il n'y a pas de synchronisation automatique :
il n'y a pas de serveur pour la faire.

## Puis-je récupérer mon historique Agent Stats ?

Oui. L'export CSV d'Agent Stats est lu tel quel : menu → **Relevés** →
**Importer depuis Agent Stats**. Tout l'historique arrive d'un coup.

Attention : ce format ne dit pas s'il s'agit d'un cumul ou d'une période, donc
seul le contrôle de cohérence s'applique à cet import. L'app te signale les
reculs qu'elle trouve avant d'enregistrer.

## L'app est-elle officielle ? Est-ce que je risque mon compte ?

Elle n'est pas officielle et n'a aucun lien avec Niantic. Elle ne se connecte
pas à Ingress, ne demande pas tes identifiants et n'automatise rien dans le jeu.
Elle lit un texte que *tu* lui donnes, depuis une fonction de partage fournie
par le jeu lui-même.
