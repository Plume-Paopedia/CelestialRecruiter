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
        function() return p().cooldownWhisper end,
        function(v) p().cooldownWhisper = v end, 180, 0, 86400)
    cdWhisper:SetPoint("TOPLEFT", 4, row(46))

    local cdInvite = W.MakeNumInput(ch, "Cooldown invitation (s)", 145,
        function() return p().cooldownInvite end,
        function(v) p().cooldownInvite = v end, 300, 0, 86400)
    cdInvite:SetPoint("LEFT", cdWhisper, "RIGHT", 12, 0)

    local maxApm = W.MakeNumInput(ch, "Max actions/min", 145,
        function() return p().maxActionsPerMinute end,
        function(v) p().maxActionsPerMinute = v end, 8, 1, 120)
    maxApm:SetPoint("LEFT", cdInvite, "RIGHT", 12, 0)

    local maxWph = W.MakeNumInput(ch, "Max messages/h", 145,
        function() return p().maxWhispersPerHour end,
        function(v) p().maxWhispersPerHour = v end, 20, 1, 500)
    maxWph:SetPoint("TOPLEFT", 4, row(46))

    local maxIph = W.MakeNumInput(ch, "Max invites/h", 145,
        function() return p().maxInvitesPerHour end,
        function(v) p().maxInvitesPerHour = v end, 10, 1, 200)
    maxIph:SetPoint("LEFT", maxWph, "RIGHT", 12, 0)

    local afkHold = W.MakeNumInput(ch, "Pause AFK/DND (s)", 145,
        function() return p().afkDndHoldSeconds end,
        function(v) p().afkDndHoldSeconds = v end, 900, 0, 86400)
    afkHold:SetPoint("LEFT", maxIph, "RIGHT", 12, 0)

    local logLim = W.MakeNumInput(ch, "Limite logs", 145,
        function() return p().logLimit end,
        function(v) p().logLimit = v end, 300, 50, 1000)
    logLim:SetPoint("TOPLEFT", 4, row(46))

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

    local lvlMax = W.MakeNumInput(ch, "Niveau max", 120,
        function() return p().scanLevelMax end,
        function(v) p().scanLevelMax = v end, 80, 1, 80)
    lvlMax:SetPoint("LEFT", lvlMin, "RIGHT", 12, 0)

    local lvlSlice = W.MakeNumInput(ch, "Tranche niveau", 120,
        function() return p().scanLevelSlice end,
        function(v) p().scanLevelSlice = v end, 10, 1, 40)
    lvlSlice:SetPoint("LEFT", lvlMax, "RIGHT", 12, 0)

    local whoDelay = W.MakeNumInput(ch, "Delai WHO (s)", 120,
        function() return p().scanWhoDelaySeconds end,
        function(v) p().scanWhoDelaySeconds = v end, 6, 3, 30)
    whoDelay:SetPoint("TOPLEFT", 4, row(46))

    local whoTimeout = W.MakeNumInput(ch, "Timeout WHO (s)", 120,
        function() return p().scanWhoTimeoutSeconds end,
        function(v) p().scanWhoTimeoutSeconds = v end, 8, 3, 30)
    whoTimeout:SetPoint("LEFT", whoDelay, "RIGHT", 12, 0)

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
            function(v) p().inviteKeywordOnly = v end},
        {"Inviter depuis scanner sans opt-in",
            function() return p().scannerBypassOptIn end,
            function(v) p().scannerBypassOptIn = v end},
        {"Respecter AFK",
            function() return p().respectAFK end,
            function(v) p().respectAFK = v end},
        {"Respecter DND",
            function() return p().respectDND end,
            function(v) p().respectDND = v end},
        {"Bloquer en instance",
            function() return p().blockInInstance end,
            function(v) p().blockInInstance = v end},
        {"Scanner inclut joueurs en guilde",
            function() return p().scanIncludeGuilded end,
            function(v) p().scanIncludeGuilded = v end},
        {"Scanner inclut cross-realm",
            function() return p().scanIncludeCrossRealm end,
            function(v) p().scanIncludeCrossRealm = v end},
        {"Scanner par classe (plus lent)",
            function() return p().scanUseClassFilters end,
            function(v) p().scanUseClassFilters = v end},
        {"Bouton minimap",
            function() return p().showMinimapButton end,
            function(v) p().showMinimapButton = v; ns.Minimap_SetShown(v) end},
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

    sd.totalH = 900
    ch:SetHeight(sd.totalH)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshSettings()
    if not sd.ch then return end

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
            " | Contactes: " .. (cProg.current or 0) .. "/" .. (cProg.target or 0) ..
            " | Invites: " .. (iProg.current or 0) .. "/" .. (iProg.target or 0) ..
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
