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

    local p = ns.db.profile
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
        function() return p.guildName end,
        function(v) p.guildName = ns.Util_Trim(v) end)
    guildName:SetPoint("TOPLEFT", 4, row(46))

    local discord = W.MakeInput(ch, "Discord", 200,
        function() return p.discord end,
        function(v) p.discord = ns.Util_Trim(v) end)
    discord:SetPoint("LEFT", guildName, "RIGHT", 12, 0)

    local raidDays = W.MakeInput(ch, "Jours raid", 200,
        function() return p.raidDays end,
        function(v) p.raidDays = ns.Util_Trim(v) end)
    raidDays:SetPoint("LEFT", discord, "RIGHT", 12, 0)

    local goal = W.MakeInput(ch, "Objectif", 200,
        function() return p.goal end,
        function(v) p.goal = ns.Util_Trim(v) end)
    goal:SetPoint("TOPLEFT", 4, row(46))

    local invKw = W.MakeInput(ch, "Mot cle invite", 200,
        function() return p.inviteKeyword end,
        function(v) p.inviteKeyword = ns.Util_Trim(v) end)
    invKw:SetPoint("LEFT", goal, "RIGHT", 12, 0)

    local keywords = W.MakeInput(ch, "Mots cles (virgules)", 420,
        function() return table.concat(p.keywords or {}, ", ") end,
        function(v) p.keywords = ns.Util_SplitComma(v) end)
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
    sd.tplDefault = W.MakeTextArea(ch, "Modele: Par defaut", 620, 48,
        function() return ns.Templates_GetText("default") end,
        function(v) ns.Templates_SetText("default", v) end)
    sd.tplDefault:SetPoint("TOPLEFT", 4, row(68))

    sd.tplDefaultReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("default")
        sd.tplDefault:SetValue(ns.Templates_GetText("default"))
    end)
    sd.tplDefaultReset:SetPoint("LEFT", sd.tplDefault, "RIGHT", 8, -6)

    -- Template: Raid
    sd.tplRaid = W.MakeTextArea(ch, "Modele: Raid", 620, 48,
        function() return ns.Templates_GetText("raid") end,
        function(v) ns.Templates_SetText("raid", v) end)
    sd.tplRaid:SetPoint("TOPLEFT", 4, row(68))

    sd.tplRaidReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("raid")
        sd.tplRaid:SetValue(ns.Templates_GetText("raid"))
    end)
    sd.tplRaidReset:SetPoint("LEFT", sd.tplRaid, "RIGHT", 8, -6)

    -- Template: Court
    sd.tplShort = W.MakeTextArea(ch, "Modele: Court", 620, 48,
        function() return ns.Templates_GetText("short") end,
        function(v) ns.Templates_SetText("short", v) end)
    sd.tplShort:SetPoint("TOPLEFT", 4, row(68))

    sd.tplShortReset = W.MakeBtn(ch, "Reset", 52, "n", function()
        ns.Templates_ResetToDefault("short")
        sd.tplShort:SetValue(ns.Templates_GetText("short"))
    end)
    sd.tplShortReset:SetPoint("LEFT", sd.tplShort, "RIGHT", 8, -6)

    ---------------------------------------------------------------------------
    -- Section: Anti-spam
    ---------------------------------------------------------------------------
    local h2 = W.MakeHeader(ch, "Anti-spam")
    h2:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h2)
    y = y - 8

    local cdWhisper = W.MakeNumInput(ch, "Cooldown message (s)", 145,
        function() return p.cooldownWhisper end,
        function(v) p.cooldownWhisper = v end, 180, 0, 86400)
    cdWhisper:SetPoint("TOPLEFT", 4, row(46))

    local cdInvite = W.MakeNumInput(ch, "Cooldown invitation (s)", 145,
        function() return p.cooldownInvite end,
        function(v) p.cooldownInvite = v end, 300, 0, 86400)
    cdInvite:SetPoint("LEFT", cdWhisper, "RIGHT", 12, 0)

    local maxApm = W.MakeNumInput(ch, "Max actions/min", 145,
        function() return p.maxActionsPerMinute end,
        function(v) p.maxActionsPerMinute = v end, 8, 1, 120)
    maxApm:SetPoint("LEFT", cdInvite, "RIGHT", 12, 0)

    local maxWph = W.MakeNumInput(ch, "Max messages/h", 145,
        function() return p.maxWhispersPerHour end,
        function(v) p.maxWhispersPerHour = v end, 20, 1, 500)
    maxWph:SetPoint("TOPLEFT", 4, row(46))

    local maxIph = W.MakeNumInput(ch, "Max invites/h", 145,
        function() return p.maxInvitesPerHour end,
        function(v) p.maxInvitesPerHour = v end, 10, 1, 200)
    maxIph:SetPoint("LEFT", maxWph, "RIGHT", 12, 0)

    local afkHold = W.MakeNumInput(ch, "Pause AFK/DND (s)", 145,
        function() return p.afkDndHoldSeconds end,
        function(v) p.afkDndHoldSeconds = v end, 900, 0, 86400)
    afkHold:SetPoint("LEFT", maxIph, "RIGHT", 12, 0)

    local logLim = W.MakeNumInput(ch, "Limite logs", 145,
        function() return p.logLimit end,
        function(v) p.logLimit = v end, 300, 50, 1000)
    logLim:SetPoint("TOPLEFT", 4, row(46))

    ---------------------------------------------------------------------------
    -- Section: Scanner
    ---------------------------------------------------------------------------
    local h3 = W.MakeHeader(ch, "Scanner")
    h3:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h3)
    y = y - 8

    local lvlMin = W.MakeNumInput(ch, "Niveau min", 120,
        function() return p.scanLevelMin end,
        function(v) p.scanLevelMin = v end, 10, 1, 80)
    lvlMin:SetPoint("TOPLEFT", 4, row(46))

    local lvlMax = W.MakeNumInput(ch, "Niveau max", 120,
        function() return p.scanLevelMax end,
        function(v) p.scanLevelMax = v end, 80, 1, 80)
    lvlMax:SetPoint("LEFT", lvlMin, "RIGHT", 12, 0)

    local lvlSlice = W.MakeNumInput(ch, "Tranche niv", 120,
        function() return p.scanLevelSlice end,
        function(v) p.scanLevelSlice = v end, 10, 1, 40)
    lvlSlice:SetPoint("LEFT", lvlMax, "RIGHT", 12, 0)

    local whoDelay = W.MakeNumInput(ch, "Delai WHO (s)", 120,
        function() return p.scanWhoDelaySeconds end,
        function(v) p.scanWhoDelaySeconds = v end, 6, 3, 30)
    whoDelay:SetPoint("TOPLEFT", 4, row(46))

    local whoTimeout = W.MakeNumInput(ch, "Timeout WHO (s)", 120,
        function() return p.scanWhoTimeoutSeconds end,
        function(v) p.scanWhoTimeoutSeconds = v end, 8, 3, 30)
    whoTimeout:SetPoint("LEFT", whoDelay, "RIGHT", 12, 0)

    ---------------------------------------------------------------------------
    -- Section: Options
    ---------------------------------------------------------------------------
    local h4 = W.MakeHeader(ch, "Options")
    h4:SetPoint("TOPLEFT", 4, row(30))
    W.MakeSeparator(ch, h4)
    y = y - 8

    local checks = {
        {"Exiger opt-in mot cle",
            function() return p.inviteKeywordOnly end,
            function(v) p.inviteKeywordOnly = v end},
        {"Invites scanner sans opt-in",
            function() return p.scannerBypassOptIn end,
            function(v) p.scannerBypassOptIn = v end},
        {"Respecter AFK",
            function() return p.respectAFK end,
            function(v) p.respectAFK = v end},
        {"Respecter DND",
            function() return p.respectDND end,
            function(v) p.respectDND = v end},
        {"Bloquer en instance",
            function() return p.blockInInstance end,
            function(v) p.blockInInstance = v end},
        {"Scanner inclut joueurs guildes",
            function() return p.scanIncludeGuilded end,
            function(v) p.scanIncludeGuilded = v end},
        {"Scanner inclut cross-realm",
            function() return p.scanIncludeCrossRealm end,
            function(v) p.scanIncludeCrossRealm = v end},
        {"Scanner filtre classes (lent)",
            function() return p.scanUseClassFilters end,
            function(v) p.scanUseClassFilters = v end},
        {"Bouton minimap",
            function() return p.showMinimapButton end,
            function(v) p.showMinimapButton = v; ns.Minimap_SetShown(v) end},
    }

    sd.checks = {}
    for _, def in ipairs(checks) do
        local chk = W.MakeCheck(ch, def[1], def[2], def[3])
        chk:SetPoint("TOPLEFT", 8, row(26))
        sd.checks[#sd.checks + 1] = chk
    end

    ---------------------------------------------------------------------------
    -- Section: Blacklist
    ---------------------------------------------------------------------------
    local h5 = W.MakeHeader(ch, "Blacklist")
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

    sd.totalH = -y + 20
    ch:SetHeight(sd.totalH)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshSettings()
    if sd.ch then
        sd.ch:SetHeight(sd.totalH or 900)
    end
end
