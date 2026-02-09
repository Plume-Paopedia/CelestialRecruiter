local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Help (Aide) Tab
-- ═══════════════════════════════════════════════════════════════════

local hd = {}

local SECTIONS = {
    -- =====================================================================
    -- INTRODUCTION
    -- =====================================================================
    {
        title = "Bienvenue sur CelestialRecruiter",
        text =
            "|cff00aaffCelestialRecruiter|r est un assistant de recrutement de guilde complet. " ..
            "Il te permet de scanner les joueurs en ligne, de les ajouter a une file d'attente, " ..
            "de leur envoyer des messages personnalises et des invitations de guilde, le tout " ..
            "depuis une interface intuitive.\n\n" ..
            "L'addon respecte les limites anti-spam de Blizzard grace a un systeme de cooldowns " ..
            "integre. Tu peux recruter efficacement sans risquer de sanction.",
    },
    -- =====================================================================
    -- PREMIERE CONFIGURATION
    -- =====================================================================
    {
        title = "1. Premiere configuration",
        text =
            "Avant de commencer a recruter, configure ton addon :\n\n" ..
            "|cffFFD700Etape 1|r - Ouvre l'addon avec la commande |cff00aaff/cr|r dans le chat.\n\n" ..
            "|cffFFD700Etape 2|r - Va dans l'onglet |cffFFD700Reglages|r et remplis les informations de ta guilde :\n" ..
            "  - |cff00aaffNom de guilde|r : Le nom exact de ta guilde (rempli automatiquement si tu es en guilde).\n" ..
            "  - |cff00aaffDiscord|r : Ton lien d'invitation Discord pour que les recrues puissent te rejoindre.\n" ..
            "  - |cff00aaffJours de raid|r : Par exemple \"Mercredi / Dimanche 21h\".\n" ..
            "  - |cff00aaffObjectif|r : L'objectif de ta guilde (\"Progression Mythique\", \"Ambiance chill\", etc.).\n\n" ..
            "|cffFFD700Etape 3|r - Configure tes |cffFFD700mots-cles|r (section Mots-cles dans Reglages).\n" ..
            "  Ces mots sont utilises pour detecter les joueurs qui parlent de recrutement dans les canaux.\n" ..
            "  Par defaut : guilde, guild, recrute, recrutement, raid, roster, mythique.\n\n" ..
            "|cffFFD700Etape 4|r - Personnalise tes messages d'invitation (section |cffFFD700Messages d'invitation|r " ..
            "dans Reglages).\n" ..
            "  3 modeles sont disponibles : |cff00aaffPar defaut|r, |cff00aaffRaid|r, et |cff00aaffCourt|r.\n" ..
            "  Tu peux les modifier librement avec des variables (voir la section dediee plus bas).\n\n" ..
            "|cff888888Une fois configure, tes reglages sont sauvegardes automatiquement " ..
            "et persistent entre les sessions.|r",
    },
    -- =====================================================================
    -- SCANNER
    -- =====================================================================
    {
        title = "2. Le Scanner - Trouver des joueurs",
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
            "  - |cff00aaffTri|r : Trie les resultats par Niveau (croissant/decroissant), Classe, Zone ou Nom.\n" ..
            "  - |cff00aaffMasquer traites|r : Cache les joueurs deja en file d'attente ou deja contactes/invites.\n\n" ..

            "|cffFFD700Comprendre les lignes :|r\n" ..
            "  - La barre de couleur a gauche correspond a la |cff00aaffcouleur de classe|r du joueur.\n" ..
            "  - |cffffb347XR|r = Joueur cross-realm (serveur connecte) / |cff888888L|r = Joueur local (ton serveur).\n" ..
            "  - Le nom est colore par classe, suivi du niveau, de la classe et de la zone.\n" ..
            "  - |cff33e07aen liste|r = Le joueur est deja dans ta file d'attente.\n" ..
            "  - |cff00aaff+ Liste|r ajoute le joueur a ta file / |cff33e07aInviter|r envoie une invitation guilde directement.\n\n" ..

            "|cffff6b6bLimitation cross-realm :|r La commande /who de WoW ne peut scanner que " ..
            "ton serveur et les serveurs connectes au tien (le cluster). Il est impossible de " ..
            "trouver des joueurs sur des serveurs completement differents. Les joueurs \"XR\" " ..
            "que tu vois sont ceux des royaumes connectes a ton cluster.",
    },
    -- =====================================================================
    -- FILE D'ATTENTE
    -- =====================================================================
    {
        title = "3. La File d'attente - Contacter les joueurs",
        text =
            "La file d'attente regroupe tous les joueurs que tu veux contacter. " ..
            "Les joueurs sans guilde trouves par le scanner y sont ajoutes automatiquement.\n\n" ..

            "|cffFFD700Choisir un modele :|r\n" ..
            "En haut de l'onglet, un menu deroulant |cffFFD700Modele|r te permet de selectionner " ..
            "quel message sera envoye (Par defaut, Raid, Court). Le message est affiche en apercu " ..
            "en bas de l'ecran quand tu survoles un joueur.\n\n" ..

            "|cffFFD700Les boutons par joueur :|r\n" ..
            "  |cff33e07aInviter|r - Envoie une invitation de guilde au joueur. " ..
            "Necessite que tu sois en guilde et que tu aies le droit d'inviter.\n" ..
            "  |cff888888Message|r - Envoie un whisper au joueur avec le modele selectionne. " ..
            "Le message est automatiquement personnalise avec son nom.\n" ..
            "  |cffff6b6bRetirer|r - Retire le joueur de la file (il ne sera pas blackliste).\n\n" ..

            "|cffFFD700Comprendre les lignes :|r\n" ..
            "  - La barre de couleur a gauche correspond a la classe du joueur.\n" ..
            "  - Le nom est colore par classe, avec le niveau et la classe affiches a cote.\n" ..
            "  - Le statut est indique a droite : |cff00aaffnew|r (nouveau), " ..
            "|cffffb347contacted|r (message envoye).\n" ..
            "  - |cff33e07aopt-in|r signifie que le joueur a repondu avec le mot cle d'invitation.\n" ..
            "  - |cff888888src:scanner|r ou |cff888888src:boite|r indique l'origine du contact.\n\n" ..

            "|cffFFD700Filtrage automatique :|r\n" ..
            "Les joueurs deja invites, ayant rejoint la guilde, ou ignores sont automatiquement " ..
            "masques de la file. Seuls les joueurs |cff00aaffnew|r et |cffffb347contacted|r restent visibles.\n\n" ..

            "|cff888888Astuce : Survole un joueur pour voir l'apercu du message qui lui sera envoye " ..
            "en bas de l'ecran. Le message est personnalise avec son nom.|r",
    },
    -- =====================================================================
    -- BOITE DE RECEPTION
    -- =====================================================================
    {
        title = "4. La Boite de reception - Reponses des joueurs",
        text =
            "La boite de reception affiche les joueurs qui t'ont envoye un whisper contenant " ..
            "un de tes mots-cles configures.\n\n" ..

            "|cffFFD700Le systeme d'opt-in :|r\n" ..
            "Quand un joueur repond a ton message avec le |cff00aaffmot cle d'invite|r " ..
            "(par defaut |cff00aaff!invite|r), il est automatiquement marque comme " ..
            "|cff33e07aopt-in|r. Cela signifie qu'il accepte de recevoir une invitation.\n" ..
            "Tu peux alors l'inviter directement depuis la boite ou la file d'attente.\n\n" ..

            "|cffFFD700Les boutons :|r\n" ..
            "  |cff00aaff+ Liste|r - Ajoute le joueur a la file d'attente pour le contacter plus tard.\n" ..
            "  |cff888888Ignorer 7j|r - Ignore le joueur pendant 7 jours (il ne sera plus affiche).\n" ..
            "  |cffff6b6bBlacklist|r - Bloque definitivement le joueur (il ne sera plus jamais contacte).\n\n" ..

            "|cff888888Les joueurs sont tries par date de dernier whisper recu, les plus recents en haut.|r",
    },
    -- =====================================================================
    -- MESSAGES / TEMPLATES
    -- =====================================================================
    {
        title = "5. Les Messages d'invitation - Personnalisation",
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
            "  |cff00aaff{inviteKeyword}|r - Le mot cle que le joueur doit repondre pour opt-in.\n\n" ..

            "|cffFFD700Exemple de message :|r\n" ..
            "|cff888888\"Salut {name}, la guilde {guild} recrute. {goal}. Discord: {discord} :)\"|r\n" ..
            "Deviendra :\n" ..
            "|cff888888\"Salut Arthas, la guilde Celestial Sentinels recrute. Ambiance chill et " ..
            "progression stable. Discord: https://discord.gg/7FbBTkrH :)\"|r\n\n" ..

            "|cffff6b6bImportant :|r Les messages sont coupes a |cffFFD700255 caracteres|r " ..
            "(limite WoW whisper). Verifie que tes messages ne sont pas trop longs !\n" ..
            "Clique |cff888888Reset|r a cote d'un modele pour revenir au texte par defaut.",
    },
    -- =====================================================================
    -- ANTI-SPAM
    -- =====================================================================
    {
        title = "6. Le Systeme Anti-spam - Eviter les sanctions",
        text =
            "CelestialRecruiter integre un systeme anti-spam robuste pour proteger ton compte " ..
            "contre les sanctions Blizzard. |cffff6b6bNe desactive jamais ces protections.|r\n\n" ..

            "|cffFFD700Les limites (dans Reglages) :|r\n" ..
            "  |cff00aaffCooldown invitation|r (defaut: 300s) - Delai minimum entre deux invitations " ..
            "au meme joueur. Empeche de spammer un joueur qui a refuse.\n" ..
            "  |cff00aaffCooldown message|r (defaut: 180s) - Delai minimum entre deux whispers " ..
            "au meme joueur.\n" ..
            "  |cff00aaffMax actions/min|r (defaut: 8) - Nombre maximum d'actions (invites + whispers) " ..
            "par minute au total.\n" ..
            "  |cff00aaffMax invites/h|r (defaut: 10) - Nombre maximum d'invitations de guilde par heure.\n" ..
            "  |cff00aaffMax messages/h|r (defaut: 20) - Nombre maximum de whispers par heure.\n\n" ..

            "|cffFFD700Protections automatiques :|r\n" ..
            "  |cff00aaffRespecter AFK|r - Ne contacte pas les joueurs AFK.\n" ..
            "  |cff00aaffRespecter DND|r - Ne contacte pas les joueurs en mode Ne Pas Deranger.\n" ..
            "  |cff00aaffPause AFK/DND|r (defaut: 900s) - Temps d'attente si le joueur est " ..
            "detecte AFK ou DND.\n" ..
            "  |cff00aaffPas en instance|r - Bloque les actions si tu es en donjon/raid.\n\n" ..

            "|cff888888Les valeurs par defaut sont volontairement conservatrices. " ..
            "Tu peux les ajuster, mais ne descends pas en dessous de la moitie des valeurs " ..
            "par defaut pour eviter tout risque.|r",
    },
    -- =====================================================================
    -- OPTIONS DU SCANNER
    -- =====================================================================
    {
        title = "7. Options avancees du Scanner",
        text =
            "Ces options se trouvent dans l'onglet |cffFFD700Reglages|r :\n\n" ..

            "|cffFFD700Comportement :|r\n" ..
            "  |cff00aaffExiger opt-in|r - Si active, tu ne peux envoyer de message qu'aux joueurs " ..
            "ayant repondu avec le mot cle. Si desactive, tous les joueurs peuvent recevoir un message.\n" ..
            "  |cff00aaffInvites scanner sans opt-in|r - Permet d'inviter les joueurs trouves par le " ..
            "scanner meme s'ils n'ont pas opt-in (utile pour recruter directement les joueurs sans guilde).\n" ..
            "  |cff00aaffInclure joueurs guildes|r - Inclut les joueurs deja dans une guilde dans les " ..
            "resultats du scanner. Desactive par defaut.\n" ..
            "  |cff00aaffInclure cross-realm|r - Inclut les joueurs des serveurs connectes au tien.\n" ..
            "  |cff00aaffFiltre classes|r - Ajoute des sous-requetes par classe pour trouver plus de " ..
            "joueurs (plus lent, active uniquement si tu manques de resultats).\n\n" ..

            "|cffFFD700Parametres de scan :|r\n" ..
            "  |cff00aaffNiveau min|r / |cff00aaffNiveau max|r - Plage de niveaux a scanner " ..
            "(defaut: 10-80).\n" ..
            "  |cff00aaffTranche niveaux|r - Taille de chaque sous-requete (defaut: 10). " ..
            "Exemple : avec tranche 10, le scan fait 10-19, 20-29, etc.\n" ..
            "  |cff00aaffDelai WHO|r (defaut: 6s) - Pause entre chaque requete /who. " ..
            "Ne descends pas en dessous de 3s.\n" ..
            "  |cff00aaffTimeout WHO|r (defaut: 8s) - Temps max d'attente pour une reponse du serveur.",
    },
    -- =====================================================================
    -- BOUTON MINIMAP
    -- =====================================================================
    {
        title = "8. Le Bouton Minimap",
        text =
            "Un bouton est affiche autour de ta minimap pour un acces rapide a l'addon.\n\n" ..
            "  |cffFFD700Clic gauche|r - Ouvre ou ferme l'interface CelestialRecruiter.\n" ..
            "  |cffFFD700Clic droit|r - Lance un scan rapide.\n" ..
            "  |cffFFD700Glisser-deposer|r - Maintiens le clic et deplace la souris pour " ..
            "repositionner le bouton autour de la minimap.\n\n" ..
            "Le badge sur le bouton affiche le nombre de joueurs en file d'attente.\n" ..
            "Tu peux le desactiver dans |cffFFD700Reglages > Bouton minimap|r.",
    },
    -- =====================================================================
    -- STATISTIQUES DE SESSION
    -- =====================================================================
    {
        title = "9. Statistiques de session",
        text =
            "La barre en bas de l'interface affiche tes statistiques en temps reel :\n\n" ..
            "  |cff00aaffContacts|r - Nombre total de contacts dans ta base de donnees.\n" ..
            "  |cff00aaffFile d'attente|r - Nombre de joueurs en attente.\n" ..
            "  |cff00aaffBlacklist|r - Nombre de joueurs blacklistes.\n\n" ..
            "Sur le cote droit : les stats de ta session en cours " ..
            "(invitations envoyees, messages envoyes, joueurs trouves).\n\n" ..
            "|cff888888Survole la barre de statut pour voir le detail complet de ta session " ..
            "(duree, scans lances, joueurs trouves, ajouts en file).|r",
    },
    -- =====================================================================
    -- COMMANDES
    -- =====================================================================
    {
        title = "10. Commandes slash",
        text =
            "|cff00aaff/cr|r - Ouvre ou ferme l'interface CelestialRecruiter.\n" ..
            "|cff00aaff/cr reset|r - Remet |cffff6b6bTOUS|r les reglages et donnees a zero " ..
            "(attention, irreversible !).\n" ..
            "|cff00aaff/cr help|r - Affiche un resume des commandes dans le chat.\n\n" ..
            "|cff888888Tu peux aussi fermer la fenetre avec la touche Echap.|r",
    },
    -- =====================================================================
    -- ASTUCES
    -- =====================================================================
    {
        title = "11. Astuces et bonnes pratiques",
        text =
            "|cffFFD700Pour un recrutement efficace :|r\n\n" ..
            "  1. |cff00aaffScanne regulierement|r - Les joueurs en ligne changent constamment. " ..
            "Lance un scan toutes les 10-15 minutes pour avoir des resultats frais.\n\n" ..
            "  2. |cff00aaffPersonnalise tes messages|r - Un message generique fonctionne moins bien " ..
            "qu'un message qui donne envie. Mentionne ce qui rend ta guilde unique.\n\n" ..
            "  3. |cff00aaffVise les joueurs sans guilde|r - Le scanner ajoute automatiquement " ..
            "les joueurs sans guilde a ta file. Ce sont les plus susceptibles d'accepter.\n\n" ..
            "  4. |cff00aaffUtilise le filtre \"Masquer traites\"|r dans le scanner pour ne voir " ..
            "que les nouveaux joueurs.\n\n" ..
            "  5. |cff00aaffNe spamme pas|r - Laisse les cooldowns anti-spam faire leur travail. " ..
            "Un joueur contacte trop souvent te signalera.\n\n" ..
            "  6. |cff00aaffSois reactif|r - Quand un joueur repond dans ta boite de reception, " ..
            "invite-le rapidement avant qu'il se deconnecte.\n\n" ..
            "  7. |cff00aaffInclude ton Discord|r - Le Discord est essentiel pour donner confiance " ..
            "aux joueurs et leur permettre de decouvrir ta communaute.",
    },
    -- =====================================================================
    -- CREDITS
    -- =====================================================================
    {
        title = "Credits",
        text =
            "|cff00aaffCelestialRecruiter|r a ete cree avec amour par |cffFFD700plume.pao|r " ..
            "pour la guilde |cffFFD700Celestial Sentinels|r.\n\n" ..
            "Rejoins-nous sur Discord : |cff7289da https://discord.gg/7FbBTkrH|r\n\n" ..
            "Si tu as des suggestions, des bugs a signaler ou juste envie de dire merci, " ..
            "n'hesite pas a venir nous voir sur le Discord ! <3\n\n" ..
            "|cff888888Version: 2.7.0  |  Interface: 12.0.x (pre-patch Midnight)|r",
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
