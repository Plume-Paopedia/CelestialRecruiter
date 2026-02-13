local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Help (Aide) Tab  —  v3.4.0
-- Comprehensive tutorial & guide covering ALL features
-- ═══════════════════════════════════════════════════════════════════

local hd = {}

local SECTIONS = {
    -- =====================================================================
    -- 1. BIENVENUE
    -- =====================================================================
    {
        title = "Bienvenue sur CelestialRecruiter",
        text =
            "|cff00aaffCelestialRecruiter|r est l'assistant de recrutement de guilde le plus complet " ..
            "disponible sur World of Warcraft. Il te permet de scanner les joueurs en ligne, de gerer " ..
            "une file d'attente intelligente, d'envoyer des messages personnalises, de lancer des " ..
            "invitations de guilde, et bien plus encore.\n\n" ..
            "Depuis la |cffFFD700version 3.0|r, l'addon integre des fonctionnalites avancees : " ..
            "|cff9370DBtests A/B|r de templates, |cffFFD700campagnes de recrutement|r, " ..
            "|cff33e07ascore de reputation|r intelligent, |cff00aaffauto-recrutement|r, " ..
            "|cffFFD700succes et series|r, |cff9370DBsuggestions intelligentes|r et un " ..
            "tableau |cff00aaffAnalytics|r complet.\n\n" ..
            "L'addon respecte les limites anti-spam de Blizzard grace a un systeme de cooldowns " ..
            "integre. Tu peux recruter efficacement sans risquer de sanction.\n\n" ..
            "|cff888888Ce guide couvre toutes les fonctionnalites de la v3.4.0. " ..
            "Prends le temps de le lire pour exploiter tout le potentiel de l'addon.|r",
    },
    -- =====================================================================
    -- 2. DEMARRAGE RAPIDE
    -- =====================================================================
    {
        title = "Demarrage rapide (5 minutes)",
        text =
            "Pas envie de tout lire ? Voici comment commencer en 5 minutes :\n\n" ..
            "|cffFFD700Etape 1|r - Tape |cff00aaff/cr|r dans le chat pour ouvrir l'interface.\n\n" ..
            "|cffFFD700Etape 2|r - Va dans l'onglet |cffFFD700Reglages|r et remplis les informations " ..
            "de ta guilde :\n" ..
            "  - |cff00aaffNom de guilde|r (rempli automatiquement si tu es en guilde)\n" ..
            "  - |cff00aaffDiscord|r (ton lien d'invitation)\n" ..
            "  - |cff00aaffJours de raid|r (ex: \"Mercredi / Dimanche 21h\")\n" ..
            "  - |cff00aaffObjectif|r (ex: \"Progression Mythique\", \"Ambiance chill\")\n\n" ..
            "|cffFFD700Etape 3|r - Va dans l'onglet |cff00aaffScanner|r et clique sur " ..
            "|cff00aaffScanner|r. L'addon lance automatiquement des requetes /who par tranches " ..
            "de niveaux pour trouver des joueurs sans guilde.\n\n" ..
            "|cffFFD700Etape 4|r - Va dans l'onglet |cff00aaffFile d'attente|r. Les joueurs sans " ..
            "guilde trouves par le scanner y apparaissent automatiquement. Clique sur " ..
            "|cff33e07aRecruiter|r a cote d'un joueur pour lui envoyer un message + une invitation.\n\n" ..
            "|cffFFD700Etape 5|r - C'est tout ! Repete les etapes 3 et 4 regulierement. " ..
            "Les joueurs qui repondent apparaitront dans ta |cffFFD700Boite de reception|r.\n\n" ..
            "|cff888888Astuce : Lis les sections suivantes pour decouvrir les fonctionnalites " ..
            "avancees comme l'auto-recrutement, les campagnes et les tests A/B.|r",
    },
    -- =====================================================================
    -- 3. LE SCANNER
    -- =====================================================================
    {
        title = "Le Scanner - Trouver des joueurs",
        text =
            "Le scanner est l'outil principal pour trouver des joueurs a recruter. " ..
            "Il utilise la commande |cff00aaff/who|r de WoW pour chercher des joueurs en ligne.\n\n" ..

            "|cffFFD700Comment ca marche :|r\n" ..
            "L'addon envoie automatiquement plusieurs requetes /who par tranches de niveaux " ..
            "(par exemple 10-19, 20-29, 30-39, etc.) pour couvrir un maximum de joueurs. " ..
            "WoW limite chaque requete /who a ~50 resultats, donc le decoupage en tranches " ..
            "permet de scanner beaucoup plus de monde.\n\n" ..

            "|cffFFD700Les boutons :|r\n" ..
            "  |cff00aaffScanner|r - Lance le scan. Appuie a nouveau apres chaque cooldown pour " ..
            "envoyer la requete suivante. Le bouton affiche le temps restant avant la prochaine requete.\n" ..
            "  |cffff6b6bStop|r - Arrete le scan en cours.\n" ..
            "  |cff888888Import /who|r - Si tu as fait un /who manuellement dans le chat, ce bouton " ..
            "importe les resultats dans l'addon.\n" ..
            "  |cff888888Vider|r - Efface tous les resultats du scanner.\n\n" ..

            "|cffFFD700Les filtres :|r\n" ..
            "La barre de filtres te permet d'affiner les resultats :\n" ..
            "  - |cff00aaffFiltre classe|r : Affiche uniquement une classe specifique (Guerrier, Mage, etc.).\n" ..
            "  - |cff00aaffFiltre royaume|r : Tous / Local seulement / Cross-realm.\n" ..
            "  - |cff00aaffNiv min/max|r : Filtre par plage de niveaux. Tape le niveau et appuie Entree.\n" ..
            "  - |cff00aaffTri|r : Trie les resultats par Niveau, Classe, Zone ou Nom.\n" ..
            "  - |cff00aaffMasquer traites|r : Cache les joueurs deja en file d'attente ou deja contactes/invites.\n\n" ..

            "|cffFFD700Comprendre les lignes :|r\n" ..
            "  - La barre de couleur a gauche correspond a la |cff00aaffcouleur de classe|r du joueur.\n" ..
            "  - |cffffb347XR|r = Joueur cross-realm (serveur connecte) / |cff888888L|r = Joueur local.\n" ..
            "  - Le nom est colore par classe, suivi du niveau, de la classe et de la zone.\n" ..
            "  - |cff33e07aen liste|r = Le joueur est deja dans ta file d'attente.\n" ..
            "  - |cff00aaff+ Liste|r ajoute le joueur a ta file / |cff33e07aInviter|r envoie une invitation directement.\n\n" ..

            "|cffff6b6bLimitation cross-realm :|r La commande /who ne peut scanner que ton serveur " ..
            "et les serveurs connectes au tien (le cluster). Les joueurs \"XR\" sont ceux des " ..
            "royaumes connectes a ton cluster.\n\n" ..

            "|cffFFD700Options avancees du scanner (dans Reglages) :|r\n" ..
            "  - |cff00aaffNiveau min/max|r : Plage de niveaux a scanner (defaut: 10-80).\n" ..
            "  - |cff00aaffTranche niveaux|r : Taille de chaque sous-requete (defaut: 10).\n" ..
            "  - |cff00aaffDelai WHO|r (6s) : Pause entre chaque requete /who.\n" ..
            "  - |cff00aaffTimeout WHO|r (8s) : Temps max d'attente pour une reponse serveur.\n" ..
            "  - |cff00aaffInclure joueurs guildes|r : Affiche aussi les joueurs deja en guilde.\n" ..
            "  - |cff00aaffInclure cross-realm|r : Inclut les serveurs connectes.\n" ..
            "  - |cff00aaffFiltre classes|r : Ajoute des sous-requetes par classe pour plus de resultats.",
    },
    -- =====================================================================
    -- 4. LA FILE D'ATTENTE
    -- =====================================================================
    {
        title = "La File d'attente - Contacter les joueurs",
        text =
            "La file d'attente regroupe tous les joueurs que tu veux contacter. " ..
            "Les joueurs sans guilde trouves par le scanner y sont ajoutes automatiquement.\n\n" ..

            "|cffFFD700Score de reputation|r |cff9370DB(NOUVEAU v3.2)|r\n" ..
            "Chaque joueur dans la file possede un |cff33e07ascore de reputation|r (0-100) calcule " ..
            "automatiquement. Ce score t'aide a prioriser les contacts les plus prometteurs. " ..
            "Survole un joueur pour voir le detail du score dans le tooltip.\n\n" ..

            "|cffFFD700Choisir un modele :|r\n" ..
            "En haut de l'onglet, un menu deroulant |cffFFD700Modele|r te permet de selectionner " ..
            "quel message sera envoye (Par defaut, Raid, Court, ou tes modeles personnalises). " ..
            "L'apercu du message s'affiche en bas quand tu survoles un joueur.\n\n" ..

            "|cffFFD700Trier la file :|r\n" ..
            "Tu peux trier les joueurs par :\n" ..
            "  - |cff00aaffScore|r (reputation, du plus haut au plus bas)\n" ..
            "  - |cff00aaffNom|r (alphabetique)\n" ..
            "  - |cff00aaffNiveau|r (croissant ou decroissant)\n" ..
            "  - |cff00aaffClasse|r (groupe par classe)\n\n" ..

            "|cffFFD700Les boutons par joueur :|r\n" ..
            "  |cff33e07aRecruiter|r - Envoie message + invitation de guilde.\n" ..
            "  |cff00aaffMessage|r - Envoie uniquement un whisper avec le modele selectionne.\n" ..
            "  |cff33e07aInviter|r - Envoie uniquement une invitation de guilde.\n" ..
            "  |cffff6b6bRetirer|r - Retire le joueur de la file.\n\n" ..

            "|cffFFD700Action groupee :|r\n" ..
            "Le bouton |cffFFD700Recruter tout|r en haut de l'onglet lance le recrutement automatique " ..
            "de tous les joueurs visibles dans la file, en respectant les cooldowns anti-spam.\n\n" ..

            "|cffFFD700Indicateurs de statut (points colores) :|r\n" ..
            "  - |cff00aaffBleu|r = Nouveau (pas encore contacte)\n" ..
            "  - |cffffb347Orange|r = Contacte (message envoye)\n" ..
            "  - |cff33e07aVert|r = Invite (invitation guilde envoyee)\n" ..
            "  - |cffFFD700Or|r = Rejoint (a rejoint la guilde !)\n" ..
            "  - |cff888888Gris|r = Ignore\n\n" ..

            "|cff888888Astuce : Trie par score de reputation pour contacter en priorite " ..
            "les joueurs les plus susceptibles de rejoindre ta guilde.|r",
    },
    -- =====================================================================
    -- 5. LA BOITE DE RECEPTION
    -- =====================================================================
    {
        title = "La Boite de reception - Reponses des joueurs",
        text =
            "La boite de reception affiche les joueurs qui t'ont envoye un whisper contenant " ..
            "un de tes mots-cles configures, ou qui ont repondu a tes messages.\n\n" ..

            "|cffFFD700Indicateurs de contact chaud|r |cff9370DB(NOUVEAU)|r\n" ..
            "Un indicateur visuel signale les contacts \"chauds\" : ceux avec un score de " ..
            "reputation eleve (>= 70) ou qui ont opt-in recemment. Ces contacts sont prioritaires " ..
            "car ils sont les plus susceptibles de rejoindre ta guilde.\n\n" ..

            "|cffFFD700Systeme de reponse rapide|r |cff9370DB(NOUVEAU)|r\n" ..
            "Tu peux repondre directement depuis la boite de reception sans avoir a ouvrir " ..
            "le chat. Clique sur le bouton de reponse rapide a cote du joueur.\n\n" ..

            "|cffFFD700Le systeme d'opt-in :|r\n" ..
            "Quand un joueur repond a ton message avec le |cff00aaffmot cle d'invite|r " ..
            "(par defaut |cff00aaff!invite|r), il est automatiquement marque comme " ..
            "|cff33e07aopt-in|r. Tu peux alors l'inviter directement.\n\n" ..

            "|cffFFD700Trier la boite :|r\n" ..
            "  - |cff00aaffRecence|r : Messages les plus recents en haut\n" ..
            "  - |cff00aaffScore|r : Par score de reputation\n" ..
            "  - |cff00aaffContacts chauds|r : Les leads chauds en priorite\n\n" ..

            "|cffFFD700Les boutons :|r\n" ..
            "  |cff00aaff+ Liste|r - Ajoute le joueur a la file d'attente.\n" ..
            "  |cff33e07aInviter|r - Envoie une invitation de guilde directe.\n" ..
            "  |cff888888Ignorer 7j|r - Ignore le joueur pendant 7 jours.\n" ..
            "  |cffff6b6bBlacklist|r - Bloque definitivement le joueur.\n\n" ..

            "|cff888888Astuce : Reponds rapidement aux joueurs opt-in. " ..
            "Plus tu es reactif, plus tes chances de conversion sont elevees.|r",
    },
    -- =====================================================================
    -- 6. LES TEMPLATES
    -- =====================================================================
    {
        title = "Les Templates - Messages d'invitation",
        text =
            "L'addon propose 3 modeles de messages que tu peux personnaliser dans " ..
            "|cffFFD700Reglages > Messages d'invitation|r.\n\n" ..

            "|cffFFD700Les modeles :|r\n" ..
            "  |cff00aaffPar defaut|r - Message general de recrutement.\n" ..
            "  |cff00aaffRaid|r - Message oriente raid / progression.\n" ..
            "  |cff00aaffCourt|r - Message court et direct.\n\n" ..

            "|cffFFD700Variables disponibles :|r\n" ..
            "Les variables sont remplacees automatiquement quand le message est envoye :\n" ..
            "  |cff00aaff{name}|r - Le nom du joueur cible (ex: \"Arthas\").\n" ..
            "  |cff00aaff{guild}|r - Le nom de ta guilde.\n" ..
            "  |cff00aaff{discord}|r - Ton lien Discord.\n" ..
            "  |cff00aaff{raidDays}|r - Tes jours de raid.\n" ..
            "  |cff00aaff{goal}|r - L'objectif de ta guilde.\n" ..
            "  |cff00aaff{inviteKeyword}|r - Le mot cle pour opt-in.\n\n" ..

            "|cffFFD700Exemple de message :|r\n" ..
            "|cff888888\"Salut {name}, la guilde {guild} recrute ! {goal}. Discord: {discord} :)\"|r\n" ..
            "Deviendra :\n" ..
            "|cff888888\"Salut Arthas, la guilde Celestial Sentinels recrute ! Ambiance chill et " ..
            "progression stable. Discord: https://discord.gg/7FbBTkrH :)\"|r\n\n" ..

            "|cffff6b6bImportant :|r Les messages sont coupes a |cffFFD700255 caracteres|r " ..
            "(limite WoW whisper). Verifie que tes messages ne sont pas trop longs !\n" ..
            "Clique |cff888888Reset|r a cote d'un modele pour revenir au texte par defaut.\n\n" ..

            "|cff888888Astuce : Teste differents messages avec le systeme de tests A/B " ..
            "(voir section dediee) pour trouver celui qui convertit le mieux.|r",
    },
    -- =====================================================================
    -- 7. L'ANTI-SPAM
    -- =====================================================================
    {
        title = "L'Anti-spam - Eviter les sanctions",
        text =
            "CelestialRecruiter integre un systeme anti-spam robuste pour proteger ton compte " ..
            "contre les sanctions Blizzard. |cffff6b6bNe desactive jamais ces protections.|r\n\n" ..

            "|cffFFD700Les limites (dans Reglages) :|r\n" ..
            "  |cff00aaffCooldown invitation|r (defaut: 300s) - Delai minimum entre deux invitations " ..
            "au meme joueur.\n" ..
            "  |cff00aaffCooldown message|r (defaut: 180s) - Delai minimum entre deux whispers " ..
            "au meme joueur.\n" ..
            "  |cff00aaffMax actions/min|r (defaut: 8) - Nombre maximum d'actions par minute.\n" ..
            "  |cff00aaffMax invites/h|r (defaut: 10) - Nombre maximum d'invitations par heure.\n" ..
            "  |cff00aaffMax messages/h|r (defaut: 20) - Nombre maximum de whispers par heure.\n\n" ..

            "|cffFFD700Protections automatiques :|r\n" ..
            "  |cff00aaffRespecter AFK|r - Ne contacte pas les joueurs AFK.\n" ..
            "  |cff00aaffRespecter DND|r - Ne contacte pas les joueurs en mode Ne Pas Deranger.\n" ..
            "  |cff00aaffPause AFK/DND|r (defaut: 900s) - Temps d'attente si joueur AFK/DND.\n" ..
            "  |cff00aaffPas en instance|r - Bloque les actions si tu es en donjon/raid.\n\n" ..

            "|cff888888Les valeurs par defaut sont volontairement conservatrices. " ..
            "Tu peux les ajuster, mais ne descends pas en dessous de la moitie des valeurs " ..
            "par defaut pour eviter tout risque.|r",
    },
    -- =====================================================================
    -- 8. L'AUTO-RECRUTEMENT
    -- =====================================================================
    {
        title = "L'Auto-recrutement - Recruter automatiquement",
        text =
            "L'auto-recrutement |cff9370DB(NOUVEAU v3.0)|r permet a l'addon de contacter " ..
            "automatiquement les joueurs de ta file d'attente, un par un, en respectant " ..
            "tous les cooldowns anti-spam.\n\n" ..

            "|cffFFD700Comment configurer :|r\n" ..
            "Dans |cffFFD700Reglages > Auto-recrutement|r, tu peux regler :\n" ..
            "  - |cff00aaffMode|r : |cff888888whisper|r (message seul), |cff888888invite|r " ..
            "(invitation seule), ou |cff888888recruit|r (les deux).\n" ..
            "  - |cff00aaffDelai entre actions|r (defaut: 15s) : Temps d'attente entre chaque joueur.\n" ..
            "  - |cff00aaffMax par session|r (defaut: 50) : Nombre max de joueurs traites par session.\n" ..
            "  - |cff00aaffModele|r : Le template a utiliser pour les messages.\n\n" ..

            "|cffFFD700Restrictions horaires :|r\n" ..
            "Tu peux limiter l'auto-recrutement a certaines heures :\n" ..
            "  - |cff00aaffHeure debut|r / |cff00aaffHeure fin|r (ex: 18h a 23h)\n" ..
            "  - L'addon se met en pause automatiquement hors des horaires autorises.\n" ..
            "  - Support des plages qui traversent minuit (ex: 22h a 2h).\n\n" ..

            "|cffFFD700Limites quotidiennes :|r\n" ..
            "  - |cff00aaffMax contacts/jour|r (defaut: 100)\n" ..
            "  - |cff00aaffMax invites/jour|r (defaut: 50)\n" ..
            "  - L'auto-recrutement s'arrete automatiquement quand les limites sont atteintes.\n\n" ..

            "|cffFFD700Classes prioritaires :|r\n" ..
            "Tu peux definir des classes prioritaires qui seront traitees en premier " ..
            "(utile si tu cherches un tank ou un healer en priorite).\n\n" ..

            "|cffFFD700Conditions de saut :|r\n" ..
            "  - Sauter les joueurs deja guildes\n" ..
            "  - Sauter les joueurs deja contactes\n" ..
            "  - Sauter les joueurs deja invites\n" ..
            "  - Exclure les cross-realm\n" ..
            "  - Exiger l'opt-in avant de contacter\n\n" ..

            "|cffff6b6bSecurite :|r L'auto-recrutement s'arrete automatiquement si la file " ..
            "est vide, si les limites quotidiennes/session sont atteintes, ou si tu es hors " ..
            "des horaires autorises. Tu peux l'arreter manuellement a tout moment.\n\n" ..

            "|cff888888Astuce : Commence avec un delai de 15-20s et un max de 30 par session. " ..
            "Augmente progressivement si tout se passe bien.|r",
    },
    -- =====================================================================
    -- 9. LE A/B TESTING
    -- =====================================================================
    {
        title = "Le A/B Testing - Optimiser tes messages",
        text =
            "Le systeme de tests A/B |cff9370DB(NOUVEAU v3.1)|r te permet de comparer " ..
            "automatiquement deux (ou plus) templates de messages pour determiner lequel " ..
            "est le plus efficace.\n\n" ..

            "|cffFFD700Comment ca marche :|r\n\n" ..

            "|cffFFD700Etape 1|r - Va dans |cffFFD700Reglages > Tests A/B|r et cree un nouveau test.\n" ..
            "  Donne un nom au test (ex: \"Court vs Raid\").\n\n" ..

            "|cffFFD700Etape 2|r - Choisis 2 templates a comparer.\n" ..
            "  Par exemple, le template |cff00aaffPar defaut|r contre le template |cff00aaffCourt|r.\n\n" ..

            "|cffFFD700Etape 3|r - Demarre le test.\n" ..
            "  A partir de maintenant, chaque fois que tu envoies un message, l'addon choisit " ..
            "automatiquement l'un des deux templates grace a un algorithme inspire du " ..
            "|cff9370DBThompson Sampling|r.\n\n" ..

            "|cffFFD700L'algorithme Thompson Sampling :|r\n" ..
            "  - Au debut, les deux templates sont envoyes a frequence egale.\n" ..
            "  - Au fur et a mesure des resultats (reponses, joueurs qui rejoignent), l'addon " ..
            "favorise progressivement le template le plus performant.\n" ..
            "  - Plus il y a de donnees, plus le choix est precis.\n" ..
            "  - Chaque variante accumule un |cff00aaffpoids|r base sur son taux de reussite.\n\n" ..

            "|cffFFD700Etape 4|r - Consulte les resultats dans l'onglet |cffFFD700Analytics|r.\n" ..
            "  Tu y verras pour chaque variante : nombre d'envois, reponses, joueurs recrutes, " ..
            "et un score de performance.\n\n" ..

            "|cffFFD700Completion automatique :|r\n" ..
            "Le test se termine automatiquement quand chaque variante a atteint le nombre " ..
            "minimum d'echantillons (defaut: 30) et qu'un gagnant clair se degage " ..
            "(seuil de confiance >= 95%).\n\n" ..

            "|cff888888Astuce : Lance un test A/B chaque fois que tu crees un nouveau template. " ..
            "Compare-le a ton meilleur template actuel pour verifier qu'il fait mieux.|r",
    },
    -- =====================================================================
    -- 10. LES CAMPAGNES
    -- =====================================================================
    {
        title = "Les Campagnes - Recrutement organise",
        text =
            "Le systeme de campagnes |cff9370DB(NOUVEAU v3.1)|r te permet de creer des campagnes " ..
            "de recrutement structurees avec des objectifs mesurables.\n\n" ..

            "|cffFFD700Creer une campagne :|r\n" ..
            "Dans les reglages ou via le panneau Analytics, cree une campagne avec :\n" ..
            "  - |cff00aaffNom|r : Un nom descriptif (ex: \"Recrutement healer Avril\")\n" ..
            "  - |cff00aaffDescription|r : Le contexte de la campagne\n" ..
            "  - |cff00aaffTemplate|r : Le modele de message a utiliser\n" ..
            "  - |cff00aaffFiltres|r : Niveau min/max, classes, zones, cross-realm\n\n" ..

            "|cffFFD700Definir des objectifs :|r\n" ..
            "  - |cffFFD700Contactes|r : Nombre de joueurs a contacter (defaut: 50)\n" ..
            "  - |cffFFD700Invites|r : Nombre d'invitations a envoyer (defaut: 20)\n" ..
            "  - |cffFFD700Recrues|r : Nombre de joueurs a recruter (defaut: 5)\n" ..
            "  La campagne se complete automatiquement quand tous les objectifs sont atteints.\n\n" ..

            "|cffFFD700Suivre la progression :|r\n" ..
            "  - Nombre de contacts traites, invites envoyes, recrues obtenues, reponses recues\n" ..
            "  - Barre de progression vers chaque objectif\n" ..
            "  - Duree depuis le lancement\n" ..
            "  - Vue d'ensemble dans l'onglet Analytics\n\n" ..

            "|cffFFD700Etats d'une campagne :|r\n" ..
            "  - |cff888888Brouillon|r : En preparation, pas encore lancee\n" ..
            "  - |cff33e07aActive|r : En cours de recrutement\n" ..
            "  - |cffffb347En pause|r : Temporairement arretee\n" ..
            "  - |cffFFD700Terminee|r : Tous les objectifs sont atteints !\n" ..
            "  - |cff888888Archivee|r : Gardee pour reference historique\n\n" ..

            "|cffFFD700Planification :|r\n" ..
            "Tu peux planifier une campagne pour fonctionner uniquement certains jours " ..
            "et certaines heures (ex: du lundi au vendredi, de 18h a 23h).\n\n" ..

            "|cff888888Astuce : Duplique une campagne reussie pour en creer une nouvelle " ..
            "avec les memes parametres. Utilise des campagnes thematiques " ..
            "(\"Recrutement tank\", \"Recrutement raid\") pour mieux cibler.|r",
    },
    -- =====================================================================
    -- 11. LE SCORE DE REPUTATION
    -- =====================================================================
    {
        title = "Le Score de Reputation - Prioriser les contacts",
        text =
            "Le systeme de reputation |cff9370DB(NOUVEAU v3.2)|r attribue un score de 0 a 100 " ..
            "a chaque contact pour t'aider a prioriser tes efforts de recrutement.\n\n" ..

            "|cffFFD700Comment le score est calcule :|r\n" ..
            "  Score de base : |cff00aaff50 points|r\n\n" ..
            "  |cff33e07aBonus positifs :|r\n" ..
            "  - Opt-in (a repondu avec le mot cle) : |cff33e07a+30|r\n" ..
            "  - A repondu a ton message : |cff33e07a+25|r\n" ..
            "  - Vu aujourd'hui : |cff33e07a+20|r / Cette semaine : |cff33e07a+10|r / Ce mois : |cff33e07a+5|r\n" ..
            "  - Source = boite de reception (il t'a contacte) : |cff33e07a+20|r\n" ..
            "  - Niveau 70+ : |cff33e07a+15|r / Niveau 60+ : |cff33e07a+10|r / Niveau 40+ : |cff33e07a+5|r\n" ..
            "  - Tags : hot/priority : |cff33e07a+15|r / tank/heal : |cff33e07a+10|r / friend : |cff33e07a+20|r\n" ..
            "  - Statut \"joined\" : |cff33e07a+100|r\n\n" ..

            "  |cffff6b6bMalus negatifs :|r\n" ..
            "  - Cross-realm : |cffff6b6b-10|r\n" ..
            "  - Deja contacte : |cffff6b6b-5|r\n" ..
            "  - Deja invite (n'a pas rejoint) : |cffff6b6b-15|r\n" ..
            "  - Ignore : |cffff6b6b-50|r\n" ..
            "  - Pas vu depuis 30+ jours : |cffff6b6b-10|r\n" ..
            "  - Niveau < 20 : |cffff6b6b-5|r\n" ..
            "  - Tags : spam/bot : |cffff6b6b-30|r\n\n" ..

            "|cffFFD700Classifications :|r\n" ..
            "  |cffff6600Score 80+|r : Hot Lead - Contact tres prometteur, a traiter en priorite !\n" ..
            "  |cff33e07aScore 60-79|r : Promising - Bon potentiel, a contacter rapidement.\n" ..
            "  |cff888888Score 40-59|r : Neutral - Contact standard, pas de signal fort.\n" ..
            "  |cff6699ffScore 20-39|r : Cold - Peu de chances de conversion.\n" ..
            "  |cffff6b6bScore 0-19|r : Ignore - Ne vaut probablement pas l'effort.\n\n" ..

            "|cffFFD700Auto-tagging :|r\n" ..
            "L'addon peut automatiquement ajouter des tags (hot, promising, cold) " ..
            "en fonction du score de reputation.\n\n" ..

            "|cff888888Astuce : Concentre tes efforts sur les contacts \"Hot Lead\" et \"Promising\". " ..
            "Utilise le tri par score dans la file d'attente pour les voir en premier.|r",
    },
    -- =====================================================================
    -- 12. LES SUCCES
    -- =====================================================================
    {
        title = "Les Succes - Gamification du recrutement",
        text =
            "Le systeme de succes |cff9370DB(NOUVEAU v3.0)|r gamifie ton experience de recrutement " ..
            "avec 25 succes repartis en 4 categories.\n\n" ..

            "|cffFFD700Categories :|r\n\n" ..

            "  |cff00aaff--- Recrutement ---|r\n" ..
            "  - Premiere prise de contact (1 message envoye)\n" ..
            "  - Recruteur debutant (10 contacts)\n" ..
            "  - Recruteur confirme (50 contacts)\n" ..
            "  - Recruteur expert (100 contacts)\n" ..
            "  - Maitre recruteur (500 contacts)\n" ..
            "  - Legende vivante (1000 contacts !)\n" ..
            "  - Premiere recrue (1 joueur rejoint)\n" ..
            "  - Chasseur de talents (10 recrues)\n" ..
            "  - Legende du recrutement (50 recrues)\n" ..
            "  - Batisseur de guilde (50+ recrues)\n\n" ..

            "  |cff33e07a--- Social ---|r\n" ..
            "  - Papillon social (10 reponses recues)\n" ..
            "  - Brise-glace (25 reponses recues)\n" ..
            "  - Arc-en-ciel (recruter une de chaque classe)\n" ..
            "  - Roi de la conversion (>30% de conversion sur 20+ contacts)\n\n" ..

            "  |cffFFD700--- Dedication ---|r\n" ..
            "  - Regulier (3 jours d'affilee)\n" ..
            "  - Dedicace (7 jours d'affilee)\n" ..
            "  - Infatigable (14 jours d'affilee)\n" ..
            "  - Inarretable (30 jours d'affilee !)\n" ..
            "  - Fidele (7 jours de connexion consecutifs)\n" ..
            "  - Explorateur assidu (50 scans)\n\n" ..

            "  |cff9370DB--- Maitrise ---|r\n" ..
            "  - Hibou nocturne (recruter entre 23h et 5h)\n" ..
            "  - Leve-tot (recruter entre 5h et 8h)\n" ..
            "  - Speed demon (10 contacts en 1 heure)\n" ..
            "  - Maitre des templates (utiliser les 3 templates)\n" ..
            "  - Perfectionniste (100% de conversion sur 5+ contacts en 1 jour)\n\n" ..

            "|cffFFD700Series (Streaks) :|r\n" ..
            "  - |cff00aaffSerie de connexion|r : Jours consecutifs de connexion\n" ..
            "  - |cff00aaffSerie de recrutement|r : Jours consecutifs de recrutement\n" ..
            "  - |cff00aaffObjectif hebdomadaire|r : Semaines consecutives d'activite\n" ..
            "  Chaque serie enregistre ta meilleure performance.\n\n" ..

            "|cff888888Astuce : Les succes sont verifies automatiquement. " ..
            "Une notification apparait quand tu en debloques un.|r",
    },
    -- =====================================================================
    -- 13. LES SUGGESTIONS INTELLIGENTES
    -- =====================================================================
    {
        title = "Les Suggestions Intelligentes",
        text =
            "Le moteur de suggestions |cff9370DB(NOUVEAU v3.2)|r analyse tes donnees de " ..
            "recrutement et te propose des actions concretes pour ameliorer tes resultats.\n\n" ..

            "|cffFFD700Types de suggestions :|r\n\n" ..

            "|cff00aaffMeilleure heure pour recruter|r\n" ..
            "  L'addon analyse tes statistiques horaires et te dit quand recruter pour " ..
            "maximiser tes chances. Si c'est le bon moment, il te le signale !\n\n" ..

            "|cff00aaffMeilleur template a utiliser|r\n" ..
            "  Base sur les performances de tes templates (taux de reponse, taux de " ..
            "conversion), l'addon recommande le template le plus efficace.\n\n" ..

            "|cff00aaffContacts a recontacter|r\n" ..
            "  L'addon identifie les contacts qui ont ete contactes il y a plus de 3 jours " ..
            "et qui ont un score de reputation > 40. Un rappel pourrait les convertir.\n" ..
            "  Les 10 meilleurs prospects sont affiches, tries par score.\n\n" ..

            "|cff00aaffLeads chauds prioritaires|r\n" ..
            "  Les contacts dans ta file avec un score >= 70 qui n'ont pas encore ete " ..
            "contactes. Ce sont tes meilleures opportunites !\n\n" ..

            "|cff00aaffClasses sous-representees|r\n" ..
            "  L'addon compare la distribution de classes de tes recrues par rapport " ..
            "a une distribution ideale et signale les classes manquantes.\n\n" ..

            "|cff00aaffBilan hebdomadaire|r\n" ..
            "  Un resume des tendances de la semaine : evolution des contacts, invites, " ..
            "recrues par rapport a la semaine precedente.\n\n" ..

            "|cffFFD700Priorite des suggestions :|r\n" ..
            "  Les suggestions sont classees par priorite (5 = urgent, 1 = informatif). " ..
            "Les leads chauds et les prospects a recontacter sont toujours en haut.\n\n" ..

            "|cff888888Astuce : Consulte les suggestions regulierement dans le panneau Analytics. " ..
            "Elles s'adaptent automatiquement a tes donnees.|r",
    },
    -- =====================================================================
    -- 14. L'ANALYTICS
    -- =====================================================================
    {
        title = "L'Analytics - Tableau de bord",
        text =
            "L'onglet Analytics |cff9370DB(NOUVEAU v3.0)|r offre un tableau de bord complet " ..
            "pour visualiser tes performances de recrutement.\n\n" ..

            "|cffFFD700Cartes de resume :|r\n" ..
            "  4 cartes en haut de l'ecran affichent les chiffres cles :\n" ..
            "  - |cff00aaffContactes|r : Nombre total de joueurs contactes\n" ..
            "  - |cff33e07aInvites|r : Nombre d'invitations envoyees\n" ..
            "  - |cffFFD700Recrues|r : Nombre de joueurs qui ont rejoint ta guilde\n" ..
            "  - |cffFF69B4Conversion|r : Taux de conversion (recrues / contactes)\n\n" ..

            "|cffFFD700Funnel de conversion :|r\n" ..
            "  Un graphique en barres horizontales qui montre le pipeline :\n" ..
            "  Contactes -> Invites -> Rejoints\n" ..
            "  Permet de voir a quelle etape tu perds le plus de joueurs.\n\n" ..

            "|cffFFD700Meilleurs horaires (heatmap) :|r\n" ..
            "  Un graphique a barres verticales (0h a 23h) montrant l'activite " ..
            "de recrutement par heure. Les barres plus hautes = plus d'activite. " ..
            "Survole une barre pour voir le detail.\n\n" ..

            "|cffFFD700Distribution par classe :|r\n" ..
            "  Barres horizontales colorees par classe montrant la repartition " ..
            "de tes contacts/recrues par classe WoW.\n\n" ..

            "|cffFFD700Performance des templates :|r\n" ..
            "  Compare les taux de succes de tes differents modeles de messages.\n\n" ..

            "|cffFFD700Tendances hebdomadaires :|r\n" ..
            "  3 cartes comparant cette semaine a la precedente pour les contactes, " ..
            "invites et recrues, avec le pourcentage d'evolution.\n\n" ..

            "|cffFFD700Widgets du tableau de bord :|r\n" ..
            "  Des widgets supplementaires affichent les suggestions intelligentes, " ..
            "la progression des succes et les campagnes actives.\n\n" ..

            "|cffFFD700Tests A/B :|r\n" ..
            "  Les resultats de ton test A/B actif ou le plus recent, avec pour " ..
            "chaque variante : envois, reponses, recrues, score et gagnant.\n\n" ..

            "|cffFFD700Campagnes :|r\n" ..
            "  Vue d'ensemble de tes campagnes avec leur statut, progression " ..
            "et statistiques (contactes, invites, recrues/objectif).\n\n" ..

            "|cff888888Astuce : Consulte l'Analytics apres chaque session de recrutement " ..
            "pour ajuster ta strategie. Le funnel de conversion est particulierement " ..
            "utile pour identifier les points de blocage.|r",
    },
    -- =====================================================================
    -- 15. GUIDE: COMMENT BIEN RECRUTER
    -- =====================================================================
    {
        title = "Guide : Comment bien recruter",
        text =
            "Ce guide rassemble les meilleures pratiques pour maximiser l'efficacite " ..
            "de ton recrutement avec CelestialRecruiter.\n\n" ..

            "|cffFFD700=== PREPARATION ===|r\n\n" ..

            "|cff00aaff1. Configure ta guilde correctement|r\n" ..
            "  Remplis TOUS les champs dans Reglages : nom de guilde, Discord, jours de raid, " ..
            "objectif. Ces informations sont utilisees dans tes messages et donnent confiance " ..
            "aux joueurs. Un lien Discord est |cffFFD700essentiel|r.\n\n" ..

            "|cff00aaff2. Cree des templates de qualite|r\n" ..
            "  Un bon message de recrutement est :\n" ..
            "  - |cff33e07aCourt|r (150-200 caracteres max, pas 255)\n" ..
            "  - |cff33e07aPersonnalise|r (utilise {name}, ca fait la difference)\n" ..
            "  - |cff33e07aAuthentique|r (mentionne ce qui rend ta guilde unique)\n" ..
            "  - |cff33e07aAvec un appel a l'action|r (Discord, !invite, etc.)\n" ..
            "  Evite les messages trop generiques comme \"recrute toutes classes tous niveaux\".\n\n" ..

            "|cffFFD700=== TIMING ===|r\n\n" ..

            "|cff00aaff3. Recrute aux bons moments|r\n" ..
            "  - |cffFFD700Heures de pointe|r : 18h-23h en semaine, 14h-23h le weekend\n" ..
            "  - |cffFFD700Mardi/Mercredi soir|r : Reset hebdomadaire = plus de joueurs connectes\n" ..
            "  - |cffFFD700Apres un patch/extension|r : Afflux de joueurs, moment ideal !\n" ..
            "  - Consulte la heatmap dans Analytics pour connaitre TES meilleures heures.\n\n" ..

            "|cffFFD700=== QUALITE DES MESSAGES ===|r\n\n" ..

            "|cff00aaff4. Sois personnel et humain|r\n" ..
            "  Evite les messages robots. Ajoute une touche personnelle :\n" ..
            "  - Mentionne la zone ou est le joueur si possible\n" ..
            "  - Adapte ton template selon la classe (\"On cherche un super tank !\")\n" ..
            "  - Sois amical, pas vendeur\n\n" ..

            "|cff00aaff5. Mentionne ce qui rend ta guilde unique|r\n" ..
            "  Ambiance, progression, events, Discord actif, joueurs sympas... " ..
            "Donne envie de rejoindre VOTRE guilde plutot qu'une autre.\n\n" ..

            "|cffFFD700=== SUIVI ===|r\n\n" ..

            "|cff00aaff6. Reponds rapidement aux replies|r\n" ..
            "  Quand un joueur repond a ton message ou opt-in, c'est LE moment. " ..
            "Plus tu es reactif, plus tes chances de conversion sont elevees. " ..
            "Utilise les indicateurs de contacts chauds dans la boite de reception.\n\n" ..

            "|cff00aaff7. Ne spamme jamais|r\n" ..
            "  - Laisse les cooldowns anti-spam faire leur travail\n" ..
            "  - Ne contacte pas le meme joueur plus d'une fois par semaine\n" ..
            "  - Un joueur agace fera un rapport = sanctions possibles\n\n" ..

            "|cff00aaff8. Invite immediatement les joueurs opt-in|r\n" ..
            "  Un joueur qui repond \"!invite\" est pret MAINTENANT. " ..
            "Chaque minute de retard reduit tes chances.\n\n" ..

            "|cffFFD700=== FONCTIONNALITES AVANCEES ===|r\n\n" ..

            "|cff00aaff9. Utilise les tests A/B|r\n" ..
            "  Cree un test A/B chaque fois que tu modifies un template. " ..
            "Compare l'ancien et le nouveau pour voir lequel performe mieux. " ..
            "Laisse l'algorithme collecter au moins 30 envois par variante.\n\n" ..

            "|cff00aaff10. Exploite les scores de reputation|r\n" ..
            "  Trie ta file par score. Concentre tes efforts sur les Hot Leads (80+) " ..
            "et les Promising (60-79). Les Cold (20-39) ne valent souvent pas le temps.\n\n" ..

            "|cff00aaff11. Configure l'auto-recrutement prudemment|r\n" ..
            "  - Commence avec un delai de 20s et un max de 20/session\n" ..
            "  - Active les restrictions horaires (18h-23h)\n" ..
            "  - Surveille tes premieres sessions auto pour verifier que tout va bien\n" ..
            "  - Augmente progressivement si pas de probleme\n\n" ..

            "|cff00aaff12. Lance des campagnes thematiques|r\n" ..
            "  Au lieu de recruter \"tout le monde\", cree des campagnes ciblees :\n" ..
            "  - \"Recrutement healers\" (filtre classe + template adapte)\n" ..
            "  - \"Recrutement hauts niveaux\" (filtre niv 70+)\n" ..
            "  - \"Weekend warriors\" (planifie le weekend uniquement)\n" ..
            "  Les campagnes permettent de mesurer precisement tes resultats.\n\n" ..

            "|cffFFD700=== ERREURS A EVITER ===|r\n\n" ..

            "  |cffff6b6b1.|r Envoyer le meme message a tout le monde sans personnaliser\n" ..
            "  |cffff6b6b2.|r Baisser les cooldowns anti-spam en dessous des valeurs par defaut\n" ..
            "  |cffff6b6b3.|r Ignorer les reponses des joueurs (ils se deconnectent vite !)\n" ..
            "  |cffff6b6b4.|r Recruter uniquement via invitation sans envoyer de message\n" ..
            "  |cffff6b6b5.|r Ne pas avoir de Discord ou un lien casse dans le message\n" ..
            "  |cffff6b6b6.|r Recruter en instance/donjon (bloque par l'anti-spam)\n" ..
            "  |cffff6b6b7.|r Lancer l'auto-recrutement a fond sans surveillance\n" ..
            "  |cffff6b6b8.|r Ne jamais consulter les Analytics (tu recrutes a l'aveugle)\n\n" ..

            "|cff888888Rappel : Le recrutement efficace est un marathon, pas un sprint. " ..
            "Sois constant, adapte tes messages, et les resultats viendront.|r",
    },
    -- =====================================================================
    -- 16. RACCOURCIS CLAVIER
    -- =====================================================================
    {
        title = "Raccourcis clavier",
        text =
            "CelestialRecruiter propose des raccourcis clavier configurables pour les " ..
            "actions les plus courantes. Configure-les dans " ..
            "|cffFFD700Options > Raccourcis > CelestialRecruiter|r dans le menu WoW.\n\n" ..

            "|cffFFD700Raccourcis disponibles :|r\n\n" ..
            "  |cff00aaffOuvrir/Fermer l'interface|r\n" ..
            "  Equivalent de |cff00aaff/cr|r. Ouvre ou ferme la fenetre principale.\n\n" ..

            "  |cff00aaffLancer un scan|r\n" ..
            "  Lance le scan suivant sans ouvrir l'interface.\n\n" ..

            "  |cff00aaffRecruiter suivant dans la file|r\n" ..
            "  Envoie message + invitation au premier joueur de la file.\n\n" ..

            "  |cff00aaffInviter suivant dans la file|r\n" ..
            "  Envoie une invitation guilde au premier joueur de la file.\n\n" ..

            "  |cff00aaffMessage suivant dans la file|r\n" ..
            "  Envoie un whisper au premier joueur de la file.\n\n" ..

            "  |cff00aaffDemarrer/Arreter auto-recrutement|r\n" ..
            "  Active ou desactive l'auto-recrutement.\n\n" ..

            "  |cff00aaffAller a l'onglet Scanner|r\n" ..
            "  Ouvre l'interface directement sur l'onglet Scanner.\n\n" ..

            "  |cff00aaffAller a l'onglet File d'attente|r\n" ..
            "  Ouvre l'interface directement sur l'onglet File.\n\n" ..

            "  |cff00aaffAller a l'onglet Boite|r\n" ..
            "  Ouvre l'interface directement sur la Boite de reception.\n\n" ..

            "  |cff00aaffAller a l'onglet Reglages|r\n" ..
            "  Ouvre l'interface directement sur les Reglages.\n\n" ..

            "|cff888888Astuce : Assigne au moins le raccourci \"Ouvrir/Fermer\" et " ..
            "\"Recruiter suivant\" pour un workflow rapide sans souris.|r",
    },
    -- =====================================================================
    -- 17. COMMANDES SLASH
    -- =====================================================================
    {
        title = "Commandes slash",
        text =
            "|cff00aaff/cr|r\n" ..
            "  Ouvre ou ferme l'interface CelestialRecruiter.\n\n" ..

            "|cff00aaff/cr reset|r\n" ..
            "  Remet |cffff6b6bTOUS|r les reglages et donnees a zero.\n" ..
            "  |cffff6b6bAttention : cette action est irreversible !|r Toutes tes donnees " ..
            "(contacts, statistiques, campagnes, succes, tests A/B) seront supprimees.\n\n" ..

            "|cff00aaff/cr help|r\n" ..
            "  Affiche un resume des commandes disponibles dans le chat.\n\n" ..

            "|cff888888Tu peux aussi fermer la fenetre avec la touche Echap. " ..
            "Le bouton minimap offre un acces rapide :\n" ..
            "  - Clic gauche = Ouvrir/Fermer\n" ..
            "  - Clic droit = Scan rapide\n" ..
            "  - Glisser-deposer = Repositionner|r",
    },
    -- =====================================================================
    -- 18. CREDITS
    -- =====================================================================
    {
        title = "Credits",
        text =
            "|cff00aaffCelestialRecruiter|r a ete cree avec amour par |cffFFD700plume.pao|r " ..
            "pour la guilde |cffFFD700Celestial Sentinels|r.\n\n" ..
            "Rejoins-nous sur Discord : |cff7289da https://discord.gg/7FbBTkrH|r\n\n" ..
            "Si tu as des suggestions, des bugs a signaler ou juste envie de dire merci, " ..
            "n'hesite pas a venir nous voir sur le Discord !\n\n" ..
            "|cffFFD700Fonctionnalites de la v3.x :|r\n" ..
            "  - Auto-recrutement intelligent avec regles et limites\n" ..
            "  - Systeme de tests A/B avec Thompson Sampling\n" ..
            "  - Campagnes de recrutement avec objectifs\n" ..
            "  - Score de reputation (0-100) pour prioriser\n" ..
            "  - 25 succes en 4 categories avec series\n" ..
            "  - Suggestions intelligentes basees sur les donnees\n" ..
            "  - Tableau de bord Analytics complet\n" ..
            "  - Raccourcis clavier configurables\n" ..
            "  - Systeme de themes visuels\n" ..
            "  - Systeme de notifications\n" ..
            "  - Animations et effets de particules\n\n" ..
            "|cff888888Version: 3.4.0  |  Interface: 11.1.x (The War Within)|r",
    },
}

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function ns.UI_BuildHelp(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", 8, -8)
    sf:SetPoint("BOTTOMRIGHT", -8, 8)
    local ch = CreateFrame("Frame", nil, sf)
    ch:SetWidth(1)
    sf:SetScrollChild(ch)

    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(s, d)
        local mx = math.max(0, ch:GetHeight() - s:GetHeight())
        s:SetVerticalScroll(math.max(0, math.min(mx, s:GetVerticalScroll() - d * 40)))
    end)
    sf:SetScript("OnSizeChanged", function(s)
        ch:SetWidth(s:GetWidth())
    end)

    hd.sf = sf
    hd.ch = ch
    hd.blocks = {}
