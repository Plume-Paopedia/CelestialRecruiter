local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local format = string.format

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Scanner Tab (Control Panel)
-- ═══════════════════════════════════════════════════════════════════

local sd = {}

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
        ns.Scanner_Stop()
        ns.UI_Refresh()
    end)
    sd.stopBtn:SetPoint("LEFT", sd.scanBtn, "RIGHT", 6, 0)

    -- Import /who
    sd.importBtn = W.MakeBtn(controls, "Import /who", 100, "n", function()
        local added, total = ns.Scanner_ImportCurrentWho()
        ns.Util_Print(("Import /who: %d/%d"):format(added or 0, total or 0))
        ns.UI_Refresh()
    end)
    sd.importBtn:SetPoint("LEFT", sd.stopBtn, "RIGHT", 6, 0)

    -- Clear
    sd.clearBtn = W.MakeBtn(controls, "Vider", 60, "n", function()
        ns.Scanner_Clear()
        ns.UI_Refresh()
    end)
    sd.clearBtn:SetPoint("LEFT", sd.importBtn, "RIGHT", 6, 0)

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

    local dash = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dash:SetPoint("LEFT", sd.lvlMinInput, "RIGHT", 4, 0)
    dash:SetText("-")
    dash:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.lvlMaxInput = makeInput(configBar, 44)
    sd.lvlMaxInput:SetPoint("LEFT", dash, "RIGHT", 4, 0)
    sd.lvlMaxInput:SetText(tostring(ns.db and ns.db.profile.scanLevelMax or 80))

    local sliceLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sliceLabel:SetPoint("LEFT", sd.lvlMaxInput, "RIGHT", 16, 0)
    sliceLabel:SetText("Tranche:")
    sliceLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    sd.sliceInput = makeInput(configBar, 36)
    sd.sliceInput:SetPoint("LEFT", sliceLabel, "RIGHT", 6, 0)
    sd.sliceInput:SetText(tostring(ns.db and ns.db.profile.scanLevelSlice or 5))

    -- Info label: scan mode
    local modeLabel = configBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("LEFT", sd.sliceInput, "RIGHT", 16, 0)
    modeLabel:SetText("|cff888888Scan par classe|r")

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

    -- Scan button state
    if awaiting then
        sd.scanBtn:SetLabel("Attente WHO...")
        sd.scanBtn:SetOff(true)
    elseif cd >= 1 then
        sd.scanBtn:SetLabel(format("Scanner (%.0fs)", cd))
        sd.scanBtn:SetOff(true)
    else
        sd.scanBtn:SetLabel("Scanner")
        sd.scanBtn:SetOff(false)
    end

    -- Pulse animation
    if scanning and not sd.pulseAG:IsPlaying() then
        sd.scanGlow:Show()
        sd.pulseAG:Play()
    elseif not scanning and sd.pulseAG:IsPlaying() then
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
            sd.classInfo:SetText(format("En cours :  |c%s%s|r   Niv %s", hex, cn, lr))
        elseif awaiting then
            sd.classInfo:SetText("Attente de reponse /who...")
        else
            sd.classInfo:SetText("|cff00aaffScan actif...|r")
        end
    else
        if total > 0 and sent >= total then
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

    -- Stats line 2: queue + session
    local qBadge = ns.UI_QueueBadge and ns.UI_QueueBadge() or ""
    local qCount = qBadge ~= "" and qBadge or "0"
    local sessMsg = ns.sessionStats and ns.sessionStats.whispersSent or 0
    local sessInv = ns.sessionStats and ns.sessionStats.invitesSent or 0
    sd.statsText2:SetText(format(
        "En file d'attente: |cffffb347%s|r   Session: %d msg, %d inv",
        qCount, sessMsg, sessInv
    ))
end

---------------------------------------------------------------------------
-- Badge (tab count)
---------------------------------------------------------------------------
function ns.UI_ScannerBadge()
    local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}
    local n = st.listedPlayers or 0
    return n > 0 and tostring(n) or ""
end
