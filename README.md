# CelestialRecruiter

**Assistant de recrutement de guilde complet pour World of Warcraft (Retail)**

[![Version](https://img.shields.io/badge/version-3.5.0-blue)]()
[![WoW](https://img.shields.io/badge/WoW-Dragonflight-orange)]()
[![Langue](https://img.shields.io/badge/langue-Fran%C3%A7ais-red)]()
[![Discord](https://img.shields.io/badge/Discord-Rejoindre-7289DA)](https://discord.gg/3HwyEBaAQB)

CelestialRecruiter automatise et optimise le recrutement de guilde dans WoW. Scanner `/who`, file d'attente intelligente, templates personnalisables, anti-spam, analytics, gamification, et notifications Discord en temps reel.

> **Auteur** : Plume | **Discord** : [discord.gg/3HwyEBaAQB](https://discord.gg/3HwyEBaAQB)

---

## Table des matieres

- [Installation](#installation)
- [Demarrage rapide](#demarrage-rapide)
- [Fonctionnalites](#fonctionnalites)
  - [Scanner /who](#scanner-who)
  - [File d'attente & Actions](#file-dattente--actions)
  - [Boite de reception (Inbox)](#boite-de-reception-inbox)
  - [Templates de messages](#templates-de-messages)
  - [Auto-Recruteur](#auto-recruteur)
  - [Anti-Spam](#anti-spam)
  - [Filtres & Presets](#filtres--presets)
  - [Reputation & Scoring](#reputation--scoring)
  - [Statistiques & Analytics](#statistiques--analytics)
  - [Objectifs & Succes](#objectifs--succes)
  - [Leaderboard](#leaderboard)
  - [Campagnes](#campagnes)
  - [A/B Testing](#ab-testing)
  - [Suggestions intelligentes](#suggestions-intelligentes)
  - [Import / Export](#import--export)
  - [Integration Discord](#integration-discord)
  - [Effets visuels (FX)](#effets-visuels-fx)
  - [Themes](#themes)
- [Commandes slash](#commandes-slash)
- [Architecture du projet](#architecture-du-projet)
- [Integration Discord (guide complet)](#integration-discord-guide-complet)
- [FAQ](#faq)
- [Changelog](#changelog)

---

## Installation

1. Telecharger ou cloner ce depot dans le dossier AddOns de WoW :
   ```
   World of Warcraft/_retail_/Interface/AddOns/CelestialRecruiter/
   ```
2. Les librairies Ace3 sont incluses (pas de dependance externe).
3. Relancer WoW ou `/reload` en jeu.
4. L'addon apparait sur la minimap et repond a `/cr`.

---

## Demarrage rapide

1. **Ouvrir l'addon** : clic gauche sur le bouton minimap ou `/cr`
2. **Configurer** : onglet Settings > renseigner nom de guilde, discord, jours de raid
3. **Scanner** : onglet Scanner > cliquer "Scan Manuel" ou activer l'Auto-Scan
4. **Recruter** : onglet Queue > selectionner un joueur > Whisper / Invite / Recruter
5. **Suivre** : onglet Analytics pour voir les conversions et tendances

---

## Fonctionnalites

### Scanner /who

Le coeur du recrutement automatise. Le scanner envoie des requetes `/who` par classe et tranche de niveau pour decouvrir des joueurs potentiels.

| Fonction | Description |
|---|---|
| **Scan manuel** | Lance un cycle de scan immediat (bouton avec cooldown) |
| **Auto-Scan** | Scans continus en arriere-plan, declenches par evenements hardware (clic/touche) |
| **Filtrage intelligent** | Exclut automatiquement : joueurs en guilde, cross-realm, blacklistes, deja contactes (<7j) |
| **Tranche de niveau** | Configurable (min/max/taille de tranche) |
| **Filtre par classe** | Selection des classes a scanner |
| **Liste de resultats** | Tableau triable (nom, niveau, classe, zone, guilde) avec actions individuelles |
| **Import WHO** | Importer les joueurs du panneau /who natif de WoW |
| **Thompson Sampling** | Planification adaptative des requetes pour maximiser les decouvertes |

### File d'attente & Actions

La file d'attente centralise les joueurs a contacter, tries par score de reputation.

| Action | Description |
|---|---|
| **Whisper** | Envoie un message template personnalise au joueur |
| **Invite** | Envoie une invitation de guilde (necessite clic physique) |
| **Recruter** | Whisper + Invite combines en une seule action |
| **Operations en masse** | Selection multiple + whisper/invite en lot |
| **Score de priorite** | Affichage du score 0-100 avec code couleur |
| **Tri intelligent** | Par score de reputation, date, niveau, classe |

Chaque action respecte les regles anti-spam et met a jour automatiquement le statut du contact, les statistiques, le leaderboard, et les notifications Discord.

### Boite de reception (Inbox)

Detection et gestion automatique des whispers entrants.

- **Detection automatique** des whispers contenant des mots-cles (configurable)
- **Mot-cle d'invitation** : un joueur qui repond `!invite` est automatiquement marque opt-in
- **Historique de conversation** : messages entrants et sortants par contact (50 max)
- **Reponse rapide** depuis l'interface
- **Effet visuel** : explosion de particules vertes a chaque nouveau contact
- **Notification Discord** pour chaque whisper recu

### Templates de messages

Systeme de templates pour personnaliser les messages de recrutement.

**Templates inclus :**
- **Defaut** : `Salut {name}, la guilde {guild} recrute...`
- **Raid** : `Salut {name}, {guild} recrute pour roster raid...`
- **Court** : `{name}, {guild} recrute...`

**Variables disponibles :**

| Variable | Remplacee par |
|---|---|
| `{name}` | Nom du joueur cible |
| `{guild}` | Nom de votre guilde |
| `{discord}` | Lien Discord de la guilde |
| `{raidDays}` | Jours de raid |
| `{goal}` | Objectif de la guilde |
| `{inviteKeyword}` | Mot-cle d'opt-in (defaut: `!invite`) |

- Creation de templates personnalises illimitee
- Troncature UTF-8 safe (max 240 caracteres)
- Normalisation automatique des espaces

### Auto-Recruteur

Recrutement 100% automatise avec moteur de regles configurable.

| Regle | Description |
|---|---|
| **Mode** | Whisper seul, Invite seul, ou les deux |
| **Template** | Choix du template a utiliser |
| **Delai** | Temps entre chaque action (defaut: 15s) |
| **Filtres niveau/classe** | Classes cibles et plage de niveau |
| **Classes prioritaires** | Classes traitees en premier |
| **Plage horaire** | Actif uniquement entre certaines heures (ex: 18h-23h) |
| **Limites journalieres** | Max contacts/invites par jour |
| **Conditions de skip** | Ignorer les joueurs en guilde, deja contactes, etc. |
| **Cross-realm** | Exclure ou inclure les joueurs d'autres royaumes |
| **Opt-in requis** | N'inviter que les joueurs ayant repondu au mot-cle |

Respecte toutes les regles anti-spam. Suit les statistiques en temps reel.

### Anti-Spam

Systeme de protection integre pour eviter le spam et respecter les joueurs.

| Protection | Defaut |
|---|---|
| Max actions/minute | 8 |
| Max whispers/heure | 20 |
| Max invites/heure | 10 |
| Cooldown whisper | 180s |
| Cooldown invite | 300s |
| Cooldown re-invite | 7 jours |

**Detections automatiques :**
- Joueur AFK (ecoute `CHAT_MSG_AFK`) > respect pendant X minutes
- Joueur DND (ecoute `CHAT_MSG_DND`) > respect pendant X minutes
- Blocage en instance (pas de recrutement en donjon/raid)
- Prevention auto-ciblage
- Verification blacklist

### Filtres & Presets

Filtrage multi-criteres avance pour toutes les listes de contacts.

**Criteres disponibles :**
- Recherche texte (nom / notes)
- Statut : `new`, `contacted`, `invited`, `joined`, `ignored`
- Classe (multi-selection des 13 classes)
- Race
- Plage de niveau
- Source (scanner / inbox)
- Opt-in, cross-realm
- Tags personnalises
- Activite recente (X derniers jours)

**Presets** : sauvegardez et rechargez vos combinaisons de filtres preferees.

### Reputation & Scoring

Algorithme intelligent de scoring (0-100) pour prioriser les meilleurs candidats.

| Critere | Impact |
|---|---|
| Contact recent (aujourd'hui) | +20 |
| Opt-in (a repondu) | +30 |
| Niveau max | +15 |
| A repondu a un whisper | +25 |
| Source inbox | +20 |
| Cross-realm | -10 |
| Tags `priority` / `hot` | +15 |
| Tags `tank` / `heal` | +10 |
| Tags `friend` | +20 |
| Tags `spam` / `bot` | -30 |
| Statut `ignored` | -50 |

**Classes de score :**
- **Hot** (80+) : candidat ideal
- **Promising** (60+) : bon potentiel
- **Neutral** (40+) : standard
- **Cold** (20+) : faible priorite
- **Ignore** (<20) : a eviter

### Statistiques & Analytics

Tableau de bord complet pour analyser vos performances de recrutement.

- **Funnel de conversion** : contactes > invites > rejoints (avec pourcentages)
- **Distribution par classe** (graphique camembert/barres)
- **Heatmap horaire** : quelles heures sont les plus actives
- **Graphe d'activite quotidienne** (7 / 30 jours)
- **Performance des templates** : taux de reponse par template
- **Meilleures heures** : classement des creneaux les plus efficaces
- **Tendances hebdomadaires** : comparaison cette semaine vs. semaine derniere
- **Records personnels** : meilleur jour, meilleure semaine, plus longue serie
- **Historique 90 jours** : scans, contacts, invites, recrues par jour

### Objectifs & Succes

Systeme de gamification avec succes deblocables et jalons.

**Categories de succes :**

| Categorie | Exemples |
|---|---|
| **Recrutement** | 1er contact, 10/50/100/500/1000 contacts, recrues rejointes |
| **Social** | Papillon social, lanceur de conversation |
| **Diversite** | Toutes les classes recrutees, jalons par classe |
| **Vitesse** | Reponse la plus rapide, recrue la plus rapide |
| **Regularite** | Series quotidiennes/hebdomadaires, recrutement constant |

13 classes WoW supportees : Guerrier, Paladin, Chasseur, Voleur, Pretre, Chevalier de la mort, Chaman, Mage, Demoniste, Moine, Druide, Chasseur de demons, Evocateur.

### Leaderboard

Suivi de performance personnel avec systeme de tiers.

| Tier | Recrues requises | Couleur |
|---|---|---|
| Bronze | 5 | Bronze |
| Argent | 25 | Argent |
| Or | 100 | Or |
| Diamant | 500 | Bleu diamant |

**Metriques suivies :**
- Contacts, invites, recrues, whispers, scans (quotidien/hebdo/mensuel)
- Records personnels : meilleur jour, meilleure semaine, plus longue serie
- Temps de conversion le plus rapide (contact > recrue)
- Heatmap d'activite par heure et par jour de la semaine
- Statistiques all-time cumulees

### Campagnes

Organisez vos efforts de recrutement en campagnes ciblees.

**Cycle de vie** : `brouillon` > `active` > `en pause` > `terminee` > `archivee`

- Objectifs par campagne (nombre de contactes, invites, recrues)
- Filtres cibles (niveau, classes, zones, cross-realm)
- Template dedie par campagne
- Planning (jours/heures d'activite)
- Roster de contacts par campagne
- Statistiques dediees (contactes, invites, recrues, reponses)
- Progression vers les objectifs

### A/B Testing

Optimisez vos messages grace aux tests statistiques.

- **Tests multi-variantes** : comparez 2+ templates simultanement
- **Thompson Sampling** : allocation adaptative du trafic
- **Metriques par variante** : envoyes, reponses, recrues
- **Taux de conversion** : contact>invite, invite>recrue, contact>recrue
- **Seuil de confiance** (defaut 0.95) : determination statistique du gagnant
- **Cycle** : `pause` > `actif` > `termine`
- Un seul test actif a la fois

### Suggestions intelligentes

Analyse automatique des donnees pour recommander des optimisations.

- **Meilleur creneau** : analyse horaire pour identifier les heures optimales
- **Meilleur template** : suggestion du template le plus performant
- **Classes manquantes** : identification des classes sous-representees
- **Opportunites de conversion** : contacts "stales" a relancer
- **Patterns d'activite** : fenetres optimales de recrutement

### Import / Export

Sauvegarde et transfert de donnees.

- **Export** : contacts, templates, parametres (serialisation Lua safe)
- **Import** : depuis chaine de texte (max 1 Mo, environnement sandbox)
- **Auto-backup** : sauvegarde quotidienne automatique dans SavedVariables
- **Transfert** : deplacez vos donnees entre personnages ou comptes

### Integration Discord

Notifications en temps reel vers votre serveur Discord via webhook.

**16 types d'evenements :**

| Categorie | Evenements |
|---|---|
| **Guilde** | Membre rejoint, part, promu, retrograde |
| **Recrutement** | Whisper envoye, invite envoyee, joueur rejoint |
| **File d'attente** | Joueur ajoute, retire |
| **Blacklist** | Joueur blackliste |
| **Scanner** | Demarre, arrete, termine |
| **Auto-recruteur** | Demarre, arrete, termine |
| **Rapports** | Resume quotidien, resume de session |
| **Alertes** | Limite atteinte, erreur |

**Architecture** : Addon (Lua) > SavedVariables (disque) > Script Python > Discord Webhook

Chaque evenement est colore (vert = positif, bleu = info, orange = warning, rouge = negatif, violet = systeme, or = special).

> Voir [Integration Discord (guide complet)](#integration-discord-guide-complet) plus bas.

### Effets visuels (FX)

Moteur d'effets visuels pour celebrer les moments cles.

- **Particules** : systeme pooled (60 particules, expansion auto), gravite, rotation, fade
- **Feux d'artifice** : explosion or/violet quand une recrue rejoint la guilde
- **Burst vert** : particules vertes pour chaque nouveau contact
- **Flash ecran** : overlay lumineux pour les moments epiques
- **Notifications toast** : bandeaux empiles (max 5), timer visuel, pause au survol
- **Bannieres de celebration** : grande banniere centree avec emoji
- **Toasts de succes** : style achievement WoW
- **Animations** : slide-in elastique, pulse glow, fade-out
- **Graphiques** : lignes, barres, camembert avec auto-scaling et grille
- **Animations avancees** : shimmer, glow pulse, compteur anime, barre de progression, typewriter

### Themes

4 themes visuels avec palette complete.

| Theme | Description |
|---|---|
| **Dark** (defaut) | Bleu/gris profond |
| **Light** | Pastels lumineux |
| **Purple Dream** | Accents violets |
| **Forest** | Tons verts naturels |

Changement de theme en temps reel depuis les parametres.

---

## Commandes slash

| Commande | Description |
|---|---|
| `/cr` | Ouvrir/fermer la fenetre principale |
| `/cr reset` | Reinitialiser la position de la fenetre |
| `/cr flush` | Envoyer immediatement les notifications Discord en attente |
| `/cr help` | Afficher l'aide |

**Bouton minimap** : clic gauche = ouvrir, clic droit = lancer un scan.

**Raccourcis clavier** : configurable dans ESC > Raccourcis > CelestialRecruiter.

---

## Architecture du projet

```
CelestialRecruiter/
|
|-- Core/                     # Noyau de l'addon
|   |-- Util.lua              # Fonctions utilitaires (texte, temps, tri, realm)
|   |-- DB.lua                # Base de donnees (contacts, queue, blacklist, logs)
|   |-- Core.lua              # Initialisation Ace, events guilde, slash commands
|
|-- Modules/                  # Logique metier
|   |-- Scanner.lua           # Scanner /who avec auto-scan et Thompson Sampling
|   |-- Queue.lua             # Actions de recrutement (whisper, invite, recruit)
|   |-- Inbox.lua             # Detection de whispers entrants et opt-in
|   |-- AntiSpam.lua          # Rate limiting et protection anti-spam
|   |-- Templates.lua         # Templates de messages avec variables
|   |-- Filters.lua           # Filtrage multi-criteres avec presets
|   |-- AutoRecruiter.lua     # Recrutement automatise avec regles
|   |-- Reputation.lua        # Scoring intelligent des contacts (0-100)
|   |-- Statistics.lua        # Statistiques avancees et tendances
|   |-- Goals.lua             # Succes et gamification
|   |-- Leaderboard.lua       # Performance et tiers (Bronze > Diamant)
|   |-- Campaigns.lua         # Campagnes de recrutement ciblees
|   |-- ABTesting.lua         # Tests A/B de templates
|   |-- SmartSuggestions.lua  # Suggestions basees sur les donnees
|   |-- ImportExport.lua      # Sauvegarde et transfert de donnees
|   |-- Keybinds.lua          # Raccourcis clavier
|   |-- Minimap.lua           # Bouton minimap avec badge
|   |-- Discord.lua           # Integration Discord (legacy)
|   |-- DiscordQueue.lua      # File d'attente Discord moderne
|   |-- BulkOperations.lua    # Operations en masse
|
|-- UI/                       # Interface utilisateur
|   |-- Widgets.lua           # Composants reutilisables (boutons, inputs, dropdowns)
|   |-- Main.lua              # Fenetre principale a onglets (7 tabs)
|   |-- Scanner.lua           # Panel du scanner avec resultats
|   |-- Queue.lua             # Panel de la file d'attente
|   |-- Inbox.lua             # Panel de la boite de reception
|   |-- Analytics.lua         # Tableau de bord statistiques
|   |-- Settings.lua          # Panel de configuration
|   |-- Logs.lua              # Visualiseur de logs (300 entrees)
|   |-- Help.lua              # Documentation in-game
|   |-- DashboardWidgets.lua  # Widgets du dashboard
|   |-- FilterBar.lua         # Barre de filtres visuelle
|
|-- FX/                       # Effets visuels
|   |-- Themes.lua            # 4 themes avec palette complete
|   |-- AnimationSystem.lua   # Animations (easing, shimmer, typewriter)
|   |-- ParticleSystem.lua    # Moteur de particules (pool, gravite, rotation)
|   |-- Charts.lua            # Graphiques (lignes, barres, camembert)
|   |-- Notifications.lua     # Toasts, bannieres, achievements
|
|-- Libs/                     # Librairies externes (Ace3)
|   |-- LibStub/
|   |-- CallbackHandler-1.0/
|   |-- AceAddon-3.0/
|   |-- AceEvent-3.0/
|   |-- AceDB-3.0/
|
|-- Tools/                    # Outils externes
|   |-- discord_webhook.py    # Script Python - envoi des events Discord
|   |-- start_discord_bot.bat # Lanceur Windows
|   |-- config.json           # Configuration du script Discord
|   |-- requirements.txt      # Dependances Python (requests, watchdog)
|   |-- DISCORD_SETUP.md      # Guide d'installation Discord
|   |-- INTEGRATION_GUIDE.md  # Documentation developpeur
|
|-- CelestialRecruiter.toc    # Table of Contents WoW
```

### Flux de donnees

```
Decouverte          Stockage           Action              Suivi
---------           --------           ------              -----
Scanner /who  --->  DB contacts  --->  Whisper/Invite --->  Stats + Discord
Inbox whisper --->  File attente --->  Auto-Recruteur --->  Leaderboard
                    Reputation         Anti-Spam            Succes/Goals
```

### Persistance

| Scope | Donnees |
|---|---|
| **Global** | Contacts, queue, blacklist, logs, campagnes, stats, Discord queue |
| **Profil** | Parametres guilde, templates, mots-cles, config anti-spam |
| **Personnage** | Leaderboard, records personnels, stats de session |

---

## Integration Discord (guide complet)

L'addon envoie des notifications Discord en temps reel grace a un script Python companion.

### Principe

```
WoW Addon (Lua)  -->  SavedVariables (disque)  -->  Script Python  -->  Discord Webhook
```

L'addon queue les evenements dans `CelestialRecruiterDB` (SavedVariables). Le script Python surveille ce fichier et envoie les messages au webhook Discord.

### Installation pas a pas

1. **Creer un webhook Discord** :
   - Parametres du serveur > Integrations > Webhooks > Nouveau webhook
   - Copier l'URL du webhook

2. **Installer Python 3.7+** et les dependances :
   ```bash
   cd Tools/
   pip install -r requirements.txt
   ```

3. **Configurer** `Tools/config.json` :
   ```json
   {
     "savedvariables_path": "C:\\...\\WTF\\Account\\VOTRECOMPTE\\SavedVariables\\CelestialRecruiterDB.lua",
     "webhook_url": "https://discord.com/api/webhooks/VOTRE_WEBHOOK",
     "check_interval": 5,
     "rate_limit_delay": 2
   }
   ```

4. **Configurer in-game** : Settings > Discord > coller l'URL webhook + activer les evenements souhaites

5. **Lancer le script** :
   ```bash
   python Tools/discord_webhook.py
   ```
   Ou double-cliquer `Tools/start_discord_bot.bat`.

6. **Flush immediat** : `/cr flush` en jeu ou `/reload` pour forcer l'ecriture des SavedVariables.

---

## FAQ

**Q : L'addon fonctionne-t-il en anglais ?**
R : L'interface est en francais (frFR). Les commandes slash et la logique fonctionnent independamment de la langue du client.

**Q : Peut-on recruter en cross-realm ?**
R : Oui, c'est activable/desactivable dans les parametres du scanner et de l'auto-recruteur.

**Q : Comment eviter le spam ?**
R : Le systeme anti-spam est actif par defaut avec des limites strictes. Un cooldown de 7 jours empeche de recontacter un joueur deja invite.

**Q : Les notifications Discord arrivent-elles en temps reel ?**
R : WoW ecrit les SavedVariables au `/reload` ou a la deconnexion. Utilisez `/cr flush` pour forcer l'envoi. Le script Python verifie le fichier toutes les 5 secondes.

**Q : Comment fonctionne l'Auto-Scan ?**
R : Il necessite des evenements hardware (clic souris/touche clavier) car WoW exige une action physique pour `SendWho()`. L'addon hook le WorldFrame pour intercepter les clics naturels du gameplay.

**Q : Comment lire mon score de reputation ?**
R : 80+ = Hot (ideal), 60+ = Promising, 40+ = Neutral, 20+ = Cold, <20 = Ignore. Le score est visible dans la file d'attente a cote de chaque joueur.

**Q : Puis-je utiliser l'addon avec plusieurs personnages ?**
R : Oui. Les contacts et la queue sont globaux (partages entre persos). Le leaderboard et les stats de session sont par personnage.

**Q : Quelles librairies sont necessaires ?**
R : Ace3 est inclus dans le dossier `Libs/`. Aucune dependance externe cote WoW. Le script Discord necessite Python 3.7+ avec `requests` et `watchdog`.

---

## Changelog

### v3.5.0
- Auto-Scan : scan semi-automatique via WorldFrame + clavier
- Liste de resultats dans l'onglet Scanner avec skipReason
- Reorganisation du projet : 4 dossiers (Core, Modules, UI, FX)
- Integration Discord modernisee (DiscordQueue + script Python)

### v3.4.0
- Classement personnel avec paliers, records et heatmap
- Tutoriel complet, section Succes dans Analytics
- Widgets dashboard, textes francais uniformises

### v3.3.0
- Particules, notifications 3 niveaux, animations avancees
- UI : ouverture/fermeture animee, badges animes

### v3.2.0
- A/B Testing, campagnes, suggestions intelligentes
- 25 succes, reputation, reponse rapide inbox

### v3.1.0
- Detection recrues 3 methodes, matching strict Name-Realm

### v3.0.0
- Auto-recrutement, 6 themes, analytics, filtres avances

---

## Dependances

- **WoW** : Retail 11.0+ (Dragonflight)
- **Ace3** (inclus) : AceAddon-3.0, AceEvent-3.0, AceDB-3.0
- **Discord** (optionnel) : Python 3.7+, requests, watchdog

---

Fait par **plume.pao** avec amour.
