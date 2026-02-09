# CelestialRecruiter

Assistant de recrutement de guilde complet pour World of Warcraft Retail.

## Fonctionnalites

- **Scanner /who** : Recherche automatique de joueurs par niveau, zone et classe avec filtres avancees
- **File d'attente** : Gestion des candidats avec templates de messages personnalisables
- **Boite de reception** : Suivi des reponses et historique des conversations
- **Templates** : Messages de recrutement pre-configures avec variables dynamiques (`{name}`, `{guild}`, `{level}`)
- **Anti-spam** : Cooldowns intelligents pour eviter le spam et respecter les regles Blizzard
- **Blacklist** : Liste noire pour exclure des joueurs du recrutement
- **Journaux** : Historique complet de toutes les actions (invitations, messages, scans)
- **Bouton minimap** : Acces rapide avec compteur de file d'attente

## Installation

1. Telecharger la derniere release (.zip)
2. Extraire le dossier `CelestialRecruiter` dans :
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Relancer WoW ou `/reload`

## Utilisation

- `/cr` : Ouvrir/fermer la fenetre principale
- `/cr scan` : Lancer un scan rapide
- `/cr help` : Afficher l'aide

## Commandes slash

| Commande | Description |
|----------|-------------|
| `/cr` | Toggle la fenetre |
| `/cr scan` | Lancer un scan |
| `/cr queue` | Afficher la file d'attente |
| `/cr help` | Aide |

## Configuration

L'onglet **Reglages** permet de configurer :
- Niveaux min/max pour le scanner
- Cooldown anti-spam (secondes)
- Templates de messages
- Blacklist

## Dependances

- Ace3 (inclus) : AceAddon-3.0, AceEvent-3.0, AceDB-3.0

## Auteur

**Plume** - [Discord](https://discord.gg/7FbBTkrH)

## Licence

Tous droits reserves.
