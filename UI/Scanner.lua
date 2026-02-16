local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local format = string.format

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Scanner Tab (Control Panel + Results List)
-- ═══════════════════════════════════════════════════════════════════

local sd = {}
local _lastAmbientTime = 0

-- Confirmation popup for clearing scanner results
StaticPopupDialogs["CELREC_CONFIRM_CLEAR"] = {
    text = "Voulez-vous vraiment effacer tous les r\195\169sultats du scan ?",
    button1 = "Oui",
    button2 = "Non",
    OnAccept = function()
        ns.Scanner_Clear()
        if ns.Notifications_Info then
            ns.Notifications_Info("R\195\169sultats vid\195\169s", "Les r\195\169sultats du scan ont \195\169t\195\169 effac\195\169s.")
        end
        ns.UI_Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Pre-computed color strings (avoid format() in tight loops)
local MUTED_HEX = format("%02x%02x%02x", C.muted[1]*255, C.muted[2]*255, C.muted[3]*255)
local STATUS_BLACKLIST = "|cffff6666Blackliste|r"
local STATUS_CROSSREALM = "|cffffb347Inter-royaume|r"
local STATUS_IGNORED = "|cff" .. MUTED_HEX .. "Ignore|r"
local STATUS_QUEUED = "|cffffd700En file|r"
local STATUS_RECENT_INVITE = "|cffFFA500Invite recemment|r"
local NAME_FALLBACK_PREFIX = "|cff00aaff"

local function makeInput(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 22)
    box:SetBackdrop({bgFile = W.SOLID, edgeFile = W.EDGE, edgeSize = 8,
        insets = {left=2, right=2, top=2, bottom=2}})
    box:SetBackdropColor(0.05, 0.06, 0.11, 0.85)
    box:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetTextInsets(4, 4, 0, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    return box
end

---------------------------------------------------------------------------
-- Row Factory: Scanner result row
---------------------------------------------------------------------------
local function MakeScannerRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(W.ROW_H)
    row:SetBackdrop({bgFile = W.SOLID})
    W.SetRowBG(row, i)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(s)
        s:SetBackdropColor(unpack(C.hover))
        W.ShowPlayerTooltip(s, s._boundKey, s._boundScan)
    end)
    row:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(s._bgc))
        W.HidePlayerTooltip()
    end)

    -- Class color bar (3px left edge)
    row.bar = row:CreateTexture(nil, "OVERLAY")
    row.bar:SetTexture(W.SOLID)
    row.bar:SetWidth(3)
    row.bar:SetPoint("TOPLEFT")
    row.bar:SetPoint("BOTTOMLEFT")

    -- Name (class-colored, 170px)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", 8, 0)
    row.name:SetWidth(170)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Level + Class (100px, dim)
    row.classInfo = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.classInfo:SetPoint("LEFT", 182, 0)
    row.classInfo:SetWidth(100)
    row.classInfo:SetJustifyH("LEFT")
    row.classInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.classInfo:SetWordWrap(false)

    -- Race (70px, dim)
    row.race = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.race:SetPoint("LEFT", 286, 0)
    row.race:SetWidth(70)
    row.race:SetJustifyH("LEFT")
    row.race:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.race:SetWordWrap(false)

    -- Zone (100px, muted)
    row.zone = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.zone:SetPoint("LEFT", 360, 0)
    row.zone:SetWidth(100)
    row.zone:SetJustifyH("LEFT")
    row.zone:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    row.zone:SetWordWrap(false)

    -- Guild / Status label (120px)
    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.status:SetPoint("LEFT", 464, 0)
    row.status:SetWidth(120)
    row.status:SetJustifyH("LEFT")
    row.status:SetWordWrap(false)

    -- Add button (28x24, style "s") - hidden for ineligibles
    row.addBtn = W.MakeBtn(row, "+", 28, "s", nil)
    row.addBtn:SetPoint("RIGHT", -6, 0)

    W.AddRowGlow(row)
    return row