end

---------------------------------------------------------------------------
-- Refresh (rebuild blocks on first show, then just update height)
---------------------------------------------------------------------------
function ns.UI_RefreshHelp()
    if not hd.ch then return end

    -- Build blocks lazily on first refresh (so parent has width)
    if #hd.blocks == 0 and hd.ch:GetWidth() > 10 then
        local y = 0
        for _, sec in ipairs(SECTIONS) do
            -- Section header
            local h = W.MakeHeader(hd.ch, sec.title)
            h:SetPoint("TOPLEFT", 4, -y)
            W.MakeSeparator(hd.ch, h)
            y = y + 24

            -- Content block
            local block = W.MakeInfoBlock(hd.ch, sec.text)
            block:SetPoint("TOPLEFT", hd.ch, "TOPLEFT", 4, -y)
            block:SetPoint("RIGHT", hd.ch, "RIGHT", -4, 0)
            block:UpdateHeight()
            y = y + block:GetHeight() + 14

            hd.blocks[#hd.blocks + 1] = block
        end
        hd.totalH = y + 10
    end

    -- Recalculate block heights on width changes
    if #hd.blocks > 0 then
        local y = 0
        local idx = 1
        for _, sec in ipairs(SECTIONS) do
            y = y + 24
            local block = hd.blocks[idx]
            if block then
                block:ClearAllPoints()
                block:SetPoint("TOPLEFT", hd.ch, "TOPLEFT", 4, -y)
                block:SetPoint("RIGHT", hd.ch, "RIGHT", -4, 0)
                block:UpdateHeight()
                y = y + block:GetHeight() + 14
                idx = idx + 1
            end
        end
        hd.totalH = y + 10
    end

    hd.ch:SetHeight(hd.totalH or 800)
end
