# Spécification v1 — Application mobile de suivi de stats Ingress

**Statut :** brouillon de démarrage — à valider/amender avant le premier commit
**Nom du projet :** `FieldTally` *(tranché — voir §0.2)*
**Dernière mise à jour :** 2026-09-09 (v1.4 — nom du projet tranché : `FieldTally`, `applicationId` Android `io.nohzoh.fieldtally` ; v1.3 avait hébergé la couche d'enrichissement des compteurs sur le repo GitHub, récupérée par l'app au démarrage ; v1.2 avait remplacé le référentiel figé par un registre piloté par les imports ; v1.1 avait ajouté la gestion des compteurs éphémères et le garde-fou anti-import de période partielle)

---

## 0. Décisions déjà actées pour cette v1

Ces points ont été tranchés en amont de cette spec et structurent tout le reste du document ; ils ne sont pas rediscutés plus bas sauf pour leurs implications techniques.

| Sujet | Décision |
|---|---|
| Ingestion des données | Coller le texte de partage exporté par l'appli Ingress **+** intégration au bouton de partage natif Android (l'app apparaît dans la feuille de partage quand on partage depuis Ingress) |
| Backend / réseau | **100 % local et hors-ligne en v1** — pas de compte, pas de serveur, pas de groupes/classement (reporté en v2, voir §6) |
| Distribution | **Android d'abord**, iOS dans une itération suivante |
| Nom du projet | Un nom **distinct** d'« Agent Stats », pour éviter toute confusion avec le site existant |

**Amendement (v1.3) à la ligne « Backend / réseau » :** la v1 reste sans compte, sans serveur applicatif et sans envoi d'aucune donnée utilisateur. Une seule exception, volontairement étroite, y est ajoutée : l'app peut aller lire un fichier JSON public hébergé sur le site GitHub Pages du projet pour tenir à jour la catégorisation des compteurs sans passer par une release (voir §3.1.4). C'est une lecture seule d'un contenu non personnel, désactivable, et l'app reste pleinement fonctionnelle hors-ligne dans tous les cas — le principe « pas de backend applicatif, pas de compte, pas de télémétrie » n'est pas remis en cause.

### 0.1 Non-objectifs explicites de la v1

- Pas de comptes utilisateurs, pas de synchronisation cloud.
- Pas de groupes ni de classements entre agents (ça suppose un backend partagé — voir §6).
- Pas d'iOS fonctionnel (le code doit rester multi-plateforme, mais aucun effort de build/test/distribution iOS n'est attendu en v1 au-delà de ne pas fermer la porte).
- Pas de Grafana ni d'outil externe de dashboarding (mis de côté comme convenu).
- Pas de publication officielle sur Play Store / App Store (distribution via GitHub Releases uniquement).

### 0.2 Nom du projet — tranché : `FieldTally`

