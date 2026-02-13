# CelestialRecruiter v3.3.0

Assistant de recrutement de guilde complet pour World of Warcraft Retail.
Scanner, file d'attente, templates, anti-spam, analytics, et bien plus.

**Auteur** : Plume | **Discord** : [discord.gg/7FbBTkrH](https://discord.gg/7FbBTkrH)

---

## Installation

1. Copier le dossier `CelestialRecruiter` dans `World of Warcraft\_retail_\Interface\AddOns\`
2. `/reload` en jeu
3. `/cr` pour ouvrir l'interface

---

## Commandes

| Commande | Action |
|----------|--------|
| `/cr` | Ouvrir / fermer l'interface |
| `/cr reset` | Reinitialiser toutes les donnees |
| `/cr help` | Aide rapide |

Les raccourcis clavier se configurent dans **ESC > Raccourcis > CelestialRecruiter**.

---

## Fonctionnalites

### Scanner
- Scan `/who` automatise avec filtres (niveau, classe, zone)
- Import instantane des resultats `/who`
- Detection joueurs sans guilde, support cross-realm
- Cooldown intelligent respectant les limites Blizzard

### File d'attente
- Tri par nom, niveau, classe, ou **score de reputation**
- Actions rapides : recruter, inviter, whisper, ignorer, blacklist
- Indicateurs colores par statut (nouveau, contacte, invite, rejoint)
- Score de reputation avec badge colore et tooltip detaille
- Bouton "Recruter tout" pour traitement en masse

### Boite de reception
- Detection automatique des mots-cles configurables
- Opt-in tracking (keyword `!invite` par defaut)
- Apercu des messages, indicateurs "HOT" pour contacts prometteurs
- Reponse rapide en ligne avec editbox integre
- Tri par recence, score, ou "Hot d'abord"

### Templates de messages
- 3 templates inclus (defaut, raid, court) + templates personnalises
- Variables dynamiques : `{name}`, `{guild}`, `{discord}`, `{raidDays}`, `{goal}`, `{inviteKeyword}`
- Editeur avec previsualisation en temps reel

### Auto-recrutement
- Recrutement automatique avec regles configurables
- Limites de securite : par session, par jour, par heure
- Restrictions horaires, classes prioritaires
- Pause / reprise a tout moment

### A/B Testing
- Compare automatiquement l'efficacite de 2 templates
- Algorithme Thompson Sampling pour allocation intelligente
- Statistiques : taux de reponse, taux de conversion, score
- Gestion dans l'onglet Reglages

### Campagnes
- Organise le recrutement en campagnes avec objectifs
- Suivi de progression (contactes, reponses, recrues)
- Etats : brouillon, active, en pause, terminee, archivee

### Analytics
- Funnel de conversion : contacte > invite > rejoint
- Meilleurs horaires de recrutement
- Performance par template et par classe
- Tendances hebdomadaires (semaine actuelle vs precedente)
- Vue dashboard avec widgets configurables

### Reputation
- Score 0-100 par contact base sur : opt-in, reponses, niveau, source
- Classification : Hot Lead, Promising, Neutral, Cold
- Prediction de conversion
- Tags automatiques

### Suggestions intelligentes
- Meilleur moment pour recruter
- Meilleur template a utiliser
- Contacts a recontacter
- Hot leads a traiter en priorite
- Analyse des classes manquantes

### Succes et objectifs
- 25 succes deblocables en 4 categories (recrutement, social, dedication, maitrise)
- Systeme de streaks (quotidien, hebdomadaire)
- Jalons de progression
- Notification dediee a chaque deblocage

---

## Systeme visuel

### Notifications (3 niveaux)
- **Toast classique** : slide-in depuis la droite, barre de timer, pause au survol
- **Banniere de celebration** : banniere doree centree avec etoiles pulsantes (quand une recrue rejoint la guilde)
- **Toast de succes** : theme violet avec icone (deblocage de succes)

### Particules
- Confettis dores (45 particules) + anneau d'etincelles + flash ecran + starburst a chaque recrue
- Effet scan : balayage vert avec barre lumineuse
- Effets hover et clic sur les boutons
- Effet starburst violet/or pour les succes
- Pool de 60+ textures reutilisables

### Animations
- Shimmer diagonal, glow pulse, compteur anime, remplissage barre
- Fade transition, bounce-in elastique, slide reveal, texte typewriter
- Ouverture/fermeture de la fenetre avec scale + fade
- Indicateur d'onglet glissant avec glow
- Badges pulsants sur changement de valeur

---

## Configuration recommandee

**Anti-spam** :
- Cooldown invitation : 300s, cooldown message : 180s
- Max 8 actions/min, 10 invitations/h, 20 messages/h
- Respect AFK/DND active, blocage en instance active

**Scanner** :
- Niveau 10-80, tranche de 5, delai /who 6s
- Cross-realm active, guildes exclues

**Auto-recrutement** :
- Delai 15s, max 50/session, 100 contacts/jour
- Restriction horaire 18h-23h recommandee

---

## Themes

6 themes inclus : Dark (defaut), Light, Purple Dream, Forest, Ocean, Amber.
Plus un editeur de theme personnalise avec generateur de palette.

---

## Dependances

- Ace3 (inclus) : AceAddon-3.0, AceEvent-3.0, AceDB-3.0
- World of Warcraft Retail 11.0+

---

## Structure des fichiers

```
Core.lua              Point d'entree, detection des recrues (3 methodes)
DB.lua                Base de donnees (contacts, blacklist, logs)
Scanner.lua           Scanner /who automatise
Queue.lua             File d'attente et actions de recrutement
Inbox.lua             Detection whispers entrants
Templates.lua         Gestion des templates de messages
AntiSpam.lua          Rate limiting et cooldowns
Filters.lua           Filtres avances avec presets
Statistics.lua        Collecte de statistiques
Reputation.lua        Score de reputation des contacts
ABTesting.lua         A/B testing de templates (Thompson Sampling)
Campaigns.lua         Gestion de campagnes de recrutement
Goals.lua             25 succes et streaks
SmartSuggestions.lua  Suggestions intelligentes
ImportExport.lua      Import/export et backup auto
AutoRecruiter.lua     Recrutement automatique
Keybinds.lua          Raccourcis clavier
Themes.lua            Systeme de themes
Discord.lua           Integration Discord webhook
BulkOperations.lua    Operations en masse
Minimap.lua           Bouton minimap
ParticleSystem.lua    Effets visuels (confettis, starburst, etc.)
AnimationSystem.lua   Animations (shimmer, glow, bounce, etc.)
Notifications.lua     Toasts, bannieres, succes
Charts.lua            Graphiques pour analytics
DashboardWidgets.lua  Widgets du dashboard
UI_Widgets.lua        Composants UI de base
UI_Scanner.lua        Onglet Scanner
UI_Queue.lua          Onglet File d'attente
UI_Inbox.lua          Onglet Boite de reception
UI_Analytics.lua      Onglet Analytics
UI_Settings.lua       Onglet Reglages
UI_Logs.lua           Onglet Journaux
UI_Help.lua           Onglet Aide
UI.lua                Frame principal, tabs, barre de statut
```

---

## Changelog

### v3.3.0
- Systeme de particules complet (confettis, starburst, scan sweep, hover/clic)
- Notifications 3 niveaux (toast, celebration doree, succes violet)
- Animations avancees (shimmer, glow pulse, bounce, typewriter, etc.)
- UI : animations d'ouverture/fermeture, indicateur d'onglet glissant, badges animes
- Integration : succes utilisent le toast violet, recrues utilisent la banniere doree
- Correctifs de robustesse sur 11 fichiers (nil-safety, pcall, iteration safe)

### v3.2.0
- A/B Testing de templates avec Thompson Sampling
- Campagnes de recrutement avec objectifs
- Suggestions intelligentes (meilleur moment, template, contacts a recontacter)
- 25 succes deblocables et systeme de streaks
- File d'attente avec score de reputation et tri
- Boite de reception avec reponse rapide et indicateurs hot

### v3.1.0
- Correction analytics (comptage reel depuis la base de contacts)
- Detection recrues 3 methodes (CHAT_MSG_SYSTEM, CLUB_MEMBER_ADDED, roster check)
- Matching strict Name-Realm (plus de faux positifs cross-realm)
- Re-verification des recrues contre le roster guilde

### v3.0.0
- Auto-recrutement intelligent
- 6 themes visuels + editeur
- Statistiques et analytics avancees
- Notifications toast
- Filtres avances avec presets
- Import/export et backup auto
- Raccourcis clavier

---

Fait par **plume.pao** avec amour.
