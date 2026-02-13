# CelestialRecruiter v3.0.0 🌟

**L'addon de recrutement de guilde le plus avancé pour World of Warcraft**

Un outil professionnel de recrutement avec intelligence artificielle, automatisation et analytics avancées.

---

## ✨ Fonctionnalités v3.0.0

### 🔍 Scanner Intelligent
- **Scan /who automatisé** avec filtres multi-critères (niveau, classe, zone)
- **Import instantané** des résultats /who actuels
- **Détection automatique** des joueurs sans guilde
- **Cross-realm support** avec filtrage optionnel
- **Cooldown intelligent** pour respecter les limites Blizzard

### 📋 Gestion de File d'Attente
- **Organisation avancée** avec tri et filtrage
- **Actions rapides** : recruter, inviter, message individuel ou en masse
- **Statuts colorés** : nouveau, contacté, invité, rejoint, ignoré
- **Tags personnalisés** pour catégoriser vos contacts
- **Notes riches** sur chaque contact

### 🤖 Auto-Recrutement Intelligent **[NOUVEAU]**
- **Recrutement automatique** avec règles configurables
- **Limites de sécurité** : max par session, par jour, par heure
- **Restrictions horaires** (ex: recruter uniquement 18h-23h)
- **Filtres avancés** : niveau, classe, cross-realm, opt-in
- **Classes prioritaires** traitées en premier
- **Pause/Reprise** à tout moment
- **Statistiques temps réel** du processus

### 🎨 Thèmes Visuels **[NOUVEAU]**
- **6 thèmes préconçus** : Dark, Light, Purple Dream, Forest, Ocean, Amber
- **Thème personnalisé** avec éditeur de couleurs
- **Application instantanée** avec prévisualisation
- **Générateur de palette** à partir d'une couleur de base

### 📊 Statistiques & Analytics **[NOUVEAU]**
- **Taux de conversion** (contacté → invité → rejoint)
- **Meilleurs horaires** de recrutement
- **Performance des templates** (taux de succès)
- **Historique quotidien** (30 derniers jours)
- **Distribution par classe** des recrues
- **Tendances hebdomadaires** (comparaison semaine actuelle vs précédente)

### 🔔 Notifications Toast **[NOUVEAU]**
- **Notifications élégantes** en slide-in
- **4 types** : succès, erreur, warning, info
- **Auto-dismiss** configurable
- **Empilables** jusqu'à 5 notifications
- **Animations fluides** avec glass-morphism

### 🎯 Filtres Avancés **[NOUVEAU]**
- **Filtrage multi-critères** : statut, classe, niveau, tags, source
- **Recherche texte** dans nom et notes
- **Filtres sauvegardables** (presets)
- **Application instantanée** avec debouncing
- **Compteur de filtres actifs**

### 💾 Import/Export & Backup **[NOUVEAU]**
- **Export complet** : contacts, templates, settings, stats
- **Import sélectif** (merge ou replace)
- **Backup automatique quotidien** (conserve les 5 derniers)
- **Partage de templates** entre personnages
- **Format lisible** pour édition manuelle

### ⌨️ Raccourcis Clavier **[NOUVEAU]**
- **Toggle UI** : ouvrir/fermer l'interface
- **Lancer scan** : démarrer un scan immédiatement
- **Recruter suivant** : traiter le prochain en file
- **Inviter suivant** : inviter le prochain en file
- **Message suivant** : envoyer message au prochain
- **Toggle auto-recrutement** : démarrer/arrêter l'auto
- **Navigation tabs** : aller directement à Scanner/Queue/Inbox/Settings
- **Configuration** dans ESC > Raccourcis clavier > CelestialRecruiter

### 📨 Templates de Messages
- **Templates pré-configurés** : défaut, raid, court
- **Variables dynamiques** : `{name}`, `{guild}`, `{discord}`, `{raidDays}`, `{goal}`, `{inviteKeyword}`
- **Éditeur intégré** avec prévisualisation
- **Reset vers défaut** en un clic
- **Troncature automatique** à 240 caractères

### 🛡️ Anti-Spam & Sécurité
- **Cooldowns personnalisables** (invitation, message)
- **Rate limiting** : actions par minute, invitations/messages par heure
- **Respect AFK/DND** avec période de rétention configurable
- **Blocage en instance** optionnel
- **Blacklist** permanente
- **Ignore temporaire** avec expiration