Le nom retenu est **`FieldTally`** — « tally » au sens de décompte/pointage cumulé, cohérent avec l'esprit de l'app (des compteurs qui s'accumulent dans le temps), sans le mot « Ingress » et sans reprendre la structure d'« Agent Stats ».

**Vérification effectuée avant validation :** une recherche a remonté un produit existant du même nom, `Fieldtally` (fieldtally.org), un service de comptabilité/gestion financière agricole — un domaine sans rapport, sans présence identifiée sur les stores mobiles ni sur les réseaux sociaux sous ce nom. Le risque de confusion pour les utilisateurs (agents Ingress cherchant une app de stats) est jugé faible comparé aux deux options précédemment écartées (`FieldStats`, qui collisionnait avec une app d'analyse sportive active sur les stores et les réseaux, et `AgentLog`, qui collisionnait à la fois avec « Agent Stats » lui-même et avec plusieurs outils d'observabilité d'agents IA très actifs). Ce n'est pas un conseil juridique — juste une vérification de bon sens avant de committer le nom dans le repo, les assets et l'`applicationId` — mais rien qui justifie de revenir sur le choix.

**Identifiants techniques associés :**
- Nom du repo GitHub / nom de l'app : `FieldTally` (ou `fieldtally` en minuscules selon le contexte).
- `applicationId` Android : **`io.nohzoh.fieldtally`**.

**Points encore ouverts à trancher par toi**, listés aussi en §16 :
1. Licence open source du repo (MIT proposé par défaut, voir §10).
2. Faut-il un logo/icône dès le départ, ou un placeholder le temps d'en produire un ?
3. Le site GitHub Pages doit-il être en français, en anglais, ou bilingue ?

---

## 1. Vision & positionnement

Ingress Prime permet de suivre ses statistiques (AP, médailles, niveaux) mais de façon limitée et peu lisible dans le temps. Des outils communautaires comme **agent-stats.com** comblent ce manque depuis des années avec un historique riche (diff/semaine/mois, projections de paliers, groupes), mais leur interface web n'est pas pensée mobile-first et souffre de problèmes d'ergonomie identifiés dans l'audit qui précède cette spec (graphique multi-séries illisible, tableau non filtrable, mobile mal supporté).

L'objectif de ce projet est de reprendre les fondamentaux qui font la valeur d'Agent Stats — historique détaillé, diffs, projections de paliers — dans une **application mobile Flutter native, mobile-first**, avec une UX largement repensée (tableau de bord personnalisable, graphiques lisibles, heatmap d'activité) et un **fonctionnement 100 % local** en v1 : toutes les données de l'agent restent sur son téléphone, sans compte ni serveur.

### 1.1 Non-affiliation

Le projet est un outil **non-officiel, fan-made**, sans lien avec Niantic. Le nom, les assets et la documentation devront systématiquement inclure une mention claire de non-affiliation (« Ingress » et les noms de médailles sont des marques/contenus de Niantic, Inc.), et éviter tout usage du logo Ingress ou d'assets protégés. Ce point doit figurer dans le README, l'à-propos in-app, et le site GitHub Pages.

---

## 2. Utilisateurs cibles

- **Agent Ingress actif et régulier** qui veut suivre sa progression sans dépendre d'un site web, avec une consultation rapide « sur le terrain » (d'où le mobile-first).
- **Agent qui utilise déjà Agent Stats** et veut migrer son historique existant vers l'app (voir import CSV, §5.1 et Annexe B).
- Public non-développeur pour la partie site GitHub Pages : un agent qui trouve l'app via Reddit/un groupe Ingress et veut juste savoir « c'est quoi, c'est fiable, comment je l'installe ».

---

## 3. Périmètre fonctionnel v1

### 3.1 Ingestion des données

Deux mécanismes complémentaires, tous deux 100 % locaux (aucun envoi réseau) :

- **Coller le texte de partage Ingress.** Ingress Prime permet à l'agent d'exporter/partager un bloc de texte contenant l'ensemble de ses stats (AP, lifetime AP, et chaque médaille avec sa valeur). L'app doit fournir un écran « Ajouter un relevé » avec un champ de collage (paste), qui parse ce texte et affiche un aperçu des valeurs détectées **avant** de les enregistrer, pour que l'utilisateur puisse repérer une anomalie de parsing.
- **Intégration à la feuille de partage Android (Share Sheet).** L'app doit s'enregistrer comme destinataire de partage de texte, pour qu'un agent puisse, directement depuis l'appli Ingress, taper sur « Partager » → choisir FieldTally → arriver directement sur l'écran d'aperçu/confirmation du relevé, sans copier-coller manuel.
  - Techniquement, un plugin Flutter gérant les *share intents* entrants (ex. type `receive_sharing_intent`) couvre en général Android **et** iOS (via une App Extension), donc même si iOS n'est pas la cible v1, le choix du plugin doit rester compatible pour ne pas refaire ce travail en v2.
- **Import CSV de migration** (compatible avec le format d'export existant d'Agent Stats — colonnes `Date Heure ap lifetime_ap explorer …`, voir Annexe B), pour les agents qui ont déjà un historique accumulé ailleurs et veulent repartir avec leurs données plutôt que de zéro.

**Point de vigilance important (voir aussi §7) :** le format du texte exporté par Ingress Prime n'est pas documenté officiellement par Niantic et peut changer sans préavis à une mise à jour de l'app, ou varier selon la langue de l'app du joueur. Le parser doit être isolé dans un module dédié, largement testé (tests unitaires sur plusieurs échantillons réels), versionné, et échouer *proprement* (message clair + possibilité de corriger les champs à la main) plutôt que planter ou enregistrer des données fausses silencieusement.

#### 3.1.1 Format source réel et analyse pilotée par les en-têtes

En observant un vrai export Ingress Prime, le format est en réalité un **texte tabulé (TSV) avec une ligne d'en-têtes explicite** : `Time Span`, `Agent Name`, `Agent Faction`, `Date (yyyy-mm-dd)`, `Time (hh:mm:ss)`, `Level`, `Lifetime AP`, `Current AP`, … jusqu'à des colonnes ponctuelles comme `Orion Tokens` ou `Apollo Mod Battle Points`. C'est une bonne nouvelle : contrairement à un format positionnel figé, un format auto-descriptif par en-têtes permet un parsing bien plus robuste face aux évolutions du jeu.

Conséquence directe sur l'implémentation : **le parser doit mapper chaque colonne par son nom d'en-tête, jamais par sa position.** Un mapping positionnel casserait dès que Niantic ajoute, retire ou réordonne une colonne. Le parsing distingue dès le départ deux familles de colonnes :
- les **colonnes de métadonnées du relevé** : `Time Span`, `Agent Name`, `Agent Faction`, `Date`, `Time`, `Level` ;
- les **colonnes de compteurs**, c'est-à-dire tout le reste.

#### 3.1.2 Registre des compteurs piloté par les données, avec enrichissement optionnel

**Principe révisé (v1.2) :** plutôt que de figer à l'avance une liste « officielle » de compteurs supportés, on part de l'inverse. **Le registre des compteurs de l'app est entièrement dérivé de ce que les exports contiennent réellement**, pas d'une liste codée en dur. Un nouveau compteur qui apparaît dans un export — qu'il s'agisse d'un compteur lié à une anomalie temporaire ou d'un ajout permanent au jeu — devient immédiatement un compteur suivi à part entière (historique, graphique), sans attendre une mise à jour de l'app. C'est un point important : au moment où un compteur apparaît pour la première fois, rien ne permet de savoir a priori s'il sera éphémère (façon Orion/Apollo) ou permanent — ça ne s'observe qu'après coup, par sa présence ou son absence dans la durée (voir plus bas). Une liste figée pénaliserait à tort un nouveau compteur permanent en le traitant comme un cas dégradé simplement parce qu'il est récent.

Ce registre piloté par les données est enrichi, quand l'information est disponible, par une **couche d'enrichissement optionnelle** : un fichier JSON versionné et distinct du registre lui-même, qui associe à une clé de compteur (le nom de colonne tel qu'exporté) un libellé traduit, une catégorie et un ordre d'affichage, et des seuils de palier quand ils sont connus (pour les projections du §3.6). L'Annexe A constitue le contenu initial (« seed ») de cette couche d'enrichissement — construit directement à partir de la catégorisation réelle de l'écran de stats d'Ingress Prime (voir capture d'écran fournie), pas d'une liste inventée.

Un compteur **sans** entrée dans la couche d'enrichissement reste pleinement fonctionnel : il est juste affiché avec son libellé brut (celui de l'en-tête d'export), rangé dans une catégorie générique « Autres » en fin de liste, et sans projection de palier tant que ses seuils ne sont pas connus. Ajouter le support propre d'un nouveau compteur devient alors une simple entrée à ajouter dans ce fichier JSON (via une PR, y compris par quelqu'un de non technique), sans toucher au code de parsing ni au modèle de données.

**Statut actif/inactif, basé uniquement sur la présence dans les imports (pas sur une notion a priori d'« éphémère ») :**
- Un compteur est **actif** tant qu'il apparaît dans les imports récents.
- Il passe automatiquement en **inactif** après **45 jours d'absence** dans les imports (paramètre ajustable) : sa dernière valeur connue reste affichée, figée, et il sort du calcul des diffs actifs — jamais interprété comme retombé à 0.
- Cette règle unique s'applique de la même façon à un compteur d'anomalie qui se termine, à un compteur du jeu de base retiré par Niantic (ex. `prime_challenge`, `stealth_ops`, `urban_ops`, `ocf`, `intel_ops`, `operation_chronos`, `cryptic_memories_op`, absents de l'export réel analysé), et à tout compteur enrichi ou non — un seul mécanisme, sans distinction a priori entre catégories de compteurs.
- Un compteur qui redevient actif après une période d'inactivité (ex. une anomalie qui revient sous le même nom une saison plus tard) reprend simplement son historique là où il l'avait laissé.
- Aucune projection de palier n'est calculée sur un compteur sans seuils connus (typiquement les compteurs sans entrée d'enrichissement) : seul l'historique brut est affiché, avec la possibilité d'y associer un objectif personnel libre (réutilise le §3.7).

**Catégorisation et ordre d'affichage — repris tels quels de l'écran de stats d'Ingress Prime.** Les captures d'écran fournies confirment que le jeu catégorise déjà tous ces compteurs (Discovery, Building, Resource Gathering, Streaks, Combat, Defense, Health, Missions, Bounties, Events, Recursion), dans un ordre stable, y compris pour les onglets `ALL TIME` / `MONTH` / `WEEK` / `NOW` évoqués au §3.1.3. Fait notable : les compteurs liés à l'anomalie en cours (`Orion Tokens`, `Apollo Tokens`, etc.) sont rangés par le jeu lui-même **dans la catégorie « Events »**, aux côtés de compteurs récurrents comme `Mission Day(s) Attended` — pas dans une catégorie à part. La v1 de l'app reprend donc **la même catégorisation et le même ordre** plutôt que d'en inventer un, y compris pour les compteurs liés aux anomalies : ils restent affichés au même endroit que dans le jeu, avec juste une puce discrète « inactif depuis le JJ/MM » une fois passés en statut inactif, plutôt que d'être déplacés vers un écran séparé comme l'envisageait une version précédente de cette spec. Le détail complet (clé technique → catégorie → libellé → ordre) est repris en Annexe A.

#### 3.1.3 Garde-fou contre un import de la mauvaise période (ex. « This Week » au lieu de « All Time »)

Défaut identifié sur Agent Stats : rien n'empêche aujourd'hui d'importer un relevé qui correspond à une période partielle (une semaine, un mois) plutôt qu'un total depuis toujours, ce qui fausserait silencieusement tout l'historique, les diffs et les projections. L'export Ingress Prime contient justement un champ `Time Span` qui indique la période couverte (`ALL TIME` dans l'exemple observé, mais l'agent peut aussi choisir d'exporter `THIS WEEK` ou `THIS MONTH` depuis le jeu). Deux garde-fous complémentaires, appliqués à **toutes** les sources d'import (paste, partage, CSV) :

1. **Garde-fou déclaratif, en liste blanche plutôt qu'en liste noire.** Les valeurs `Time Span` confirmées à ce jour sont `ALL TIME`, `WEEK`, `MONTH` et `NOW` (4 granularités proposées par Ingress Prime à l'export). Plutôt que de blacklister les valeurs connues comme fausses, le parser **whitelist uniquement `ALL TIME`** (comparaison insensible à la casse) : toute autre valeur — connue (`WEEK`, `MONTH`, `NOW`) ou future/inconnue — est traitée comme une période partielle et bloque l'import par défaut, avec un message explicite du type : *« Ce relevé correspond à la période “WEEK” et non à un total depuis toujours — l'ajouter fausserait ton historique. Vérifie que tu as bien sélectionné “All Time” dans Ingress avant d'exporter. »* Pas de bouton « forcer quand même » accessible d'un simple clic à côté de ce message : si l'utilisateur veut vraiment passer outre (cas rare), ça doit être une action explicite et bien distincte, pas un réflexe.
2. **Garde-fou comportemental (le vrai filet de sécurité, y compris pour le CSV de migration qui n'a pas de colonne `Time Span` — voir Annexe B).** Quasiment tous les compteurs Ingress sont **cumulatifs et ne peuvent que croître ou rester stables** sur la vie d'un compte (AP, XM collecté, hacks, records « max »…). Le référentiel marque donc chaque compteur stable comme « monotone croissant ». À chaque nouvel import, l'app compare chaque valeur au dernier relevé enregistré pour cet agent : si un compteur monotone **diminue** au-delà d'une tolérance minime, ce n'est presque certainement pas une vraie régression du joueur mais un import de la mauvaise période (ou une erreur de copier-coller/de champ). L'app affiche alors un écran d'anomalie listant précisément quels compteurs ont diminué et de combien, et demande une confirmation explicite avant d'enregistrer quoi que ce soit.

Les deux garde-fous se complètent : le champ `Time Span` peut être absent selon la source, et à l'inverse un `Time Span` correct n'empêche pas une autre source d'erreur (faute de frappe, édition manuelle) — la cohérence des valeurs entre elles reste le filet de sécurité final.

**Découverte importante en comparant un export `ALL TIME` et un export `WEEK` du même agent au même moment :** `Level`, `Lifetime AP` et `Current AP` restent **strictement identiques** entre les deux exports, alors que tous les autres compteurs sont bien réduits à la période sélectionnée. Autrement dit, ces trois champs ne sont *jamais* périodisés par Ingress — ils ne peuvent donc pas servir, à eux seuls, de signal pour le garde-fou comportemental. Celui-ci doit obligatoirement porter sur l'ensemble des compteurs périodisés (tous les autres) et pas uniquement sur l'AP, sans quoi un import `WEEK`/`MONTH`/`NOW` par erreur ne serait pas détecté.

**Recommandation concrète :** les fixtures de test du parser (`test/fixtures/`) incluent déjà un export `ALL TIME` et un export `WEEK` réels (anonymisés — voir note ci-dessous), ce qui permet de tester dès maintenant le garde-fou n°1 (rejet direct via `Time Span`) et de vérifier concrètement, via le garde-fou n°2, qu'un import `WEEK` après un `ALL TIME` déclenche bien l'alerte sur les compteurs périodisés (ex. `Unique Portals Visited` très inférieur) tout en laissant passer l'AP sans signal. Il reste à collecter, quand l'occasion se présente, un export `MONTH` et un export `NOW` réels pour compléter la couverture de test sur ces deux granularités (leur existence est confirmée mais leur format précis n'a pas encore été observé).

**Anonymisation des fixtures :** comme convenu, les échantillons versionnés dans le repo ne doivent jamais contenir un pseudo Ingress réel ni des valeurs directement traçables jusqu'à un compte identifiable. Les deux fixtures fournies avec cette spec ont été produites à partir de tes exports réels avec : nom d'agent remplacé par un pseudo générique, date neutralisée, et toutes les valeurs numériques (hors `Level`, fixé arbitrairement) multipliées par un même facteur d'échelle fixe — ce qui casse le lien avec les valeurs réelles tout en conservant les proportions et les zéros, donc toute la valeur pédagogique du fixture pour les tests. Le même principe (pseudo générique + facteur d'échelle) doit être appliqué à tout futur échantillon réel avant de le committer.

#### 3.1.4 Distribution de la couche d'enrichissement via le repo GitHub (v1.3)

**Problème identifié :** même avec le registre piloté par les données (§3.1.2), la couche d'enrichissement (catégorie, libellé, ordre, seuils de palier) reste, par défaut, embarquée *dans l'app* — donc figée entre deux mises à jour du store/APK. Or ce sont justement les informations qui n'apparaissent jamais dans l'export lui-même (l'export donne juste un nom de colonne brut) et qui demandent le plus souvent une petite mise à jour manuelle à chaque nouveauté du jeu.

**Solution retenue : héberger le fichier d'enrichissement dans le repo GitHub du projet, et le faire récupérer par l'app plutôt que de le figer au moment du build.** Concrètement :

- Le fichier `docs/registry/counters.json` (contenu = celui de l'Annexe A, structuré en JSON) devient la **source de vérité unique**, versionnée dans le repo comme n'importe quel autre fichier. Ajouter/corriger la catégorisation d'un compteur redevient une simple PR sur ce fichier, sans toucher au code Dart ni faire de release.
- Il est servi comme fichier statique par le **site GitHub Pages** déjà prévu (§7.3), à une URL stable du type `https://<utilisateur>.github.io/<repo>/registry/counters.json`. GitHub Pages est préféré à `raw.githubusercontent.com` : il est servi via un vrai CDN avec du cache HTTP standard (ETag, `Cache-Control`), alors que `raw.githubusercontent.com` n'est pas prévu pour être interrogé en masse par un grand nombre de clients et applique un rate-limiting plus agressif.
- **À chaque démarrage de l'app**, un fetch HTTP simple (GET, pas d'authentification) est lancé en arrière-plan pour récupérer ce fichier, avec un intervalle minimal entre deux tentatives (ex. une fois par 24h, mémorisé localement) pour rester léger. Le fichier inclut un champ `updated_at` (ou un numéro de version) permettant à l'app de savoir s'il y a du nouveau avant de remplacer sa copie locale.
- **Le fetch est strictement une amélioration progressive, jamais un prérequis.** L'app embarque, au moment du build, un instantané du même fichier comme copie de secours (`assets/counters_registry_seed.json` — idéalement généré automatiquement à partir de `docs/registry/counters.json` par un script de build, pour n'avoir qu'un seul fichier à maintenir à la main). Si le fetch échoue (pas de réseau, GitHub inaccessible, JSON invalide), l'app continue silencieusement avec la dernière version qu'elle connaît (le cache local le plus récent, ou à défaut la copie embarquée) — sans message d'erreur intrusif, cette mise à jour ne doit jamais être visible de l'utilisateur quand elle échoue.
- **Le même mécanisme couvre aussi les seuils de palier** (§3.6) : plus besoin d'un fichier séparé « statique côté app » pour ça — c'est le même `counters.json`, avec le même mode de mise à jour, qui répond au risque déjà identifié en §6 sur la maintenance des seuils.
- **Transparence et contrôle utilisateur.** Comme c'est la seule requête réseau de toute la v1, elle doit être documentée explicitement dans la page Confidentialité du site (§10) même si elle ne transmet aucune donnée personnelle (lecture seule d'un fichier public, aucune identification de l'agent ou de l'appareil), et un réglage dans les préférences (« Mettre à jour la catégorisation des compteurs en ligne », activé par défaut) permet à qui le souhaite de repasser l'app en 100 % hors-ligne strict.
- **Validation en CI.** Toute PR modifiant `docs/registry/counters.json` doit être validée automatiquement (schéma JSON : clés bien formées, catégories dans une liste autorisée, pas de doublon, seuils de palier croissants) avant d'être mergée et publiée par la pipeline Pages existante (§7.3) — une erreur de syntaxe dans ce fichier ne doit jamais pouvoir casser l'app de tous les utilisateurs d'un coup.
- **Portée volontairement limitée.** Ce mécanisme de fetch au démarrage est réservé à ce seul fichier d'enrichissement — ce n'est pas un canal de configuration à distance généraliste. Le garder strictement scopé à « catégories + libellés + seuils de palier » évite qu'il ne devienne, avec le temps, une porte dérobée vers un vrai backend non assumé comme tel.

### 3.2 Modèle de données & historique

Chaque import (paste, partage, ou ligne CSV) crée un **relevé daté** (snapshot) contenant la valeur brute de chaque compteur à cet instant — pour tout compteur présent dans l'export, connu ou non (voir §3.1.2 pour le registre piloté par les données, et Annexe A pour le contenu d'enrichissement initial). Toutes les vues (diffs, graphiques, projections) sont calculées à partir de cette table de relevés, jamais stockées en dur, pour rester cohérentes si un relevé est corrigé ou supprimé a posteriori.

Chaque compteur découvert dans les imports porte, en plus de son historique de valeurs, un petit jeu de métadonnées qui alimente directement §3.1.2 et §3.1.3 : `is_monotonic` (déduit par défaut à `true`, sert au garde-fou comportemental), `status` (`actif` / `inactif`, déterminé uniquement par la présence dans les imports récents), `first_seen`, `last_seen`, et une référence optionnelle vers son entrée d'enrichissement (`null` si le compteur n'est pas encore connu du fichier d'enrichissement — voir §3.1.2).

L'utilisateur doit pouvoir : consulter la liste de ses relevés, corriger un champ saisi par erreur, et supprimer un relevé (ex. doublon).

### 3.3 Tableau de bord personnalisable

Écran d'accueil = quelques cartes **épinglées** par l'utilisateur (4 à 8, configurable), chacune avec la valeur actuelle, le diff depuis le dernier relevé, et une mini-sparkline. Objectif : corriger le problème n°1 identifié sur Agent Stats (graphique fourre-tout illisible). Un bouton « Personnaliser » permet de choisir quelles médailles épingler, avec une recherche/filtre plutôt qu'une liste à plat de 60 entrées.

### 3.4 Vue détaillée des statistiques

Liste complète de tous les compteurs suivis, **regroupée par catégorie et dans le même ordre que l'écran de stats d'Ingress Prime** (Discovery, Building, Resource Gathering, Streaks, Combat, Defense, Health, Missions, Bounties, Events, Recursion — voir §3.1.2 et Annexe A), avec en plus une catégorie « Autres » en fin de liste pour les compteurs pas encore enrichis. Filtrable et triable (par nom, par catégorie, par progression récente), avec recherche texte — l'agencement par catégorie du jeu reste le tri par défaut plutôt qu'une liste à plat, pour que l'app reste immédiatement familière à quelqu'un qui connaît déjà l'écran de stats in-game. Chaque ligne ouvre une vue détail dédiée (voir 3.5).

### 3.5 Graphiques par compteur

Contrairement au graphique unique multi-séries d'Agent Stats, chaque compteur a son propre graphique avec sa propre échelle, zoomable, avec sélection de période (semaine / mois / tout l'historique). Une **heatmap calendaire** (façon GitHub) est disponible en vue globale pour visualiser les jours d'activité d'un coup d'œil.

### 3.6 Projections de paliers

Reprise du calcul déjà présent sur Agent Stats : à partir du rythme de progression récent (semaine/mois glissant, au choix de l'utilisateur), estimer une date prévisionnelle d'atteinte du prochain palier de médaille ou de niveau, avec le nombre de points manquants. Les seuils de palier par médaille (bronze/argent/or/platine/onyx et niveaux d'agent) proviennent de la même couche d'enrichissement que la catégorisation (§3.1.4) — pas d'un fichier séparé : ils sont maintenus dans `docs/registry/counters.json`, récupérés au démarrage de l'app quand le réseau est disponible, avec une copie de secours embarquée au build pour un fonctionnement garanti hors-ligne.

### 3.7 Objectifs personnels & notifications locales

L'utilisateur peut fixer un objectif libre sur un compteur (ex. « atteindre le niveau 12 avant le 31 décembre »). Comme il n'y a pas de backend en v1, les rappels/alertes utilisent des **notifications locales planifiées sur l'appareil** (pas de push serveur) : rappel périodique si aucun relevé n'a été ajouté depuis X jours, notification quand un palier de médaille est franchi suite à un nouvel import.

### 3.8 Export & partage

- Export CSV complet de l'historique (portabilité des données, et prépare une future migration vers un backend en v2).
- Génération d'une **carte de stats partageable** (image PNG façon récapitulatif) pour publier sur Reddit/réseaux — reprend l'idée de « recap annuel » identifiée dans l'audit, mais disponible à la demande dès la v1 plutôt que uniquement en fin d'année.

### 3.9 Personnalisation visuelle & accessibilité

- Thème clair / sombre suivant le système, avec bascule manuelle possible.
- Option de coloration selon la faction (vert Enlightened / bleu Resistance) — clin d'œil simple et peu coûteux à développer.
- Respect des tailles de texte système, contrastes suffisants, labels d'accessibilité sur les graphiques (les graphiques ne doivent pas être le seul vecteur d'information — toujours doubler d'une valeur textuelle).

### 3.10 Localisation

Français et anglais au minimum dès la v1 (communauté Ingress très internationale, mais toi et les groupes que tu suis — Bougnat ENL, AURA ENL, Verdun — sont francophones). Architecture i18n dès le départ (fichiers `.arb`) même si d'autres langues sont ajoutées plus tard par la communauté.

---

## 4. Hors périmètre v1 → roadmap v2+

Pour mémoire (détaillé en §13), sont **volontairement exclus de la v1** : comptes & backend, groupes/classements entre agents, comparaison tête-à-tête, recap annuel automatique généré serveur, notifications push, build/distribution iOS aboutie, vue « Explorer mes données » façon Grafana pour power users, ingestion par OCR de capture d'écran, publication sur les stores officiels.

---

## 5. Architecture technique

### 5.1 Stack proposée

**Identifiants du projet :** nom d'app `FieldTally`, `applicationId` Android `io.nohzoh.fieldtally` (voir §0.2).

| Domaine | Choix proposé | Justification |
|---|---|---|
| Framework | Flutter (canal stable), Dart | Cible explicite du projet, un seul code pour Android/iOS |
| Gestion d'état | Riverpod | Testable facilement, bon support code-gen, standard actuel dans l'écosystème Flutter |
| Navigation | go_router | Package officiellement recommandé par l'équipe Flutter |
| Stockage local | Drift (SQLite typé) | Les données sont relationnelles et temporelles (relevés datés, agrégations par semaine/mois) — un vrai SQL est plus adapté ici qu'un store clé-valeur type Hive/Isar |
| Graphiques | fl_chart (+ un package dédié type `flutter_heatmap_calendar` pour la heatmap) | Open source, mature, bon contrôle sur les échelles indépendantes par compteur |
| Partage entrant/sortant | `receive_sharing_intent` (entrant) + `share_plus` (sortant) | Couvre Android dès la v1 sans fermer la porte à iOS en v2 |
| Notifications locales | `flutter_local_notifications` | Pas de dépendance serveur nécessaire pour les rappels v1 |
| Internationalisation | `flutter_localizations` + fichiers `.arb` | Outillage standard Flutter |
| Client HTTP (léger) | package `http` | Seul usage réseau de la v1 : le fetch en arrière-plan, au démarrage, du fichier d'enrichissement des compteurs hébergé sur GitHub Pages (§3.1.4) — un simple GET, pas besoin d'un client plus lourd |

### 5.2 Organisation du code (architecture en couches)

```
lib/
  data/           # parsing (texte Ingress, CSV), accès DB (Drift), repositories
  domain/         # modèles métier, calculs (diffs, projections de paliers)
  presentation/   # écrans, widgets, providers Riverpod
  core/           # constantes, thème, i18n, référentiel des médailles (JSON)
```

Le principe directeur : **isoler la logique métier (parsing, calculs de projection) de l'UI**, avec une couche `repository` qui fait écran entre le stockage local actuel et un éventuel backend en v2 — l'objectif est qu'introduire une synchronisation cloud plus tard ne demande pas de réécrire les écrans, seulement l'implémentation des repositories.

### 5.3 Stratégie de tests

- **Priorité absolue : tests unitaires du parser** (texte de partage Ingress → modèle de données) sur un jeu d'échantillons réels variés (langues différentes, valeurs à zéro, médailles manquantes) — c'est le point le plus fragile du projet (voir §6).
- Tests unitaires des calculs de projection de palier (dates, arrondis, cas limites — vitesse nulle ou négative).
- Tests widget sur les écrans clés (tableau de bord, écran d'ajout de relevé, aperçu de parsing).
- Un seuil de couverture minimal (à définir, ex. 70 % sur `data/` et `domain/`) vérifié en CI plutôt qu'un chiffre global arbitraire sur tout le repo.

---

## 6. Risques & points de vigilance

- **Fragilité du format de partage Ingress Prime** : c'est un format non documenté par Niantic, susceptible de changer sans préavis. C'est le risque structurel n°1 du projet — mitigé par un parsing piloté par les noms d'en-têtes plutôt que par position (§3.1.1), un registre entièrement dérivé des imports (§3.1.2), un parser isolé et testé, avec repli gracieux et retours manuels possibles.
- **Compteurs qui apparaissent ou disparaissent au fil des mises à jour du jeu** (anomalies temporaires type Orion/Apollo, mais aussi de futurs compteurs permanents inédits, et des compteurs historiques retirés comme `prime_challenge`/`stealth_ops`/…) : mitigé en refusant tout référentiel figé qui déterminerait à l'avance ce qui est supporté — le registre est entièrement piloté par les imports (§3.1.2), avec une couche d'enrichissement optionnelle et un statut actif/inactif basé sur la seule présence dans les imports récents, sans perte de données ni faux zéro.
- **Import d'une période partielle au lieu du cumul depuis toujours** (ex. copier « This Week » par erreur) : défaut identifié sur Agent Stats, qui n'a aucun garde-fou dessus. Mitigé par la double vérification déclarative + comportementale du §3.1.3.
- **Formats numériques locaux** : selon la langue/région du téléphone de l'utilisateur, les séparateurs de milliers peuvent varier — le parser doit être robuste à ça plutôt que supposer un format unique.
- **Maintenance de la catégorisation et des seuils de palier** : mitigé depuis la v1.3 en sortant cette donnée de l'app elle-même — elle vit dans `docs/registry/counters.json` sur le repo, récupérée au démarrage (§3.1.4), donc modifiable par une simple PR sans attendre une release. Reste un point de vigilance associé : une PR malformée sur ce fichier ne doit jamais pouvoir casser l'app de tous les utilisateurs — d'où la validation obligatoire en CI avant publication (§7.4).
- **Cette même mise à jour à distance introduit une dépendance réseau optionnelle** dans une app par ailleurs 100 % locale : mitigé en la traitant strictement comme une amélioration progressive (jamais bloquante, repli silencieux sur la copie embarquée ou le dernier cache valide), documentée en toute transparence sur la page Confidentialité (§10), et désactivable dans les préférences pour qui veut un hors-ligne strict.
- **Avertissement Android au sideload** : un APK installé hors Play Store déclenche un avertissement Play Protect. Ce n'est pas un bug, mais ça doit être anticipé et expliqué clairement sur le site GitHub Pages (§10) pour ne pas faire peur à un public non-développeur.
- **Dérive entre les deux copies de données** en cas d'ajout futur d'un backend (v2) : anticipé dès maintenant via le pattern repository (§5.2), mais à garder en tête au moment de concevoir le schéma local pour éviter une migration douloureuse plus tard (ex. utiliser des identifiants stables/UUID sur les relevés dès la v1).

---

## 7. CI/CD — GitHub Actions

### 7.1 Pipeline de build & tests (`ci.yml`)

Déclenché sur chaque push et pull request vers `main` :
1. Setup Flutter (action `subosito/flutter-action`, canal stable, avec cache des packages pub).
2. `flutter analyze` (lint) — bloque la CI en cas d'erreur.
3. `flutter test --coverage` — bloque la CI en cas de test cassé ; publie le rapport de couverture comme artifact.
4. `flutter build apk --debug` (ou release non signé) comme build de validation, uploadé en artifact GitHub Actions téléchargeable depuis chaque run — utile pour tester une PR sans attendre une release.

### 7.2 Pipeline de release (`release.yml`)

Déclenché manuellement ou sur un tag `v*` :
1. Build `flutter build apk --release`, signé avec un keystore stocké en secrets GitHub (`ANDROID_KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`).
2. Création d'une **GitHub Release** avec l'APK attaché et un changelog généré à partir des commits/PR depuis la release précédente.

*(Le compte/keystore de signature Android est à créer par toi ; je peux détailler la procédure de génération du keystore et l'ajout des secrets le moment venu.)*

### 7.3 Pipeline GitHub Pages (`pages.yml`)

Déclenché sur push vers `main` touchant le dossier `docs/` :
1. **Validation du fichier `docs/registry/counters.json`** (voir §3.1.4) avant tout déploiement : schéma JSON valide, clés de compteur bien formées, catégories dans une liste autorisée, pas de doublon, seuils de palier croissants. Le job échoue et bloque le déploiement si ce fichier est malformé — c'est le seul rempart contre une PR qui casserait la catégorisation pour tous les utilisateurs d'un coup.
2. Build du site (proposition : **Jekyll**, nativement supporté par GitHub Pages, permet d'écrire tout le contenu en Markdown simple — donc facilement modifiable même par quelqu'un de non-dev — avec un thème de documentation prêt à l'emploi type *just-the-docs*). Le fichier `registry/counters.json` est servi tel quel en asset statique à côté du site généré.
3. Déploiement via les actions officielles `actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`.

### 7.4 Autres automatisations recommandées

- **Dependabot** (`(.github/dependabot.yml)`) pour les mises à jour des dépendances Flutter/pub et des Actions elles-mêmes.
- Un template d'issue GitHub distinct pour « le parsing ne fonctionne pas » (avec demande explicite d'un extrait anonymisé du texte exporté) vu que c'est le point de friction le plus probable remonté par les utilisateurs.
- Un template d'issue/PR spécifique pour « ajouter/corriger un compteur » qui pointe directement vers `docs/registry/counters.json`, pour que la contribution la plus attendue de la communauté (déclarer un nouveau compteur d'anomalie) reste la plus simple à faire.
- Un script (`app/tool/sync_registry_seed.dart` ou équivalent) qui régénère `app/assets/counters_registry_seed.json` à partir de `docs/registry/counters.json`, lancé automatiquement avant chaque build (`ci.yml` et `release.yml`) pour garantir qu'il n'existe qu'un seul fichier maintenu à la main (§3.1.4).

---

## 8. Structure du repo (monorepo)

```
/
├── app/                    # projet Flutter
│   └── assets/
│       └── counters_registry_seed.json   # copie de secours embarquée, générée depuis docs/registry/counters.json (§3.1.4)
├── docs/                   # site GitHub Pages (Jekyll, contenu Markdown)
│   ├── spec/               # ce document et ses futures révisions / ADRs
│   │   └── assets/         # captures de référence (écran de stats Ingress, etc.)
│   └── registry/
│       └── counters.json   # source de vérité : catégories, libellés, ordre, seuils de palier (§3.1.2, §3.1.4)
├── .github/
│   ├── workflows/          # ci.yml, release.yml, pages.yml
│   ├── ISSUE_TEMPLATE/
│   └── dependabot.yml
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## 9. Site GitHub Pages — contenu pour un public non-développeur

Objectif : quelqu'un qui n'a jamais entendu parler de GitHub doit pouvoir comprendre le projet et installer l'app.

- **Accueil** : présentation en une phrase, captures d'écran, mention claire de non-affiliation à Niantic.
- **Fonctionnalités** : ce que l'app fait (et ne fait pas encore).
- **Installer l'app** : guide pas-à-pas pour un public non technique — télécharger l'APK depuis la dernière Release, autoriser l'installation depuis une source inconnue, et une explication rassurante de l'avertissement Play Protect (voir §6).
- **FAQ** : pourquoi pas sur le Play Store (pour l'instant), mes données sont-elles envoyées quelque part (non — tout reste sur le téléphone), que faire si l'ajout de stats ne fonctionne pas.
- **Confidentialité** : politique simple et honnête — v1 100 % locale, aucune donnée collectée, aucun tiers.
- **Feuille de route** : reprise du contenu du §13, formulée simplement.
- **Contribuer** : la partie plus technique (lancer le projet en local, structure du code) pour les développeurs qui voudraient participer.
- **Mentions légales / crédits** : disclaimer Niantic/Ingress, licence du projet, remerciements à Agent Stats comme source d'inspiration.

---

## 10. Légal, confidentialité, licence

- **Licence proposée : MIT** (permissive, standard pour un projet communautaire hobby) — à confirmer par toi (voir §0.2).
- **Confidentialité v1** : argument de vente honnête et simple à tenir — aucune collecte, aucune télémétrie, aucun compte, aucune donnée envoyée. Une nuance à mentionner explicitement (transparence totale plutôt qu'omission) : l'app télécharge, au démarrage, un fichier public de catégorisation des compteurs hébergé sur GitHub Pages (§3.1.4) — une lecture seule, sans aucune donnée personnelle transmise, désactivable dans les préférences. Pas de politique de confidentialité complexe nécessaire tant que ça reste vrai ; à réécrire si un backend ou un outil d'analytics/crash-reporting est ajouté en v2.
- **Marque Ingress/Niantic** : usage strictement descriptif et non-officiel, jamais le logo, mention de non-affiliation visible sur toutes les surfaces publiques (app, README, site).

---

## 11. Roadmap v2+ (pour mémoire, non détaillé ici)

Backend léger avec comptes (probable évolution naturelle une fois le local validé), groupes et classements entre agents, comparaison tête-à-tête avec courbes superposées, recap annuel généré automatiquement et partageable, notifications push serveur, build et distribution iOS complète (TestFlight puis éventuellement App Store), vue « Explorer mes données » avancée pour power users (l'option Grafana mise de côté pour la v1 redeviendrait pertinente ici), ingestion par OCR de capture d'écran comme méthode alternative au texte de partage, widgets d'écran d'accueil Android/iOS.

---

## 12. Annexe A — contenu initial de la couche d'enrichissement (catégories & ordre)

**Ceci n'est pas une liste figée qui détermine quels compteurs l'app supporte** (voir le principe révisé du §3.1.2) : c'est le contenu de départ du fichier d'enrichissement JSON, qui associe catégorie/ordre/libellé aux compteurs déjà connus. Un compteur absent de ce tableau reste suivi normalement par l'app dès qu'il apparaît dans un export ; il est simplement affiché sous son libellé brut, dans une catégorie « Autres » en fin de liste, jusqu'à son ajout ici.

Catégories et ordre repris **tels quels de l'écran de stats d'Ingress Prime** (captures d'écran fournies, à conserver dans le repo sous `docs/spec/assets/ingress-stats-screen-{1,2,3}.png` comme référence pour quiconque enrichit ce fichier plus tard) — colonne « clé technique » = nom de la colonne dans l'export TSV, normalisé en snake_case pour un usage interne :

**Discovery**
`explorer` (Unique Portals Visited), `drone_explorer` (Unique Portals Drone Visited), `drone_distance` (Furthest Drone Distance), `seer` (Seer Points), `collector` (XM Collected), `recon` (OPR Agreements), `scout` (Portal Scans Uploaded), `scout_controller` (Uniques Scout Controlled)

**Building**
`builder` (Resonators Deployed), `connector` (Links Created), `mind_controller` (Control Fields Created), `illuminator` (Mind Units Captured), `binder` (Longest Link Ever Created), `country_master` (Largest Control Field), `recharger` (XM Recharged), `liberator` (Portals Captured), `pioneer` (Unique Portals Captured), `engineer` (Mods Deployed)

**Resource Gathering**
`hacker` (Hacks), `maverick` (Drone Hacks), `translator` (Glyph Hack Points), `overclocker` (Overclock Hack Points)

**Streaks**
`epoch` (Completed Hackstreaks), `sojourner` (Longest Sojourner Streak)

**Combat**
`purifier` (Resonators Destroyed), `neutralizer` (Portals Neutralized), `disruptor` (Enemy Links Destroyed), `salvator` (Enemy Fields Destroyed), `bb_combatant` (Battle Beacon Combatant), `drone_sender` (Drones Returned), `red_disruptor` (Machina Links Destroyed), `red_purifier` (Machina Resonators Destroyed), `red_neutralizer` (Machina Portals Neutralized), `reclaimer` (Machina Portals Reclaimed)

**Defense**
`guardian` (Max Time Portal Held), `smuggler` (Max Time Link Maintained), `link_master` (Max Link Length x Days), `controller` (Max Time Field Held), `field_master` (Largest Field MUs x Days), `drone_recalls` (Forced Drone Recalls)

**Health**
`trekker` (Distance Walked), `crafter` (Kinetic Capsules Completed)

**Missions**
`specops` (Unique Missions Completed)

**Bounties**
`research_bounties` (Research Bounties Completed), `research_days` (Research Days Completed)

**Events**
`missionday` (Mission Day(s) Attended), `nl_1331_meetups` (NL-1331 Meetup(s) Attended), `ifs` (First Saturday Events), `second_sunday` (Second Sunday Events), `opr_live` (OPR Live Events), `anomaly_unique_hacks` (Anomaly Unique Hacks), puis les compteurs propres à l'anomalie en cours au moment de l'export (`orion_tokens`, `orion_link_and_field_points`, `apollo_tokens`, `apollo_mod_battle_points` au moment de la rédaction — ces quatre-là changeront de nom à la prochaine saison et seront alors repris automatiquement par le registre piloté par les données, §3.1.2, en attendant leur propre entrée d'enrichissement)

**Recursion**
`recursions` (Recursions)

**Hors catégorisation en jeu (affichées ailleurs dans Ingress — écran de niveau/AP), suivies séparément par l'app :** `level`, `lifetime_ap` (Lifetime AP), `ap` (Current AP).

**Absents de l'export réel analysé alors qu'ils existaient sur Agent Stats** (`recruiter`, `prime_challenge`, `stealth_ops`, `urban_ops`, `ocf`, `intel_ops`, `operation_chronos`, `cryptic_memories_op`) : cohérent avec l'écran de stats actuel où ils n'apparaissent pas non plus — probablement retirés du jeu. Pas d'entrée d'enrichissement à leur donner dans le fichier de départ ; s'ils réapparaissaient un jour dans un export, ils seraient repris automatiquement comme n'importe quel compteur inconnu (§3.1.2).

---

## 13. Annexe B — format CSV de migration (compatibilité Agent Stats)

Constaté directement sur la page d'import d'Agent Stats — utile pour que les agents qui migrent puissent réutiliser leur export existant sans transformation :

```
Date (aaaa-mm-jj) Heure (hh:mm:ss) ap lifetime_ap explorer drone_explorer drone_distance
seer collector recon scout scout_controller crafter builder connector mind-controller
illuminator binder country-master recharger liberator pioneer engineer hacker maverick
translator overclocker sojourner epoch purifier neutralizer disruptor salvator
bb_combatant red-disruptor red-purifier red-neutralizer reclaimer guardian smuggler
link-master controller field-master drone_recalls drone_sender trekker specops
research_bounties research_days missionday nl-1331-meetups recruiter recursions
prime_challenge stealth_ops urban_ops opr_live ocf intel_ops ifs second_sunday
operation_chronos cryptic_memories_op "comment"
```

Séparateur : espace. L'heure est optionnelle (défaut `00:00:00` si absente). Le champ `comment` final est entre guillemets. L'import v1 de FieldTally doit accepter ce format tel quel pour permettre une migration à droit constant depuis Agent Stats.

**Attention :** ce format CSV n'a pas de colonne `Time Span` ni de colonnes d'anomalie — il ne bénéficie donc que du garde-fou comportemental du §3.1.3 (cohérence monotone entre relevés), pas du garde-fou déclaratif. C'est une raison de plus pour que la vérification de monotonie ne soit jamais désactivée sur ce chemin d'import.

---

## 14. Points restant à trancher par toi avant de démarrer le développement

1. ~~Nom du projet~~ — tranché : `FieldTally`, `applicationId` `io.nohzoh.fieldtally` (§0.2).
2. **Licence** — MIT par défaut, à confirmer ou remplacer.
3. **Identité visuelle** — logo/icône : à produire dès le départ ou placeholder temporaire ?
4. **Langue du site GitHub Pages** — français, anglais, ou les deux ?
5. **Version minimale d'Android ciblée** — proposition par défaut : Android 8.0 (API 26) sauf si tu as une contrainte différente (ex. compatibilité avec un vieux téléphone que tu utilises pour tester).
6. **Compte/keystore de signature Android** — à créer par toi le moment venu pour la pipeline de release (§7.2) ; je peux t'accompagner sur la procédure quand on y sera.

---

*Ce document est destiné à être versionné dans le repo (`docs/spec/`) et amendé au fil du projet plutôt que figé — chaque décision structurante ultérieure peut y être ajoutée sous forme d'ADR (Architecture Decision Record).*
