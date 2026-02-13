# CelestialRecruiter v3.5.0

Assistant de recrutement de guilde pour World of Warcraft Retail.

**Auteur** : Plume | **Discord** : [discord.gg/3HwyEBaAQB](https://discord.gg/3HwyEBaAQB)

---

## Installation

1. Copier `CelestialRecruiter/` dans `Interface\AddOns\`
2. `/reload` en jeu
3. `/cr` pour ouvrir l'interface

## Commandes

| Commande | Action |
|----------|--------|
| `/cr` | Ouvrir / fermer |
| `/cr reset` | Reinitialiser les donnees |
| `/cr help` | Aide rapide |

Raccourcis clavier : **ESC > Raccourcis > CelestialRecruiter**

---

## Fonctionnalites

### Scanner /who
- Scan par classe et tranche de niveau, filtres cross-realm et guilde
- **Auto-Scan** : chaque clic ou touche du clavier declenche la requete suivante (restriction Blizzard : /who necessite une action physique)
- Liste de resultats avec statut, bouton d'ajout rapide
- Import instantane des resultats `/who` manuels

### File d'attente
- Tri par nom, niveau, classe ou score de reputation
- Actions : recruter, inviter, whisper, ignorer, blacklist
- Indicateurs par statut et score colore
- Traitement en masse

### Boite de reception
- Detection mots-cles et opt-in (`!invite`)
- Indicateurs "HOT", reponse rapide en ligne
- Tri par recence, score ou priorite

### Auto-recrutement
- Whisper/invite automatique avec limites de securite
- Restrictions horaires, classes prioritaires
- Pause / reprise a tout moment

### Templates
- 3 inclus + personnalises, variables dynamiques (`{name}`, `{guild}`, `{discord}`...)
- A/B testing avec Thompson Sampling

### Analytics & Progression
- Funnel de conversion, meilleurs horaires, performance par template
- 25 succes, streaks, classement personnel (Bronze > Diamant)
- Suggestions intelligentes, campagnes avec objectifs

### Visuel
- 6 themes + editeur, particules, animations, notifications toast/banniere

---

## Structure du projet

```
CelestialRecruiter/
├── Core/               Fondations (Util, DB, Core)
├── Modules/            Logique metier (Scanner, Queue, AutoRecruiter, ...)
├── UI/                 Interface (Widgets, onglets, Main)
├── FX/                 Visuel (Themes, Animations, Particules, Charts, Notifications)
└── Libs/               Ace3 (inclus)
```

## Dependances

- Ace3 (inclus) : AceAddon-3.0, AceEvent-3.0, AceDB-3.0
- World of Warcraft Retail 11.0+

---

## Changelog

### v3.5.0
- Auto-Scan : scan semi-automatique via WorldFrame + clavier (contourne la restriction hwevent de Blizzard)
- Liste de resultats dans l'onglet Scanner avec skipReason, lignes dim pour ineligibles
- Tooltip d'avertissement sur la checkbox Auto expliquant le fonctionnement
- Reorganisation du projet : 4 dossiers (Core, Modules, UI, FX)

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

Fait par **plume.pao** avec amour.