### 📬 Boîte de Réception
- **Détection automatique** des mots-clés configurables
- **Opt-in tracking** avec keyword `!invite` (configurable)
- **Tri par récence** des messages reçus
- **Statut des contacts** mis à jour automatiquement

### 📜 Journaux d'Activité
- **Historique complet** de toutes les actions
- **Filtres par type** : SCAN, INV, OUT, IN, ERR, SKIP, etc.
- **Codes couleur** pour identification rapide
- **Limite configurable** (50-1000 entrées)
- **Export possible** pour analyse externe

### 🎨 Interface Moderne
- **Design glass-morphism** avec effets de profondeur
- **Animations fluides** : fade, slide, bounce, scale
- **Smooth scrolling** avec momentum
- **Transitions entre tabs** avec fade
- **Badges pulsants** sur notifications
- **Tooltips enrichis** avec informations détaillées
- **Hover effects** sur tous les éléments interactifs
- **Responsive** : redimensionnable (720x460 → 1400x900)

---

## 📦 Installation

1. Télécharger la dernière release v3.0.0
2. Extraire le dossier `CelestialRecruiter` dans :
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Relancer WoW ou taper `/reload`
4. Configurer vos raccourcis clavier (ESC > Raccourcis clavier > CelestialRecruiter)

---

## 🚀 Guide Rapide

### Première Utilisation
1. Ouvrir l'addon : `/cr` ou clic sur bouton minimap
2. Onglet **Réglages** :
   - Configurer nom de guilde, Discord, objectifs
   - Ajuster niveaux min/max de scan
   - Personnaliser templates de messages
   - Définir mots-clés de détection
3. Onglet **Scanner** :
   - Clic sur "Scanner" pour lancer recherche
   - Ou utiliser raccourci clavier (à configurer)
4. Onglet **File d'attente** :
   - Voir les contacts trouvés
   - Actions individuelles ou en masse
   - Filtrer selon vos critères

### Mode Auto-Recrutement
1. Configurer les règles dans **Réglages > Auto-Recrutement** :
   - Mode : Message / Invitation / Les deux
   - Template à utiliser
   - Délai entre actions (15s recommandé)
   - Limites quotidiennes et par session
   - Restrictions horaires optionnelles
   - Classes prioritaires
2. Lancer avec bouton "Auto" ou raccourci clavier
3. Surveiller la progression en temps réel
4. Pause/Reprise selon besoin
5. Stop automatique à la fin ou sur limites atteintes

---

## ⌨️ Commandes & Raccourcis

### Commandes Slash
| Commande | Description |
|----------|-------------|
| `/cr` | Ouvrir/fermer l'interface |
| `/cr reset` | Réinitialiser toutes les données |
| `/cr help` | Afficher l'aide |

### Raccourcis Clavier (à configurer)
| Action | Description |
|--------|-------------|
| Toggle UI | Ouvrir/fermer l'interface |
| Lancer Scan | Démarrer un scan /who immédiatement |
| Recruter Suivant | Traiter le prochain contact (message + invite) |
| Inviter Suivant | Inviter le prochain contact |
| Message Suivant | Envoyer message au prochain contact |
| Toggle Auto | Démarrer/arrêter l'auto-recrutement |
| Tab Scanner | Aller à l'onglet Scanner |
| Tab Queue | Aller à l'onglet File d'attente |
| Tab Inbox | Aller à l'onglet Boîte |
| Tab Settings | Aller à l'onglet Réglages |

---

## 🎨 Thèmes Disponibles

- **Dark** (défaut) : Élégant et sobre, parfait pour sessions longues
- **Light** : Lumineux et aéré, idéal en journée
- **Purple Dream** : Mystique et enchanteur
- **Forest** : Apaisant et naturel
- **Ocean** : Profond et serein
- **Amber** : Chaleureux et accueillant
- **Custom** : Créez votre propre palette !

---

## 📊 Comprendre les Statistiques

### Taux de Conversion
- **Contacté → Invité** : % de contacts qui reçoivent une invitation après message
- **Invité → Rejoint** : % d'invités qui rejoignent effectivement
- **Contacté → Rejoint** : Taux de conversion global