end

---------------------------------------------------------------------------
-- Build (called once during init)
---------------------------------------------------------------------------
function ns.UI_BuildScanner(parent)
    -- ── Row 1: Controls ──────────────────────────────────────────────
    local controls = CreateFrame("Frame", nil, parent)
    controls:SetHeight(34)
    controls:SetPoint("TOPLEFT", 8, -8)
    controls:SetPoint("TOPRIGHT", -8, -8)

    -- Scan button with pulse
    sd.scanBtn = W.MakeBtn(controls, "Scanner", 110, "p", function()
        -- Read config from inputs before scanning
        local minV = tonumber(sd.lvlMinInput:GetText())
        local maxV = tonumber(sd.lvlMaxInput:GetText())
        local slcV = tonumber(sd.sliceInput:GetText())
        if minV then ns.db.profile.scanLevelMin = minV end
        if maxV then ns.db.profile.scanLevelMax = maxV end
        if slcV then ns.db.profile.scanLevelSlice = slcV end

        local ok, why = ns.Scanner_ScanStep(false)
        if not ok
            and why ~= "scan complete"
            and not (type(why) == "string" and why:sub(1, 4) == "wait")
            and why ~= "waiting WHO result"
        then
            ns.Util_Print("Scan: " .. W.reasonFr(why))
        end
        ns.UI_Refresh()
    end)
    sd.scanBtn:SetPoint("LEFT", 0, 0)
    W.AddTooltip(sd.scanBtn, "Scanner", "Lance un scan /who par tranches de niveaux.")

    -- Pulse glow overlay
    sd.scanGlow = sd.scanBtn:CreateTexture(nil, "BACKGROUND")
    sd.scanGlow:SetPoint("TOPLEFT", -2, 2)
    sd.scanGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    sd.scanGlow:SetTexture(W.SOLID)
    sd.scanGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.15)
    sd.scanGlow:Hide()
    sd.pulseAG = sd.scanGlow:CreateAnimationGroup()
    sd.pulseAG:SetLooping("BOUNCE")
    local pulse = sd.pulseAG:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.15)
    pulse:SetToAlpha(0)
    pulse:SetDuration(0.8)
    pulse:SetSmoothing("IN_OUT")

    -- Stop
    sd.stopBtn = W.MakeBtn(controls, "Stop", 66, "d", function()
        if ns.db.profile.scanAutoEnabled then
            ns.db.profile.scanAutoEnabled = false
        end
        ns.Scanner_Stop()
        ns.UI_Refresh()
    end)
    sd.stopBtn:SetPoint("LEFT", sd.scanBtn, "RIGHT", 6, 0)
    W.AddTooltip(sd.stopBtn, "Stop", "Arrete le scan en cours et l'auto-scan.")

    -- Import /who
    sd.importBtn = W.MakeBtn(controls, "Importer /who", 100, "n", function()
        local added, total = ns.Scanner_ImportCurrentWho()
        local msg = format("Import /who: %d/%d", added or 0, total or 0)
        ns.Util_Print(msg)
        if ns.Notifications_Success and (added or 0) > 0 then
            ns.Notifications_Success("Import /who", format("%d joueur(s) import\195\169(s) sur %d.", added, total))
        elseif ns.Notifications_Info then
            ns.Notifications_Info("Import /who", "Aucun nouveau joueur trouv\195\169.")
        end
        ns.UI_Refresh()
    end)
    sd.importBtn:SetPoint("LEFT", sd.stopBtn, "RIGHT", 6, 0)
    W.AddTooltip(sd.importBtn, "Importer /who", "Importe les resultats de la fenetre /who actuelle.")

    -- Clear (with confirmation)
    sd.clearBtn = W.MakeBtn(controls, "Vider", 60, "n", function()
        StaticPopup_Show("CELREC_CONFIRM_CLEAR")
    end)
    sd.clearBtn:SetPoint("LEFT", sd.importBtn, "RIGHT", 6, 0)
    W.AddTooltip(sd.clearBtn, "Vider", "Supprime tous les resultats du scan.")

    -- Auto-Scan checkbox
    sd.autoScanCheck = W.MakeCheck(controls, "Auto",
        function() return ns.db.profile.scanAutoEnabled end,
        function(v)
            local minV = tonumber(sd.lvlMinInput:GetText())
            local maxV = tonumber(sd.lvlMaxInput:GetText())
            local slcV = tonumber(sd.sliceInput:GetText())
            if minV then ns.db.profile.scanLevelMin = minV end
            if maxV then ns.db.profile.scanLevelMax = maxV end
            if slcV then ns.db.profile.scanLevelSlice = slcV end
            ns.Scanner_AutoScanToggle(v)
        end)
    sd.autoScanCheck:SetPoint("LEFT", sd.clearBtn, "RIGHT", 16, 0)

    -- Auto-Scan tooltip: explain the click/keypress mechanism
    sd.autoScanCheck:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Auto-Scan", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Chaque clic dans le monde ou appui de touche", 1, 1, 1, true)
        GameTooltip:AddLine("lance automatiquement la requete /who suivante.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Jouez normalement : le scan avance en arriere-plan", 0.4, 0.8, 1, true)
        GameTooltip:AddLine("pendant que vous vous deplacez ou combattez.", 0.4, 0.8, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Restriction Blizzard : la commande /who necessite", 0.5, 0.5, 0.5, true)
        GameTooltip:AddLine("une action physique (clic ou touche du clavier).", 0.5, 0.5, 0.5, true)
        GameTooltip:AddLine("Un scan 100% AFK n'est pas possible.", 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    sd.autoScanCheck:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- ── Row 2: Scan Config ───────────────────────────────────────────
    local configBar = CreateFrame("Frame", nil, parent)
    configBar:SetHeight(28)
    configBar:SetPoint("TOPLEFT", 8, -46)
    configBar:SetPoint("TOPRIGHT", -8, -46)

    local lvlLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lvlLabel:SetPoint("LEFT", 0, 0)
    lvlLabel:SetText("Niveaux:")
    lvlLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.lvlMinInput = makeInput(configBar, 44)
    sd.lvlMinInput:SetPoint("LEFT", lvlLabel, "RIGHT", 6, 0)
    sd.lvlMinInput:SetText(tostring(ns.db and ns.db.profile.scanLevelMin or 10))
    W.AddTooltip(sd.lvlMinInput, "Niveau minimum", "Le scan cherchera a partir de ce niveau.")

    local dash = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dash:SetPoint("LEFT", sd.lvlMinInput, "RIGHT", 4, 0)
    dash:SetText("-")
    dash:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.lvlMaxInput = makeInput(configBar, 44)
    sd.lvlMaxInput:SetPoint("LEFT", dash, "RIGHT", 4, 0)
    sd.lvlMaxInput:SetText(tostring(ns.db and ns.db.profile.scanLevelMax or 80))
    W.AddTooltip(sd.lvlMaxInput, "Niveau maximum", "Le scan cherchera jusqu'a ce niveau.")

    local sliceLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sliceLabel:SetPoint("LEFT", sd.lvlMaxInput, "RIGHT", 16, 0)
    sliceLabel:SetText("Tranche:")
    sliceLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.sliceInput = makeInput(configBar, 36)
    sd.sliceInput:SetPoint("LEFT", sliceLabel, "RIGHT", 6, 0)
    sd.sliceInput:SetText(tostring(ns.db and ns.db.profile.scanLevelSlice or 5))
    W.AddTooltip(sd.sliceInput, "Tranche", "Nombre de niveaux par requete /who.")

    -- Info label: scan mode
    local modeLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("LEFT", sd.sliceInput, "RIGHT", 16, 0)
    modeLabel:SetText("|cff888888Scan par classe|r")

    -- Auto-scan cycle delay input (visible only when auto-scan active)
    sd.autoDelayLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sd.autoDelayLabel:SetPoint("LEFT", modeLabel, "RIGHT", 16, 0)
    sd.autoDelayLabel:SetText("Delai cycle (min):")
    sd.autoDelayLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    sd.autoDelayLabel:Hide()

    sd.autoDelayInput = makeInput(configBar, 36)
    sd.autoDelayInput:SetPoint("LEFT", sd.autoDelayLabel, "RIGHT", 6, 0)
    sd.autoDelayInput:SetText(tostring(ns.db and ns.db.profile.scanAutoDelayMinutes or 5))
    W.AddTooltip(sd.autoDelayInput, "Delai inter-cycle", "Minutes d'attente entre deux cycles auto-scan.")
    sd.autoDelayInput:SetScript("OnEnterPressed", function(s)
        local v = tonumber(s:GetText())
        if v then
            ns.db.profile.scanAutoDelayMinutes = math.max(1, math.min(60, v))
        end
        s:ClearFocus()
    end)
    sd.autoDelayInput:Hide()

    -- ── Row 3: Big Progress Bar ──────────────────────────────────────
    local progBg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    progBg:SetHeight(22)
    progBg:SetPoint("TOPLEFT", 8, -82)
    progBg:SetPoint("TOPRIGHT", -8, -82)
    progBg:SetBackdrop({bgFile = W.SOLID})
    progBg:SetBackdropColor(1, 1, 1, 0.06)
    sd.progBg = progBg

    -- Fill
    sd.progFill = progBg:CreateTexture(nil, "ARTWORK")
    sd.progFill:SetTexture(W.SOLID)
    sd.progFill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    sd.progFill:SetPoint("TOPLEFT")
    sd.progFill:SetPoint("BOTTOMLEFT")
    sd.progFill:SetWidth(1)

    -- Spark
    sd.progSpark = progBg:CreateTexture(nil, "ARTWORK", nil, 1)
    sd.progSpark:SetTexture(W.SOLID)
    sd.progSpark:SetSize(6, 22)
    sd.progSpark:SetVertexColor(1, 1, 1, 0.9)
    sd.progSpark:SetPoint("RIGHT", sd.progFill, "RIGHT", 0, 0)
    sd.progSpark:Hide()
    sd.sparkAG = sd.progSpark:CreateAnimationGroup()
    sd.sparkAG:SetLooping("BOUNCE")
    local sparkPulse = sd.sparkAG:CreateAnimation("Alpha")
    sparkPulse:SetFromAlpha(0.5)
    sparkPulse:SetToAlpha(1.0)
    sparkPulse:SetDuration(0.6)
    sparkPulse:SetSmoothing("IN_OUT")

    -- Percentage overlay
    sd.progText = progBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sd.progText:SetPoint("CENTER")
    sd.progText:SetTextColor(1, 1, 1, 0.9)

    -- ── Row 4: Current class info ────────────────────────────────────
    sd.classInfo = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sd.classInfo:SetPoint("TOPLEFT", 10, -112)
    sd.classInfo:SetPoint("TOPRIGHT", -10, -112)
    sd.classInfo:SetJustifyH("LEFT")
    sd.classInfo:SetTextColor(C.text[1], C.text[2], C.text[3])

    -- ── Row 5: Stats line ────────────────────────────────────────────
    sd.statsText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sd.statsText:SetPoint("TOPLEFT", 10, -134)
    sd.statsText:SetPoint("TOPRIGHT", -10, -134)
    sd.statsText:SetJustifyH("LEFT")
    sd.statsText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- ── Row 6: Secondary stats ───────────────────────────────────────
    sd.statsText2 = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sd.statsText2:SetPoint("TOPLEFT", 10, -152)
    sd.statsText2:SetPoint("TOPRIGHT", -10, -152)
    sd.statsText2:SetJustifyH("LEFT")
    sd.statsText2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- ── Scroll area: scan results list ───────────────────────────────
    sd.scroll = W.MakeScroll(parent)
    sd.scroll.frame:SetPoint("TOPLEFT", 8, -172)
    sd.scroll.frame:SetPoint("BOTTOMRIGHT", -8, 8)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshScanner()
    if not sd.scanBtn then return end

    local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}
    local scanning = st.scanning
    local awaiting = st.awaiting
    local cd = st.cooldownRemaining or 0

    local autoOn = st.autoScanEnabled

    -- Sync auto-scan checkbox
    if sd.autoScanCheck then
        sd.autoScanCheck:SetChecked(autoOn and true or false)
    end
    if sd.autoDelayLabel then
        sd.autoDelayLabel:SetShown(autoOn)
    end
    if sd.autoDelayInput then
        sd.autoDelayInput:SetShown(autoOn)
        if not sd.autoDelayInput:HasFocus() then
            sd.autoDelayInput:SetText(tostring(st.autoScanDelayMinutes or 5))
        end
    end

    local autoReady = st.autoScanReady

    -- Scan button state
    if awaiting then
        sd.scanBtn:SetLabel(autoOn and "Auto: WHO..." or "Attente WHO...")
        sd.scanBtn:SetOff(true)
    elseif cd >= 1 then
        sd.scanBtn:SetLabel(format(autoOn and "Auto (%.0fs)" or "Scanner (%.0fs)", cd))
        sd.scanBtn:SetOff(true)
    elseif autoOn and autoReady then
        sd.scanBtn:SetLabel("Cliquez!")
        sd.scanBtn:SetOff(false)
    else
        sd.scanBtn:SetLabel(autoOn and "Auto-Scan" or "Scanner")
        sd.scanBtn:SetOff(false)
    end

    -- Pulse animation: pulse when auto-scan is ready for a click
    local shouldPulse = scanning or (autoOn and autoReady)
    if shouldPulse and not sd.pulseAG:IsPlaying() then
        sd.scanGlow:Show()
        sd.pulseAG:Play()
    elseif not shouldPulse and sd.pulseAG:IsPlaying() then
        sd.pulseAG:Stop()
        sd.scanGlow:Hide()
    end

    -- Progress bar
    local total = st.totalQueries or 0
    local sent = st.querySent or 0
    local prog = total > 0 and (sent / total) or 0
    local barW = sd.progBg:GetWidth() or 1
    local pw = math.max(1, barW * prog)
    sd.progFill:SetWidth(pw)
    sd.progFill:SetVertexColor(
        C.accent[1], C.accent[2], C.accent[3],
        scanning and 0.7 or (prog > 0 and 0.3 or 0.08)
    )

    -- Spark
    if scanning and prog > 0 and prog < 1 then
        sd.progSpark:Show()
        if not sd.sparkAG:IsPlaying() then sd.sparkAG:Play() end
    else
        sd.sparkAG:Stop()
        sd.progSpark:Hide()
    end

    -- Ambient particles during active scanning (throttled: max 1 call / 2s)
    if scanning then
        local now = GetTime()
        if now - _lastAmbientTime >= 2 then
            _lastAmbientTime = now
            local PS = ns.ParticleSystem
            if PS and PS.PlayScannerAmbientEffect then
                PS:PlayScannerAmbientEffect(sd.progBg)
            end
        end
    end

    -- Percentage text on bar
    if total > 0 then
        sd.progText:SetText(format("%d%%   (%d / %d)", math.floor(prog * 100), sent, total))
    else
        sd.progText:SetText("")
    end

    -- Current class info
    if scanning then
        local cn = st.currentClassName or ""
        local cf = st.currentClassFile or ""
        local lr = st.currentLevelRange or ""
        if cn ~= "" then
            local hex = cf ~= "" and W.classHex(cf) or "ff00aaff"
            if autoOn and autoReady then
                sd.classInfo:SetText(format("|c%s%s|r Niv %s  —  |cff33e07aPret! Cliquez ou bougez|r", hex, cn, lr))
            else
                sd.classInfo:SetText(format("En cours :  |c%s%s|r   Niv %s", hex, cn, lr))
            end
        elseif awaiting then
            sd.classInfo:SetText("Attente de r\195\169ponse /who...")
        elseif autoOn and autoReady then
            sd.classInfo:SetText("|cff33e07aPret!|r  Cliquez ou appuyez une touche")
        else
            sd.classInfo:SetText("|cff00aaffScan actif...|r")
        end
    else
        if autoOn and autoReady and not st.autoScanWaiting then
            sd.classInfo:SetText("|cff33e07aPret!|r  Cliquez ou appuyez une touche pour demarrer")
        elseif st.autoScanWaiting and autoOn then
            sd.classInfo:SetText(format(
                "|cff00aaffAuto-Scan|r  —  Cycle %d termine, prochain dans %d min",
                st.autoScanCycles or 0, st.autoScanDelayMinutes or 5
            ))
        elseif autoOn and not autoReady and (scanning or cd > 0) then
            sd.classInfo:SetText(format("|cff00aaffAuto-Scan|r  —  Cooldown %.0fs", cd))
        elseif total > 0 and sent >= total then
            sd.classInfo:SetText("|cff33e07aScan termine|r")
        elseif total > 0 then
            sd.classInfo:SetText("|cffffb347Scan en pause|r  —  Clique Scanner pour continuer")
        else
            sd.classInfo:SetText("Clique |cff00aaffScanner|r pour demarrer")
        end
    end

    -- Stats line 1
    local players = st.listedPlayers or 0
    local capped = st.cappedQueries or 0
    local capStr = capped > 0 and format("   |cffffb347Plafonds: %d|r", capped) or ""
    sd.statsText:SetText(format(
        "Joueurs trouves: |cff00aaff%d|r   Requetes: %d / %d%s",
        players, sent, total, capStr
    ))

    -- Stats line 2: queue + session + auto-scan cycle
    local qBadge = ns.UI_QueueBadge and ns.UI_QueueBadge() or ""
    local qCount = qBadge ~= "" and qBadge or "0"
    local sessMsg = ns.sessionStats and ns.sessionStats.whispersSent or 0
    local sessInv = ns.sessionStats and ns.sessionStats.invitesSent or 0
    local autoStr = ""
    if autoOn then
        autoStr = format("   |cff00aaffAuto: cycle %d|r", (st.autoScanCycles or 0) + 1)
    end
    sd.statsText2:SetText(format(
        "En file d'attente: |cffffb347%s|r   Session: %d msg, %d inv%s",
        qCount, sessMsg, sessInv, autoStr
    ))

    -- ── Results list ─────────────────────────────────────────────────
    if not sd.scroll then return end

    local scanRows = ns.Scanner_GetRows and ns.Scanner_GetRows() or {}
    local search = ns._ui_search or ""

    -- Queue lookup via DB_IsQueued (O(1) per key, no list rebuild)

    -- Filter and sort
    local filtered = {}
    for _, rec in ipairs(scanRows) do
        if rec and rec.key then
            if W.matchSearch(search, rec.key, rec.classLabel or "", rec.race or "", rec.zone or "", rec.guild or "") then
                filtered[#filtered + 1] = rec
            end
        end
    end

    -- Sort by lastSeen descending (most recent first)
    table.sort(filtered, function(a, b)
        return (a.lastSeen or 0) > (b.lastSeen or 0)
    end)

    local scroll = sd.scroll
    local rows = scroll.rows

    if #filtered == 0 then
        scroll:ShowEmpty("|TInterface\\Icons\\INV_Misc_Spyglass_03:14:14:0:0|t", "Aucun joueur scanne")
        for _, r in ipairs(rows) do r:Hide() end
        scroll:SetH(scroll.sf:GetHeight())
        return
    end
    scroll:HideEmpty()

    for i, rec in ipairs(filtered) do
        if not rows[i] then rows[i] = MakeScannerRow(scroll.child, i) end
        local row = rows[i]
        row:Show()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -(i - 1) * W.ROW_H)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")

        local key = rec.key
        local cf = rec.classFile or ""
        local skipped = rec.skipReason ~= nil
        local queued = ns.DB_IsQueued and ns.DB_IsQueued(key) or false

        -- Store data for tooltip (lazy, only on hover)
        row._boundKey = key
        row._boundScan = rec

        -- Class color bar
        row.bar:SetVertexColor(W.classRGB(cf))

        -- Name (class colored, pre-computed hex)
        if cf ~= "" then
            row.name:SetText("|c" .. W.classHex(cf) .. key .. "|r")
        else
            row.name:SetText(NAME_FALLBACK_PREFIX .. key .. "|r")
        end

        -- Level + class
        local lvl = rec.level or 0
        local clsLabel = rec.classLabel or ""
        if lvl > 0 and clsLabel ~= "" then
            row.classInfo:SetText(format("Niv %d  %s", lvl, clsLabel))
        elseif lvl > 0 then
            row.classInfo:SetText(format("Niv %d", lvl))
        elseif clsLabel ~= "" then
            row.classInfo:SetText(clsLabel)
        else
            row.classInfo:SetText("")
        end

        -- Race
        row.race:SetText(rec.race or "")

        -- Zone
        row.zone:SetText(rec.zone or "")

        -- Guild / Status label (pre-computed constants)
        if rec.skipReason == "blacklist" then
            row.status:SetText(STATUS_BLACKLIST)
        elseif rec.skipReason == "crossrealm" then
            row.status:SetText(STATUS_CROSSREALM)
        elseif rec.skipReason == "recent_invite" then
            local contact = ns.DB_GetContact and ns.DB_GetContact(key) or nil
            if contact and (contact.lastInviteAt or 0) > 0 then
                row.status:SetText("|cffFFA500Invite " .. ns.Util_FormatAgo(contact.lastInviteAt) .. "|r")
            else
                row.status:SetText(STATUS_RECENT_INVITE)
            end
        elseif queued then
            row.status:SetText(STATUS_QUEUED)
        elseif rec.guild and rec.guild ~= "" then
            row.status:SetText("|cffffb347<" .. rec.guild .. ">|r")
        else
            -- Only check contact status for non-skipped, non-queued, unguilded
            local contact = ns.DB_GetContact and ns.DB_GetContact(key) or nil
            if contact and contact.status == "ignored" then
                row.status:SetText(STATUS_IGNORED)
            else
                row.status:SetText("")
            end
        end

        -- Row alpha: dimmed for ineligible
        row:SetAlpha(skipped and 0.5 or 1)

        -- Add button: only rewire closure when key changes (avoids GC churn)
        if not skipped and not queued then
            row.addBtn:Show()
            row.addBtn:SetOff(false)
            if row._addBoundKey ~= key then
                row._addBoundKey = key
                row._addBoundRec = rec
                row.addBtn:SetScript("OnClick", function()
                    local r = row._addBoundRec
                    ns.DB_UpsertContact(row._addBoundKey, {
                        name = r.name,
                        source = "scanner",
                        classFile = r.classFile or "",
                        classLabel = r.classLabel or "",
                        level = r.level or 0,
                        race = r.race or "",
                        zone = r.zone or "",
                        guild = r.guild or "",
                    })
                    ns.DB_QueueAdd(row._addBoundKey)
                    ns.UI_Refresh()
                end)
            else
                row._addBoundRec = rec
            end
        else
            row.addBtn:Hide()
            row._addBoundKey = nil
        end
    end

    for i = #filtered + 1, #rows do rows[i]:Hide() end
    scroll:SetH(#filtered * W.ROW_H)
end

---------------------------------------------------------------------------
-- Badge (tab count)
---------------------------------------------------------------------------
function ns.UI_ScannerBadge()
    local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}
    local n = st.listedPlayers or 0
    return n > 0 and tostring(n) or ""
end
