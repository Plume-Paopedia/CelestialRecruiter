local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Settings (Reglages) Tab
-- ═══════════════════════════════════════════════════════════════════

local sd = {}

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function ns.UI_BuildSettings(parent)
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

    sd.sf = sf
    sd.ch = ch

    local function p() return ns.db.profile end
    local y = 0
    local function row(h) y = y - h; return y end

    ---------------------------------------------------------------------------
    -- Section: Guild Profile
    ---------------------------------------------------------------------------
    local h1 = W.MakeHeader(ch, "Profil Guilde")
    h1:SetPoint("TOPLEFT", 4, row(22))
    W.MakeSeparator(ch, h1)
    y = y - 8

    local guildName = W.MakeInput(ch, "Nom guilde", 200,
        function() return p().guildName end,
        function(v) p().guildName = ns.Util_Trim(v) end)
    guildName:SetPoint("TOPLEFT", 4, row(46))

    local discord = W.MakeInput(ch, "Discord", 200,
        function() return p().discord end,
        function(v) p().discord = ns.Util_Trim(v) end)
    discord:SetPoint("LEFT", guildName, "RIGHT", 12, 0)

    local raidDays = W.MakeInput(ch, "Jours raid", 200,
        function() return p().raidDays end,
        function(v) p().raidDays = ns.Util_Trim(v) end)
    raidDays:SetPoint("LEFT", discord, "RIGHT", 12, 0)

    local goal = W.MakeInput(ch, "Objectif", 200,
        function() return p().goal end,
        function(v) p().goal = ns.Util_Trim(v) end)
    goal:SetPoint("TOPLEFT", 4, row(46))

    local invKw = W.MakeInput(ch, "Mot cle opt-in", 200,
        function() return p().inviteKeyword end,
        function(v) p().inviteKeyword = ns.Util_Trim(v) end)
    invKw:SetPoint("LEFT", goal, "RIGHT", 12, 0)

    local keywords = W.MakeInput(ch, "Mots cles (virgules)", 420,
        function() return table.concat(p().keywords or {}, ", ") end,
        function(v) p().keywords = ns.Util_SplitComma(v) end)
    keywords:SetPoint("TOPLEFT", 4, row(46))

    ---------------------------------------------------------------------------
    -- Section: Messages d'invitation (Template Editor)
    ---------------------------------------------------------------------------
    local h1b = W.MakeHeader(ch, "Messages d'invitation")
    h1b:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h1b)
    y = y - 8

    -- Variables hint
    local hint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", 8, row(16))
    hint:SetText("Variables: |cff00aaff{name}|r |cff00aaff{guild}|r |cff00aaff{discord}|r |cff00aaff{raidDays}|r |cff00aaff{goal}|r |cff00aaff{inviteKeyword}|r  |cff888888(max 240 car.)|r")
    hint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 6

    -- Template: Par defaut
    sd.tplDefault = W.MakeTextArea(ch, "Mod\195\168le: Par d\195\169faut", 620, 48,
        function() return ns.Templates_GetText("default") end,
        function(v) ns.Templates_SetText("default", v) end)
    sd.tplDefault:SetPoint("TOPLEFT", 4, row(68))

    sd.tplDefaultReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("default")
        sd.tplDefault:SetValue(ns.Templates_GetText("default"))
    end)
    sd.tplDefaultReset:SetPoint("LEFT", sd.tplDefault, "RIGHT", 8, -6)

    -- Template: Raid
    sd.tplRaid = W.MakeTextArea(ch, "Mod\195\168le: Raid", 620, 48,
        function() return ns.Templates_GetText("raid") end,
        function(v) ns.Templates_SetText("raid", v) end)
    sd.tplRaid:SetPoint("TOPLEFT", 4, row(68))

    sd.tplRaidReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("raid")
        sd.tplRaid:SetValue(ns.Templates_GetText("raid"))
    end)
    sd.tplRaidReset:SetPoint("LEFT", sd.tplRaid, "RIGHT", 8, -6)

    -- Template: Court
    sd.tplShort = W.MakeTextArea(ch, "Mod\195\168le: Court", 620, 48,
        function() return ns.Templates_GetText("short") end,
        function(v) ns.Templates_SetText("short", v) end)
    sd.tplShort:SetPoint("TOPLEFT", 4, row(68))

    sd.tplShortReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("short")
        sd.tplShort:SetValue(ns.Templates_GetText("short"))
    end)
    sd.tplShortReset:SetPoint("LEFT", sd.tplShort, "RIGHT", 8, -6)

    -- Dynamic custom templates (created from web dashboard or other sources)
    sd.customTplWidgets = {}
    local allTemplates = ns.Templates_All()
    -- Sort by id for stable order
    local customIds = {}
    for id, tpl in pairs(allTemplates) do
        if not tpl.builtin then customIds[#customIds + 1] = id end
    end
    table.sort(customIds)
    for _, id in ipairs(customIds) do
        local tpl = allTemplates[id]
        local tplWidget = W.MakeTextArea(ch, "Mod\195\168le: " .. (tpl.name or id), 620, 48,
            function() return ns.Templates_GetText(id) end,
            function(v) ns.Templates_SetText(id, v) end)
        tplWidget:SetPoint("TOPLEFT", 4, row(68))

        local delBtn = W.MakeBtn(ch, "Suppr.", 52, "n", function()
            if ns.db.profile.customTemplates then
                ns.db.profile.customTemplates[id] = nil
            end
            ns.Templates_Init()
            ns.Util_Print("|cffC9AA71[Templates]|r Mod\195\168le '" .. id .. "' supprim\195\169.")
            tplWidget:Hide()
            if sd.customTplWidgets[id] then
                sd.customTplWidgets[id].delBtn:Hide()
            end
        end)
        delBtn:SetPoint("LEFT", tplWidget, "RIGHT", 8, -6)
        sd.customTplWidgets[id] = { widget = tplWidget, delBtn = delBtn }
    end

    ---------------------------------------------------------------------------
    -- Section: Anti-spam
    ---------------------------------------------------------------------------
    local h2 = W.MakeHeader(ch, "Anti-spam")
    h2:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h2)
    y = y - 8

    local cdWhisper = W.MakeNumInput(ch, "Cooldown message (s)", 145,
        function() return p().cooldownWhisper end,
        function(v) p().cooldownWhisper = v end, 180, 0, 86400)
    cdWhisper:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(cdWhisper, "Cooldown message", "Delai minimum (secondes) entre deux messages au meme joueur.")

    local cdInvite = W.MakeNumInput(ch, "Cooldown invitation (s)", 145,
        function() return p().cooldownInvite end,
        function(v) p().cooldownInvite = v end, 300, 0, 86400)
    cdInvite:SetPoint("LEFT", cdWhisper, "RIGHT", 12, 0)
    W.AddTooltip(cdInvite, "Cooldown invitation", "Delai minimum (secondes) entre deux invitations au meme joueur.")

    local maxApm = W.MakeNumInput(ch, "Max actions/min", 145,
        function() return p().maxActionsPerMinute end,
        function(v) p().maxActionsPerMinute = v end, 8, 1, 120)
    maxApm:SetPoint("LEFT", cdInvite, "RIGHT", 12, 0)
    W.AddTooltip(maxApm, "Max actions/min", "Nombre maximum d'actions (messages + invites) par minute.")

    local maxWph = W.MakeNumInput(ch, "Max messages/h", 145,
        function() return p().maxWhispersPerHour end,
        function(v) p().maxWhispersPerHour = v end, 20, 1, 500)
    maxWph:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(maxWph, "Max messages/h", "Nombre maximum de messages envoyes par heure.")

    local maxIph = W.MakeNumInput(ch, "Max invites/h", 145,
        function() return p().maxInvitesPerHour end,
        function(v) p().maxInvitesPerHour = v end, 10, 1, 200)
    maxIph:SetPoint("LEFT", maxWph, "RIGHT", 12, 0)
    W.AddTooltip(maxIph, "Max invites/h", "Nombre maximum d'invitations de guilde envoyees par heure.")

    local afkHold = W.MakeNumInput(ch, "Pause AFK/DND (s)", 145,
        function() return p().afkDndHoldSeconds end,
        function(v) p().afkDndHoldSeconds = v end, 900, 0, 86400)
    afkHold:SetPoint("LEFT", maxIph, "RIGHT", 12, 0)
    W.AddTooltip(afkHold, "Pause AFK/DND", "Duree (secondes) pendant laquelle ignorer un joueur AFK ou DND.")

    local logLim = W.MakeNumInput(ch, "Limite logs", 145,
        function() return p().logLimit end,
        function(v) p().logLimit = v end, 300, 50, 1000)
    logLim:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(logLim, "Limite logs", "Nombre maximum de lignes dans le journal (50-1000).")

    ---------------------------------------------------------------------------
    -- Section: Scanner
    ---------------------------------------------------------------------------
    local h3 = W.MakeHeader(ch, "Scanner")
    h3:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h3)
    y = y - 8

    local lvlMin = W.MakeNumInput(ch, "Niveau min", 120,
        function() return p().scanLevelMin end,
        function(v) p().scanLevelMin = v end, 10, 1, 80)
    lvlMin:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(lvlMin, "Niveau min", "Niveau minimum des joueurs a scanner (1-80).")

    local lvlMax = W.MakeNumInput(ch, "Niveau max", 120,
        function() return p().scanLevelMax end,
        function(v) p().scanLevelMax = v end, 80, 1, 80)
    lvlMax:SetPoint("LEFT", lvlMin, "RIGHT", 12, 0)
    W.AddTooltip(lvlMax, "Niveau max", "Niveau maximum des joueurs a scanner (1-80).")

    local lvlSlice = W.MakeNumInput(ch, "Tranche niveau", 120,
        function() return p().scanLevelSlice end,
        function(v) p().scanLevelSlice = v end, 10, 1, 40)
    lvlSlice:SetPoint("LEFT", lvlMax, "RIGHT", 12, 0)
    W.AddTooltip(lvlSlice, "Tranche niveau", "Nombre de niveaux par requete /who (1-40).")

    local whoDelay = W.MakeNumInput(ch, "Delai WHO (s)", 120,
        function() return p().scanWhoDelaySeconds end,
        function(v) p().scanWhoDelaySeconds = v end, 6, 3, 30)
    whoDelay:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(whoDelay, "Delai WHO", "Secondes d'attente entre chaque requete /who (3-30).")

    local whoTimeout = W.MakeNumInput(ch, "Timeout WHO (s)", 120,
        function() return p().scanWhoTimeoutSeconds end,
        function(v) p().scanWhoTimeoutSeconds = v end, 8, 3, 30)
    whoTimeout:SetPoint("LEFT", whoDelay, "RIGHT", 12, 0)
    W.AddTooltip(whoTimeout, "Timeout WHO", "Duree max d'attente d'une reponse /who avant timeout (3-30).")

    ---------------------------------------------------------------------------
    -- Section: Options
    ---------------------------------------------------------------------------
    local h4 = W.MakeHeader(ch, "Options")
    h4:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h4)
    y = y - 8

    local checks = {
        {"Exiger opt-in par mot cle",
            function() return p().inviteKeywordOnly end,
            function(v) p().inviteKeywordOnly = v end,
            "Seuls les joueurs ayant envoye le mot cle seront invites."},
        {"Inviter depuis scanner sans opt-in",
            function() return p().scannerBypassOptIn end,
            function(v) p().scannerBypassOptIn = v end,
            "Permet d'inviter les joueurs trouves par scan meme sans opt-in."},
        {"Respecter AFK",
            function() return p().respectAFK end,
            function(v) p().respectAFK = v end,
            "Ne pas contacter les joueurs AFK pendant la duree configuree."},
        {"Respecter DND",
            function() return p().respectDND end,
            function(v) p().respectDND = v end,
            "Ne pas contacter les joueurs DND pendant la duree configuree."},
        {"Bloquer en instance",
            function() return p().blockInInstance end,
            function(v) p().blockInInstance = v end,
            "Ne pas recruter quand vous etes en instance."},
        {"Scanner inclut joueurs en guilde",
            function() return p().scanIncludeGuilded end,
            function(v) p().scanIncludeGuilded = v end,
            "Inclure les joueurs deja dans une guilde dans les resultats."},
        {"Scanner inclut cross-realm",
            function() return p().scanIncludeCrossRealm end,
            function(v) p().scanIncludeCrossRealm = v end,
            "Inclure les joueurs d'autres royaumes dans les resultats."},
        {"Scanner par classe (plus lent)",
            function() return p().scanUseClassFilters end,
            function(v) p().scanUseClassFilters = v end,
            "Genere une requete separee par classe pour plus de resultats. Plus lent."},
        {"Bouton minimap",
            function() return p().showMinimapButton end,
            function(v) p().showMinimapButton = v; ns.Minimap_SetShown(v) end,
            "Afficher ou masquer le bouton sur la minimap."},
    }

    sd.checks = {}
    for _, def in ipairs(checks) do
        local chk = W.MakeCheck(ch, def[1], def[2], def[3])
        chk:SetPoint("TOPLEFT", 8, row(26))
        if def[4] then
            W.AddTooltip(chk, def[1], def[4])
        end
        sd.checks[#sd.checks + 1] = chk
    end

    ---------------------------------------------------------------------------
    -- Section: Blacklist
    ---------------------------------------------------------------------------
    local h5 = W.MakeHeader(ch, "Liste noire")
    h5:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h5)
    y = y - 8

    local unbl = W.MakeInput(ch, "Retirer de la blacklist (nom)", 280,
        function() return "" end,
        function(v)
            local key = ns.Util_Key(v)
            if key then
                ns.DB_SetBlacklisted(key, false)
                ns.DB_Log("BL", "Retrait blacklist: " .. key)
                ns.UI_Refresh()
            end
        end)
    unbl:SetPoint("TOPLEFT", 4, row(46))

    ---------------------------------------------------------------------------
    -- Section: Discord Notifications
    ---------------------------------------------------------------------------
    local hDiscord = W.MakeHeader(ch, "Notifications Discord")
    hDiscord:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, hDiscord)
    y = y - 8

    local discordHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discordHint:SetPoint("TOPLEFT", 8, row(16))
    discordHint:SetText("Envoie des notifications Discord en temps reel. Necessite le script Python companion (voir Tools/discord_webhook.py)")
    discordHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 6

    local discordUrl = W.MakeInput(ch, "URL Webhook Discord", 520,
        function() return ns.db.profile.discordNotify and ns.db.profile.discordNotify.webhookUrl or "" end,
        function(v)
            if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
            ns.db.profile.discordNotify.webhookUrl = ns.Util_Trim(v)
        end)
    discordUrl:SetPoint("TOPLEFT", 4, row(46))

    local discordTestBtn = W.MakeBtn(ch, "Test", 80, "p", function()
        if ns.DiscordQueue and ns.DiscordQueue.TestWebhook then
            ns.DiscordQueue:TestWebhook()
        end
    end)
    discordTestBtn:SetPoint("LEFT", discordUrl, "RIGHT", 8, -6)

    local discordEnabled = W.MakeCheck(ch, "Activer les notifications Discord",
        function() return ns.db.profile.discordNotify and ns.db.profile.discordNotify.enabled or false end,
        function(v)
            if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
            ns.db.profile.discordNotify.enabled = v
        end)
    discordEnabled:SetPoint("TOPLEFT", 8, row(26))
    W.AddTooltip(discordEnabled, "Activer Discord", "Envoie des notifications Discord pour les \195\169v\195\169nements de recrutement")

    local autoFlushCheck = W.MakeCheck(ch, "Envoi temps reel (auto-reload)",
        function() return ns.db.profile.discordNotify and ns.db.profile.discordNotify.autoFlush ~= false end,
        function(v)
            if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
            ns.db.profile.discordNotify.autoFlush = v
        end)
    autoFlushCheck:SetPoint("TOPLEFT", 8, row(26))
    W.AddTooltip(autoFlushCheck, "Envoi temps r\195\169el", "Reload automatiquement l'interface apr\195\168s chaque \195\169v\195\169nement pour envoyer les notifications Discord")

    local summaryCheck = W.MakeCheck(ch, "Mode resume (grouper les evenements)",
        function() return ns.db.profile.discordNotify and ns.db.profile.discordNotify.summaryMode ~= false end,
        function(v)
            if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
            ns.db.profile.discordNotify.summaryMode = v
        end)
    summaryCheck:SetPoint("TOPLEFT", 8, row(26))
    W.AddTooltip(summaryCheck, "Mode r\195\169sum\195\169", "Regroupe les \195\169v\195\169nements en un seul message Discord au lieu d'envoyer un message par \195\169v\195\169nement")

    local flushDelayInput = W.MakeNumInput(ch, "Delai d'envoi (secondes)", 120,
        function() return ns.db.profile.discordNotify and ns.db.profile.discordNotify.flushDelay or 30 end,
        function(v)
            if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
            ns.db.profile.discordNotify.flushDelay = v
        end, 30, 5, 120)
    flushDelayInput:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(flushDelayInput, "D\195\169lai d'envoi", "Temps d'attente avant d'envoyer les notifications (permet de regrouper plusieurs \195\169v\195\169nements)")

    -- Event toggles
    y = y - 8
    local eventHeader = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eventHeader:SetPoint("TOPLEFT", 8, row(20))
    eventHeader:SetText("Types d'\195\169v\195\169nements:")
    eventHeader:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    sd.discordEventChecks = {}

    -- Get event categories from DiscordQueue
    if ns.DiscordQueue and ns.DiscordQueue.GetEventTypes then
        local categories = ns.DiscordQueue:GetEventTypes()
        for _, category in ipairs(categories) do
            -- Category label
            local catLabel = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            catLabel:SetPoint("TOPLEFT", 12, row(18))
            catLabel:SetText(category.label)
            catLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            -- Events in this category
            for _, event in ipairs(category.events) do
                local chk = W.MakeCheck(ch, event.label,
                    function()
                        return ns.db.profile.discordNotify and ns.db.profile.discordNotify.events and ns.db.profile.discordNotify.events[event.id] or false
                    end,
                    function(v)
                        if not ns.db.profile.discordNotify then ns.db.profile.discordNotify = {} end
                        if not ns.db.profile.discordNotify.events then ns.db.profile.discordNotify.events = {} end
                        ns.db.profile.discordNotify.events[event.id] = v
                    end)
                chk:SetPoint("TOPLEFT", 20, row(24))
                sd.discordEventChecks[#sd.discordEventChecks + 1] = chk
            end
        end
    end

    y = y - 8

    ---------------------------------------------------------------------------
    -- Section: A/B Testing
    ---------------------------------------------------------------------------
    local hAB = W.MakeHeader(ch, "Test A/B")
    hAB:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, hAB)
    y = y - 8

    local abHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    abHint:SetPoint("TOPLEFT", 8, row(16))
    abHint:SetText("Compare deux modeles de message pour trouver le plus efficace. Le systeme repartit automatiquement les envois.")
    abHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 6

    -- Build template dropdown items from ns.Templates_All()
    local tplItems = {}
    for id, tpl in pairs(ns.Templates_All()) do
        tplItems[#tplItems + 1] = { label = tpl.name or id, value = id }
    end
    table.sort(tplItems, function(a, b) return a.label < b.label end)

    -- Create test form: name, tplA, tplB on same row
    sd.abName = W.MakeInput(ch, "Nom du test", 160,
        function() return "" end,
        function() end)
    sd.abName:SetPoint("TOPLEFT", 4, row(46))

    sd.abTplA = W.MakeDropdown(ch, 130, tplItems, "default", function() end)
    sd.abTplA:SetPoint("LEFT", sd.abName, "RIGHT", 12, -6)

    sd.abTplB = W.MakeDropdown(ch, 130, tplItems, "raid", function() end)
    sd.abTplB:SetPoint("LEFT", sd.abTplA, "RIGHT", 8, 0)

    -- Second row: min samples + create button
    sd.abMinSamples = W.MakeNumInput(ch, "Echantillons min", 110,
        function() return 30 end,
        function() end, 30, 5, 500)
    sd.abMinSamples:SetPoint("TOPLEFT", 4, row(46))

    sd.abCreateBtn = W.MakeBtn(ch, "Creer le test", 100, "p", function()
        local name = sd.abName.eb:GetText()
        if name == "" then name = "Test " .. date("%d/%m %H:%M") end
        local tplA = sd.abTplA:GetVal()
        local tplB = sd.abTplB:GetVal()
        local minS = tonumber(sd.abMinSamples.eb:GetText()) or 30
        ns.ABTesting:CreateTest(name, { tplA, tplB }, minS)
        sd.abName.eb:SetText("")
        ns.UI_RefreshSettings()
    end)
    sd.abCreateBtn:SetPoint("LEFT", sd.abMinSamples, "RIGHT", 12, -6)

    y = y - 8

    -- Pre-create pool of 8 AB test row frames
    sd._abRows = {}
    for i = 1, 8 do
        local r = CreateFrame("Frame", nil, ch, "BackdropTemplate")
        r:SetHeight(52)
        r:SetBackdrop({ bgFile = W.SOLID })
        r:SetBackdropColor(0, 0, 0, 0)
        r:SetPoint("LEFT", 0, 0)
        r:SetPoint("RIGHT", 0, 0)

        r._name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r._name:SetPoint("TOPLEFT", 8, -6)

        r._status = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r._status:SetPoint("LEFT", r._name, "RIGHT", 8, 0)

        r._stats = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r._stats:SetPoint("TOPLEFT", 8, -24)
        r._stats:SetPoint("RIGHT", r, "RIGHT", -260, 0)
        r._stats:SetJustifyH("LEFT")
        r._stats:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        r._btn1 = W.MakeBtn(r, "-", 80, "n", nil)
        r._btn1:SetPoint("TOPRIGHT", -88, -4)

        r._btn2 = W.MakeBtn(r, "Supprimer", 80, "d", nil)
        r._btn2:SetPoint("TOPRIGHT", -4, -4)

        r:Hide()
        sd._abRows[i] = r
    end

    sd._abDynY = y - 8

    ---------------------------------------------------------------------------
    -- Section: Campagnes (elements created, positioned in Refresh)
    ---------------------------------------------------------------------------
    sd._campHeader = W.MakeHeader(ch, "Campagnes")
    sd._campSep = ch:CreateTexture(nil, "OVERLAY")
    sd._campSep:SetTexture(W.SOLID)
    sd._campSep:SetHeight(1)
    sd._campSep:SetPoint("TOPLEFT", sd._campHeader, "BOTTOMLEFT", 0, -2)
    sd._campSep:SetPoint("RIGHT", ch, "RIGHT", -4, 0)
    sd._campSep:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.3)

    sd._campHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sd._campHint:SetText("Cree des campagnes de recrutement avec objectifs et suis leur progression.")
    sd._campHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.campName = W.MakeInput(ch, "Nom campagne", 200,
        function() return "" end,
        function() end)

    sd._campCreateBtn = W.MakeBtn(ch, "Creer campagne", 130, "p", function()
        local name = sd.campName.eb:GetText()
        if name == "" then name = "Campagne " .. date("%d/%m %H:%M") end
        ns.Campaigns:Create(name)
        sd.campName.eb:SetText("")
        ns.UI_RefreshSettings()
    end)

    -- Pre-create pool of 8 campaign row frames
    sd._campRows = {}
    for i = 1, 8 do
        local r = CreateFrame("Frame", nil, ch, "BackdropTemplate")
        r:SetHeight(52)
        r:SetBackdrop({ bgFile = W.SOLID })
        r:SetBackdropColor(0, 0, 0, 0)
        r:SetPoint("LEFT", 0, 0)
        r:SetPoint("RIGHT", 0, 0)

        r._name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r._name:SetPoint("TOPLEFT", 8, -6)

        r._status = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r._status:SetPoint("LEFT", r._name, "RIGHT", 8, 0)

        r._info = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r._info:SetPoint("TOPLEFT", 8, -24)
        r._info:SetPoint("RIGHT", r, "RIGHT", -260, 0)
        r._info:SetJustifyH("LEFT")
        r._info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        r._btn1 = W.MakeBtn(r, "-", 80, "n", nil)
        r._btn1:SetPoint("TOPRIGHT", -168, -4)

        r._btn2 = W.MakeBtn(r, "-", 80, "n", nil)
        r._btn2:SetPoint("TOPRIGHT", -84, -4)

        r._btn3 = W.MakeBtn(r, "Supprimer", 80, "d", nil)
        r._btn3:SetPoint("TOPRIGHT", -4, -4)

        r:Hide()
        sd._campRows[i] = r
    end

    ---------------------------------------------------------------------------
    -- Section: Message de bienvenue
    ---------------------------------------------------------------------------
    local hWelcome = W.MakeHeader(ch, "Message de bienvenue")
    hWelcome:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, hWelcome)
    y = y - 8

    local welcomeHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    welcomeHint:SetPoint("TOPLEFT", 8, row(16))
    welcomeHint:SetText("Envoie automatiquement un whisper de bienvenue quand un joueur rejoint la guilde.")
    welcomeHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 4

    sd.welcomeCheck = W.MakeCheck(ch, "Envoyer un message de bienvenue automatique",
        function() return p().welcomeEnabled end,
        function(v) p().welcomeEnabled = v end)
    sd.welcomeCheck:SetPoint("TOPLEFT", 8, row(26))
    W.AddTooltip(sd.welcomeCheck, "Bienvenue auto", "Envoie un whisper de bienvenue aux nouveaux membres de la guilde.")

    sd.welcomeMsg = W.MakeTextArea(ch, "Message de bienvenue", 620, 48,
        function() return p().welcomeMessage end,
        function(v) p().welcomeMessage = v end)
    sd.welcomeMsg:SetPoint("TOPLEFT", 4, row(68))

    sd.welcomeDelay = W.MakeNumInput(ch, "D\195\169lai (secondes)", 120,
        function() return p().welcomeDelay end,
        function(v) p().welcomeDelay = v end, 5, 1, 60)
    sd.welcomeDelay:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(sd.welcomeDelay, "D\195\169lai", "Secondes d'attente apr\195\168s l'arriv\195\169e du joueur avant d'envoyer le message.")

    y = y - 8

    ---------------------------------------------------------------------------
    -- Section: Mode Nuit & AI
    ---------------------------------------------------------------------------
    local hNuit = W.MakeHeader(ch, "Mode Nuit & AI")
    hNuit:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, hNuit)
    y = y - 8

    local nuitHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nuitHint:SetPoint("TOPLEFT", 8, row(16))
    nuitHint:SetText("Recrutement AFK automatique. Traite la file d'attente pendant que vous dormez. N\195\169cessite le tier Pro.")
    nuitHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 6

    -- Toggle button
    sd.nuitToggle = W.MakeBtn(ch, "D\195\169marrer Mode Nuit", 160, "p", function()
        if ns.SleepRecruiter and ns.SleepRecruiter.Toggle then
            ns.SleepRecruiter:Toggle()
            ns.UI_RefreshSettings()
        end
    end)
    sd.nuitToggle:SetPoint("TOPLEFT", 4, row(34))
    W.AddTooltip(sd.nuitToggle, "Mode Nuit", "D\195\169marre/arr\195\170te le recrutement automatique AFK.\nUtilise les messages AI si disponibles, sinon le mod\195\168le s\195\169lectionn\195\169.\nCommande: /cr nuit")

    -- Status text (dynamic, updated in refresh)
    sd.nuitStatus = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sd.nuitStatus:SetPoint("LEFT", sd.nuitToggle, "RIGHT", 12, 6)
    sd.nuitStatus:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    sd.nuitStatus:SetText("")

    -- Mode dropdown
    local nuitModeItems = {
        { label = "Whisper + Invite", value = "recruit" },
        { label = "Whisper seul", value = "whisper" },
        { label = "Invite seul", value = "invite" },
    }
    sd.nuitMode = W.MakeDropdown(ch, 160, nuitModeItems,
        (p().sleepRecruiter and p().sleepRecruiter.mode) or "recruit",
        function(v) p().sleepRecruiter.mode = v end)
    sd.nuitMode:SetPoint("TOPLEFT", 4, row(46))

    -- Template dropdown (fallback)
    local nuitTplItems = {}
    for id, tpl in pairs(ns.Templates_All()) do
        nuitTplItems[#nuitTplItems + 1] = { label = tpl.name or id, value = id }
    end
    table.sort(nuitTplItems, function(a, b) return a.label < b.label end)

    sd.nuitTemplate = W.MakeDropdown(ch, 160, nuitTplItems,
        (p().sleepRecruiter and p().sleepRecruiter.template) or "default",
        function(v) p().sleepRecruiter.template = v end)
    sd.nuitTemplate:SetPoint("LEFT", sd.nuitMode, "RIGHT", 12, 0)

    -- Delay between actions
    local nuitDelay = W.MakeNumInput(ch, "D\195\169lai entre actions (s)", 145,
        function() return p().sleepRecruiter and p().sleepRecruiter.delayBetweenActions or 60 end,
        function(v) p().sleepRecruiter.delayBetweenActions = v end, 60, 30, 300)
    nuitDelay:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(nuitDelay, "D\195\169lai", "Secondes entre chaque action de recrutement (30-300).")

    -- Max duration
    local nuitDuration = W.MakeNumInput(ch, "Dur\195\169e max (heures)", 145,
        function() return p().sleepRecruiter and p().sleepRecruiter.maxDurationHours or 8 end,
        function(v) p().sleepRecruiter.maxDurationHours = v end, 8, 1, 12)
    nuitDuration:SetPoint("LEFT", nuitDelay, "RIGHT", 12, 0)
    W.AddTooltip(nuitDuration, "Dur\195\169e max", "Dur\195\169e maximale du Mode Nuit avant arr\195\170t automatique (1-12h).")

    -- Max contacts
    local nuitMax = W.MakeNumInput(ch, "Max contacts", 145,
        function() return p().sleepRecruiter and p().sleepRecruiter.maxContacts or 200 end,
        function(v) p().sleepRecruiter.maxContacts = v end, 200, 10, 999)
    nuitMax:SetPoint("LEFT", nuitDuration, "RIGHT", 12, 0)
    W.AddTooltip(nuitMax, "Max contacts", "Nombre maximum de contacts \195\160 traiter avant arr\195\170t (10-999).")

    -- Reload interval
    local nuitReload = W.MakeNumInput(ch, "Intervalle reload (min)", 145,
        function() return p().sleepRecruiter and p().sleepRecruiter.reloadIntervalMin or 10 end,
        function(v) p().sleepRecruiter.reloadIntervalMin = v end, 10, 5, 20)
    nuitReload:SetPoint("TOPLEFT", 4, row(46))
    W.AddTooltip(nuitReload, "Intervalle reload", "Fr\195\169quence de ReloadUI pour synchroniser les messages AI (5-20 min).")

    -- Use AI toggle
    sd.nuitUseAI = W.MakeCheck(ch, "Utiliser les messages AI (si Python actif)",
        function() return p().sleepRecruiter and p().sleepRecruiter.useAI ~= false end,
        function(v) p().sleepRecruiter.useAI = v end)
    sd.nuitUseAI:SetPoint("TOPLEFT", 8, row(26))
    W.AddTooltip(sd.nuitUseAI, "Messages AI", "Utilise les messages g\195\169n\195\169r\195\169s par le companion Python (Claude API).\nSi d\195\169sactiv\195\169 ou Python non lanc\195\169, utilise le mod\195\168le s\195\169lectionn\195\169.")

    y = y - 8

    ---------------------------------------------------------------------------
    -- Section: Maintenance
    ---------------------------------------------------------------------------
    local hMaint = W.MakeHeader(ch, "Maintenance")
    hMaint:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, hMaint)
    y = y - 8

    local maintHint = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maintHint:SetPoint("TOPLEFT", 8, row(18))
    maintHint:SetText("Soft reset : efface contacts, file, blacklist et stats. Conserve r\195\169glages et mod\195\168les.")
    maintHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    y = y - 4

    sd.softResetBtn = W.MakeBtn(ch, "Soft Reset", 110, "d", function()
        StaticPopupDialogs["CR_SOFT_RESET"] = {
            text = "Soft reset : effacer contacts, file d'attente, blacklist et statistiques ?\n\nLes r\195\169glages et mod\195\168les seront conserv\195\169s.",
            button1 = "Oui, r\195\169initialiser",
            button2 = "Annuler",
            OnAccept = function()
                ns.DB_SoftReset()
                ns.Templates_Init()
                ns.UI_Refresh()
                ns.Util_Print("Soft reset effectu\195\169. R\195\169glages et mod\195\168les conserv\195\169s.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("CR_SOFT_RESET")
    end)
    sd.softResetBtn:SetPoint("TOPLEFT", 4, row(34))
    W.AddTooltip(sd.softResetBtn, "Soft Reset", "Efface contacts, file, blacklist et stats.\nConserve r\195\169glages, mod\195\168les et anti-spam.")

    sd._buildEndY = y
    sd.totalH = math.max(900, math.abs(y) + 40)
    ch:SetHeight(sd.totalH)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshSettings()
    if not sd.ch then return end

    -- Update Mode Nuit toggle button
    if sd.nuitToggle and ns.SleepRecruiter then
        local isActive = ns.SleepRecruiter:IsActive()
        sd.nuitToggle:SetLabel(isActive and "Arr\195\170ter Mode Nuit" or "D\195\169marrer Mode Nuit")
        if sd.nuitStatus then
            if isActive then
                local stats = ns.SleepRecruiter:GetStats()
                sd.nuitStatus:SetText("|cff33dd77Actif|r - " .. (stats.processed or 0) .. " trait\195\169s")
            else
                sd.nuitStatus:SetText("|cffaaaaaa Inactif|r")
            end
        end
    end

    local dy = sd._abDynY

    ---------------------------------------------------------------------------
    -- A/B Testing rows
    ---------------------------------------------------------------------------
    local abTests = (ns.ABTesting and ns.ABTesting.GetAllTests) and ns.ABTesting:GetAllTests() or {}
    local abCount = math.min(#abTests, 8)

    for i = 1, abCount do
        local test = abTests[i]
        local r = sd._abRows[i]

        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, dy)
        r:SetPoint("RIGHT", 0, 0)
        W.SetRowBG(r, i)
        dy = dy - 52

        -- Name with status-based color
        if test.status == "active" then
            r._name:SetTextColor(C.green[1], C.green[2], C.green[3])
        elseif test.status == "completed" then
            r._name:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        else
            r._name:SetTextColor(C.text[1], C.text[2], C.text[3])
        end
        r._name:SetText(test.name or test.id)

        -- Status badge
        local statusLabels = {
            active = "|cff33dd77actif|r",
            paused = "|cffff8888pause|r",
            completed = "|cffffff00termine|r",
        }
        r._status:SetText(statusLabels[test.status] or test.status)

        -- Stats line per variant
        local parts = {}
        for _, v in ipairs(test.variants or {}) do
            parts[#parts + 1] = (v.templateId or "?") .. ": " .. v.sent .. " envoyes, " .. v.replies .. " reponses, " .. v.joined .. " recrues"
        end
        r._stats:SetText(table.concat(parts, "  |  "))

        -- btn1: Start / Pause
        if test.status == "active" then
            r._btn1:SetLabel("Pause")
            r._btn1:SetScript("OnClick", function()
                ns.ABTesting:PauseTest(test.id)
                ns.UI_RefreshSettings()
            end)
            r._btn1:SetOff(false)
        elseif test.status == "completed" then
            r._btn1:SetLabel("Termine")
            r._btn1:SetOff(true)
        else
            r._btn1:SetLabel("Demarrer")
            r._btn1:SetScript("OnClick", function()
                ns.ABTesting:StartTest(test.id)
                ns.UI_RefreshSettings()
            end)
            r._btn1:SetOff(false)
        end

        -- btn2: Delete
        r._btn2:SetScript("OnClick", function()
            ns.ABTesting:DeleteTest(test.id)
            ns.UI_RefreshSettings()
        end)

        r:Show()
    end

    -- Hide unused AB rows
    for i = abCount + 1, 8 do
        sd._abRows[i]:Hide()
    end

    ---------------------------------------------------------------------------
    -- Campagnes section positioning
    ---------------------------------------------------------------------------
    dy = dy - 30
    sd._campHeader:ClearAllPoints()
    sd._campHeader:SetPoint("TOPLEFT", 4, dy)
    dy = dy - 22

    sd._campHint:ClearAllPoints()
    sd._campHint:SetPoint("TOPLEFT", 8, dy)
    dy = dy - 22

    sd.campName:ClearAllPoints()
    sd.campName:SetPoint("TOPLEFT", 4, dy)
    sd._campCreateBtn:ClearAllPoints()
    sd._campCreateBtn:SetPoint("LEFT", sd.campName, "RIGHT", 12, -6)
    dy = dy - 52

    ---------------------------------------------------------------------------
    -- Campaign rows
    ---------------------------------------------------------------------------
    local camps = (ns.Campaigns and ns.Campaigns.GetAll) and ns.Campaigns:GetAll() or {}
    local campCount = math.min(#camps, 8)

    for i = 1, campCount do
        local camp = camps[i]
        local r = sd._campRows[i]
        local prog = ns.Campaigns:GetProgress(camp.id)

        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, dy)
        r:SetPoint("RIGHT", 0, 0)
        W.SetRowBG(r, i)
        dy = dy - 52

        -- Name with color
        if camp.status == "active" then
            r._name:SetTextColor(C.green[1], C.green[2], C.green[3])
        else
            r._name:SetTextColor(C.text[1], C.text[2], C.text[3])
        end
        r._name:SetText(camp.name or camp.id)

        -- Status badge
        local campStatusLabels = {
            draft = "|cffaaaaaabrouillon|r",
            active = "|cff33dd77actif|r",
            paused = "|cffff8888pause|r",
            completed = "|cffffff00termine|r",
            archived = "|cff888888archive|r",
        }
        r._status:SetText(campStatusLabels[camp.status] or camp.status)

        -- Info line
        local cProg = prog.contacted or {}
        local iProg = prog.invited or {}
        local jProg = prog.joined or {}
        r._info:SetText(
            "Tpl: " .. (camp.template or "default") ..
            " | Contact\195\169s: " .. (cProg.current or 0) .. "/" .. (cProg.target or 0) ..
            " | Invit\195\169s: " .. (iProg.current or 0) .. "/" .. (iProg.target or 0) ..
            " | Recrues: " .. (jProg.current or 0) .. "/" .. (jProg.target or 0)
        )

        -- Buttons based on status
        if camp.status == "draft" or camp.status == "paused" then
            r._btn1:SetLabel("Demarrer")
            r._btn1:SetScript("OnClick", function()
                if camp.status == "paused" then
                    ns.Campaigns:Resume(camp.id)
                else
                    ns.Campaigns:Start(camp.id)
                end
                ns.UI_RefreshSettings()
            end)
            r._btn1:SetOff(false)
            r._btn1:Show()

            r._btn2:SetLabel("Archiver")
            r._btn2:SetScript("OnClick", function()
                ns.Campaigns:Archive(camp.id)
                ns.UI_RefreshSettings()
            end)
            r._btn2:SetOff(false)
            r._btn2:Show()
        elseif camp.status == "active" then
            r._btn1:SetLabel("Pause")
            r._btn1:SetScript("OnClick", function()
                ns.Campaigns:Pause(camp.id)
                ns.UI_RefreshSettings()
            end)
            r._btn1:SetOff(false)
            r._btn1:Show()

            r._btn2:SetLabel("Terminer")
            r._btn2:SetScript("OnClick", function()
                ns.Campaigns:Complete(camp.id)
                ns.UI_RefreshSettings()
            end)
            r._btn2:SetOff(false)
            r._btn2:Show()
        elseif camp.status == "completed" then
            r._btn1:SetLabel("Archiver")
            r._btn1:SetScript("OnClick", function()
                ns.Campaigns:Archive(camp.id)
                ns.UI_RefreshSettings()
            end)
            r._btn1:SetOff(false)
            r._btn1:Show()

            r._btn2:SetLabel("-")
            r._btn2:SetOff(true)
            r._btn2:Hide()
        elseif camp.status == "archived" then
            r._btn1:SetLabel("-")
            r._btn1:SetOff(true)
            r._btn1:Hide()

            r._btn2:SetLabel("-")
            r._btn2:SetOff(true)
            r._btn2:Hide()
        end

        -- btn3: Delete (always available)
        r._btn3:SetScript("OnClick", function()
            ns.Campaigns:Delete(camp.id)
            ns.UI_RefreshSettings()
        end)

        r:Show()
    end

    -- Hide unused campaign rows
    for i = campCount + 1, 8 do
        sd._campRows[i]:Hide()
    end

    ---------------------------------------------------------------------------
    -- Finalize content height
    ---------------------------------------------------------------------------
    sd.totalH = -dy + 20
    sd.ch:SetHeight(sd.totalH)
end