### Meilleurs Horaires
- Basé sur votre activité passée
- Identifie les heures où vous recrutez le plus
- Utile pour planifier auto-recrutement

### Performance Templates
- Compare l'efficacité de vos différents templates
- Taux de succès = recrues rejointes / template utilisé
- Optimisez vos messages selon les résultats

---

## 🛠️ Configuration Avancée

### Anti-Spam Optimal
```
Cooldown Invitation: 300s (5 min)
Cooldown Message: 180s (3 min)
Max Actions/Minute: 8
Max Invitations/Heure: 10
Max Messages/Heure: 20
Respect AFK/DND: ✓ (900s hold)
Bloquer en Instance: ✓
```

### Scanner Efficace
```
Niveau Min: 10
Niveau Max: 80
Tranche de Niveaux: 5
Délai /who: 6s
Timeout /who: 8s
Inclure Guildés: ✗
Inclure Cross-Realm: ✓
```

### Auto-Recrutement Sûr
```
Mode: Recruter (message + invite)
Délai entre Actions: 15s
Max par Session: 50
Max Contacts/Jour: 100
Max Invitations/Jour: 50
Restrictions Horaires: 18:00-23:00
```

---

## 🔧 Dépendances

- **Ace3** (inclus) : AceAddon-3.0, AceEvent-3.0, AceDB-3.0
- **World of Warcraft Retail** (11.0+)

---

## 💡 Astuces & Bonnes Pratiques

1. **Scannez régulièrement** mais respectez le cooldown (6s recommandé)
2. **Personnalisez vos templates** pour votre guilde spécifique
3. **Utilisez les tags** pour organiser vos contacts (ex: "tank", "dps", "heal")
4. **Activez l'opt-in** si vous voulez respecter la volonté des joueurs
5. **Exportez vos données** régulièrement (backup auto quotidien activé)
6. **Consultez les statistiques** pour optimiser votre recrutement
7. **Utilisez l'auto-recrutement** pendant vos sessions farm/craft
8. **Configurez les raccourcis clavier** pour efficacité maximale
9. **Testez différents templates** et comparez les performances
10. **Respectez toujours** les règles Blizzard et la communauté

---

## 🐛 Signaler un Bug

- [GitHub Issues](https://github.com/votre-repo/issues) *(à mettre à jour)*
- [Discord](https://discord.gg/7FbBTkrH)

---

## 🗺️ Roadmap v3.1+

- [ ] Intégration WeakAuras
- [ ] API publique pour autres addons
- [ ] Graphiques visuels des statistiques
- [ ] Machine learning pour prédire meilleurs moments
- [ ] A/B testing automatique des templates
- [ ] Système de réputation des contacts
- [ ] Intégration Discord webhook
- [ ] Mode campagne de recrutement
- [ ] Suggestions de joueurs basées sur l'activité

---

## 👤 Auteur

**Plume** - Développeur passionné de WoW
[Discord](https://discord.gg/7FbBTkrH) | Retail EU

---

## 📜 Licence

Tous droits réservés © 2025 Plume

---

## 🙏 Remerciements

Merci à tous les utilisateurs qui testent et donnent du feedback !
Merci à la communauté Ace3 pour les excellentes librairies.

---

## 📝 Changelog v3.0.0

### Ajouts Majeurs
- ✨ Système d'auto-recrutement intelligent
- 🎨 6 thèmes visuels + éditeur personnalisé
- 📊 Statistiques et analytics avancées
- 🔔 Notifications toast élégantes
- 🎯 Filtres avancés avec presets
- 💾 Import/export & backup automatique
- ⌨️ Raccourcis clavier globaux
- 🏷️ Système de tags pour contacts

### Améliorations
- ⚡ Performances optimisées (smooth scrolling, debouncing)
- 🎭 Animations fluides (fade, slide, bounce, scale)
- 🖱️ Transitions entre tabs
- 💫 Badges pulsants
- 🎨 Interface modernisée
- 📈 Tracking de conversion
- 🔄 UI refresh optimisé

### Corrections
- 🐛 Corrections diverses de stabilité
- 🔧 Amélioration gestion mémoire
- 🛡️ Renforcement anti-spam

---

**CelestialRecruiter v3.0.0 - L'addon qui transforme votre guilde ! 🌟**
