local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local SOLID = W.SOLID
local EDGE  = W.EDGE

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Main UI Frame, Tabs, Status Bar & Public API
-- ═══════════════════════════════════════════════════════════════════

---------------------------------------------------------------------------
-- Shared state (read by tab modules)
---------------------------------------------------------------------------
ns._ui_search    = ""
ns._ui_tpl       = "default"
ns._ui_logFilter = "ALL"

local UI = ns.UI or {shown = false}
ns.UI = UI
UI.active = "Scanner"

---------------------------------------------------------------------------
-- Tab definitions
---------------------------------------------------------------------------
local TABS = {
    {key = "Scanner",  label = "|cff00aaff\226\151\137|r Scanner",    badge = ns.UI_ScannerBadge},
    {key = "Queue",    label = "|cffFFD700\226\151\143|r File d'attente", badge = ns.UI_QueueBadge},
    {key = "Inbox",    label = "|cff33e07a\226\151\136|r Boite",       badge = ns.UI_InboxBadge},
    {key = "Settings", label = "|cff888888\226\154\153|r Reglages"},
    {key = "Logs",     label = "|cff888888\226\150\164|r Journaux"},
    {key = "Help",     label = "|cff888888\226\151\136|r Aide"},
}

local tabBtns    = {}
local tabPanels  = {}
local tabIndicator

---------------------------------------------------------------------------
-- Forward declarations
---------------------------------------------------------------------------
local SwitchTab, RefreshCurrent, UpdateStatusBar, UpdateBadges

---------------------------------------------------------------------------
-- Main Frame
---------------------------------------------------------------------------
local function CreateMainFrame()
    local f = CreateFrame("Frame", "CelestialRecruiterFrame", UIParent, "BackdropTemplate")
    f:SetSize(960, 640)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    -- Resizable
    f:SetResizable(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(720, 460, 1400, 900)
    else
        f:SetMinResize(720, 460)
        f:SetMaxResize(1400, 900)
    end

    -- Main backdrop
    f:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    f:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
    f:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.8)

    -- Drop shadow
    local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", -5, 5)
    shadow:SetPoint("BOTTOMRIGHT", 5, -5)
    shadow:SetFrameLevel(math.max(1, f:GetFrameLevel() - 1))
    shadow:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 18,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    shadow:SetBackdropColor(0, 0, 0, 0.5)
    shadow:SetBackdropBorderColor(0, 0, 0, 0.6)

    -- Inner glow borders (subtle accent highlight inside frame edges)
    local glowA = 0.05
    local glTop = f:CreateTexture(nil, "ARTWORK")
    glTop:SetTexture(SOLID); glTop:SetHeight(1)
    glTop:SetPoint("TOPLEFT", 4, -4); glTop:SetPoint("TOPRIGHT", -4, -4)
    glTop:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], glowA)
    local glBot = f:CreateTexture(nil, "ARTWORK")
    glBot:SetTexture(SOLID); glBot:SetHeight(1)
    glBot:SetPoint("BOTTOMLEFT", 4, 4); glBot:SetPoint("BOTTOMRIGHT", -4, 4)
    glBot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], glowA)
    local glL = f:CreateTexture(nil, "ARTWORK")
    glL:SetTexture(SOLID); glL:SetWidth(1)
    glL:SetPoint("TOPLEFT", 4, -4); glL:SetPoint("BOTTOMLEFT", 4, 4)
    glL:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], glowA)
    local glR = f:CreateTexture(nil, "ARTWORK")
    glR:SetTexture(SOLID); glR:SetWidth(1)
    glR:SetPoint("TOPRIGHT", -4, -4); glR:SetPoint("BOTTOMRIGHT", -4, 4)
    glR:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], glowA)

    -- ===== Title Bar =====
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- Title bar gradient glow (accent fading left to right)
    local titleGrad = titleBar:CreateTexture(nil, "BACKGROUND")
    titleGrad:SetTexture(SOLID)
    titleGrad:SetAllPoints()
    titleGrad:SetGradient("HORIZONTAL", CreateColor(C.accent[1], C.accent[2], C.accent[3], 0.10), CreateColor(0, 0, 0, 0))

    -- Accent line under title bar
    local titleLine = titleBar:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture(SOLID)
    titleLine:SetHeight(1)
    titleLine:SetPoint("BOTTOMLEFT", 0, 0)
    titleLine:SetPoint("BOTTOMRIGHT", 0, 0)
    titleLine:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.20)

    -- Gold star with gentle pulse
    local star = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    star:SetPoint("LEFT", 8, 0)
    star:SetText("|cffFFD700*|r")
    local starPulse = star:CreateAnimationGroup()
    starPulse:SetLooping("BOUNCE")
    local sp = starPulse:CreateAnimation("Alpha")
    sp:SetFromAlpha(0.55)
    sp:SetToAlpha(1)
    sp:SetDuration(2.2)
    sp:SetSmoothing("IN_OUT")
    starPulse:Play()

    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", star, "RIGHT", 4, 0)
    title:SetText("CelestialRecruiter")
    title:SetTextColor(C.text[1], C.text[2], C.text[3])

    -- Version
    local ver = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
    ver:SetText("v3.0.0")
    ver:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -- Close button with hover background
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn.bg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBtn.bg:SetTexture(SOLID)
    closeBtn.bg:SetAllPoints()
    closeBtn.bg:SetVertexColor(C.red[1], C.red[2], C.red[3], 0)
    closeBtn.t = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtn.t:SetPoint("CENTER")
    closeBtn.t:SetText("x")
    closeBtn.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    closeBtn:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
        s.bg:SetVertexColor(C.red[1], C.red[2], C.red[3], 0.18)
    end)
    closeBtn:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        s.bg:SetVertexColor(C.red[1], C.red[2], C.red[3], 0)
    end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Search box
    local search = CreateFrame("EditBox", nil, titleBar, "BackdropTemplate")
    search:SetSize(180, 22)
    search:SetPoint("RIGHT", closeBtn, "LEFT", -12, 0)
    search:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    search:SetBackdropColor(0.05, 0.06, 0.11, 0.8)
    search:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
    search:SetFontObject(GameFontHighlightSmall)
    search:SetTextInsets(6, 6, 0, 0)
    search:SetAutoFocus(false)

    local searchPH = search:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchPH:SetPoint("LEFT", 6, 0)
    searchPH:SetText("Recherche...")
    searchPH:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -- Debounced search (wait 0.3s after last keystroke)
    local searchDebounceTimer
    search:SetScript("OnTextChanged", function(s)
        ns._ui_search = ns.Util_Lower(ns.Util_Trim(s:GetText() or ""))
        searchPH:SetShown((s:GetText() or "") == "" and not s:HasFocus())

        -- Cancel previous timer
        if searchDebounceTimer then
            searchDebounceTimer:Cancel()
        end

        -- Schedule refresh after 0.3s of no typing
        searchDebounceTimer = C_Timer.NewTimer(0.3, function()
            RefreshCurrent()
            searchDebounceTimer = nil
        end)
    end)
    search:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    search:SetScript("OnEditFocusGained", function(s)
        s:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.6)
        searchPH:Hide()
    end)
    search:SetScript("OnEditFocusLost", function(s)
        s:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
        if (s:GetText() or "") == "" then searchPH:Show() end
    end)

    -- Resize grip
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    -- Open animation: alpha fade + subtle scale pop
    local openAG = f:CreateAnimationGroup()
    local fadeA = openAG:CreateAnimation("Alpha")
    fadeA:SetFromAlpha(0)
    fadeA:SetToAlpha(1)
    fadeA:SetDuration(0.18)
    fadeA:SetSmoothing("OUT")
    local scaleA = openAG:CreateAnimation("Scale")
    scaleA:SetScaleFrom(0.97, 0.97)
    scaleA:SetScaleTo(1, 1)
    scaleA:SetDuration(0.18)
    scaleA:SetSmoothing("OUT")
    scaleA:SetOrigin("CENTER", 0, 0)
    f:SetScript("OnShow", function() openAG:Play() end)

    -- ESC to close
    tinsert(UISpecialFrames, "CelestialRecruiterFrame")

    UI.mainFrame = f
    return f
end

---------------------------------------------------------------------------
-- Tab Bar
---------------------------------------------------------------------------
local function CreateTabs(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(34)
    bar:SetPoint("TOPLEFT", 4, -42)
    bar:SetPoint("TOPRIGHT", -4, -42)

    -- Bottom separator
    local sep = bar:CreateTexture(nil, "ARTWORK")
    sep:SetTexture(SOLID)
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT")
    sep:SetPoint("BOTTOMRIGHT")
    sep:SetVertexColor(C.border[1], C.border[2], C.border[3], 0.35)

    -- Active indicator line (animated sliding)
    tabIndicator = CreateFrame("Frame", nil, bar)
    tabIndicator:SetHeight(2)
    tabIndicator:SetPoint("BOTTOMLEFT", 8, -2)
    tabIndicator:SetWidth(60)
    tabIndicator._tex = tabIndicator:CreateTexture(nil, "OVERLAY")
    tabIndicator._tex:SetTexture(SOLID)
    tabIndicator._tex:SetAllPoints()
    tabIndicator._tex:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    -- Glow under the indicator
    tabIndicator._glow = tabIndicator:CreateTexture(nil, "ARTWORK")
    tabIndicator._glow:SetTexture(SOLID)
    tabIndicator._glow:SetPoint("TOPLEFT", -2, 2)
    tabIndicator._glow:SetPoint("BOTTOMRIGHT", 2, -2)
    tabIndicator._glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.12)
    -- Lerp state
    tabIndicator._curX = 8
    tabIndicator._curW = 60
    tabIndicator._tgtX = 8
    tabIndicator._tgtW = 60
    tabIndicator:SetScript("OnUpdate", function(self)
        local lf = 0.20
        local dx = math.abs(self._tgtX - self._curX)
        local dw = math.abs(self._tgtW - self._curW)
        if dx < 0.5 and dw < 0.5 then
            self._curX = self._tgtX
            self._curW = self._tgtW
        else
            self._curX = self._curX + (self._tgtX - self._curX) * lf
            self._curW = self._curW + (self._tgtW - self._curW) * lf
        end
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", self._curX, -2)
        self:SetWidth(math.max(1, self._curW))
    end)

    local xOff = 8
    for _, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, bar, "BackdropTemplate")
        btn:SetHeight(30)
        btn:SetPoint("BOTTOMLEFT", xOff, 2)
        btn:SetBackdrop({bgFile = SOLID})
        btn:SetBackdropColor(0, 0, 0, 0)

        btn.t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.t:SetPoint("LEFT", 10, 0)
        btn.t:SetText(tab.label)
        btn.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        -- Badge (count number) with pulse animation when > 0
        btn.badge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.badge:SetPoint("LEFT", btn.t, "RIGHT", 4, 0)
        btn.badge:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
        btn.badge:SetText("")

        -- Badge pulse animation
        btn.badgePulse = btn.badge:CreateAnimationGroup()
        btn.badgePulse:SetLooping("BOUNCE")
        local bp = btn.badgePulse:CreateAnimation("Scale")
        bp:SetScaleFrom(1, 1)
        bp:SetScaleTo(1.2, 1.2)
        bp:SetDuration(0.8)
        bp:SetSmoothing("IN_OUT")
        bp:SetOrigin("LEFT", 0, 0)

        local tw = btn.t:GetStringWidth() + 28
        btn:SetWidth(tw)
        btn._key = tab.key

        -- Smooth background transition on hover/click
        btn._bgAnim = btn:CreateAnimationGroup()
        local bgFade = btn._bgAnim:CreateAnimation("Alpha")
        bgFade:SetDuration(0.15)
        bgFade:SetSmoothing("OUT")

        btn:SetScript("OnClick", function()
            -- Quick click feedback
            btn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.20)
            C_Timer.After(0.08, function()
                if UI.active == btn._key then
                    btn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.10)
                else
                    btn:SetBackdropColor(0, 0, 0, 0)
                end
            end)
            SwitchTab(tab.key)
        end)
        btn:SetScript("OnEnter", function(s)
            if UI.active ~= s._key then
                s:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
                s.t:SetTextColor(C.text[1], C.text[2], C.text[3], 0.85)
            end
        end)
        btn:SetScript("OnLeave", function(s)
            if UI.active ~= s._key then
                s:SetBackdropColor(0, 0, 0, 0)
                s.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            end
        end)

        tabBtns[tab.key] = btn
        xOff = xOff + tw + 2
    end
end

---------------------------------------------------------------------------
-- Content Panels (one per tab, hidden/shown with fade transitions)
---------------------------------------------------------------------------
local function CreateContent(parent)
    for _, tab in ipairs(TABS) do
        local panel = CreateFrame("Frame", nil, parent)
        panel:SetPoint("TOPLEFT", 4, -78)
        panel:SetPoint("BOTTOMRIGHT", -4, 30)
        panel:SetAlpha(0)
        panel:Hide()

        -- Fade in/out animations for smooth transitions
        panel._fadeIn = panel:CreateAnimationGroup()
        local fadeIn = panel._fadeIn:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.15)
        fadeIn:SetSmoothing("OUT")

        panel._fadeOut = panel:CreateAnimationGroup()
        local fadeOut = panel._fadeOut:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.12)
        fadeOut:SetSmoothing("IN")
        panel._fadeOut:SetScript("OnFinished", function()
            panel:Hide()
        end)

        tabPanels[tab.key] = panel
    end

    -- Build each tab's content once
    ns.UI_BuildScanner(tabPanels.Scanner)
    ns.UI_BuildQueue(tabPanels.Queue)
    ns.UI_BuildInbox(tabPanels.Inbox)
    ns.UI_BuildSettings(tabPanels.Settings)
    ns.UI_BuildLogs(tabPanels.Logs)
    ns.UI_BuildHelp(tabPanels.Help)
end

---------------------------------------------------------------------------
-- Status Bar
---------------------------------------------------------------------------
local function CreateStatusBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(26)
    bar:SetPoint("BOTTOMLEFT", 6, 4)
    bar:SetPoint("BOTTOMRIGHT", -6, 4)
    bar:EnableMouse(true)

    -- Top separator gradient (transparent → accent → transparent)
    local sepL = bar:CreateTexture(nil, "OVERLAY")
    sepL:SetTexture(SOLID)
    sepL:SetHeight(1)
    sepL:SetPoint("TOPLEFT")
    sepL:SetPoint("TOP")
    sepL:SetGradient("HORIZONTAL", CreateColor(C.border[1], C.border[2], C.border[3], 0.05), CreateColor(C.accent[1], C.accent[2], C.accent[3], 0.30))
    local sepR = bar:CreateTexture(nil, "OVERLAY")
    sepR:SetTexture(SOLID)
    sepR:SetHeight(1)
    sepR:SetPoint("TOP")
    sepR:SetPoint("TOPRIGHT")
    sepR:SetGradient("HORIZONTAL", CreateColor(C.accent[1], C.accent[2], C.accent[3], 0.30), CreateColor(C.border[1], C.border[2], C.border[3], 0.05))

    UI.statsText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    UI.statsText:SetPoint("LEFT", 4, -2)
    UI.statsText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Session stats (right side of status bar)
    UI.sessionText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    UI.sessionText:SetPoint("RIGHT", -4, -2)
    UI.sessionText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -- Detailed session stats tooltip on hover
    bar:SetScript("OnEnter", function(self)
        local ss = ns.sessionStats
        if not ss then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Statistiques de session")
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Session demarree:", ns.Util_FormatAgo(ss.startedAt), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Scans lances:", tostring(ss.scansStarted), C.dim[1], C.dim[2], C.dim[3], C.accent[1], C.accent[2], C.accent[3])
        GameTooltip:AddDoubleLine("Joueurs trouves:", tostring(ss.playersFound), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Ajoutes en file:", tostring(ss.queueAdded), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Invitations envoyees:", tostring(ss.invitesSent), C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
        GameTooltip:AddDoubleLine("Messages envoyes:", tostring(ss.whispersSent), C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
        GameTooltip:AddDoubleLine("Recrues rejointes:", tostring(ss.recruitsJoined), C.dim[1], C.dim[2], C.dim[3], C.gold[1], C.gold[2], C.gold[3])
        GameTooltip:AddLine(" ")
        -- Total recruits (all time, from contacts with status "joined")
        local totalJoined = 0
        for _, c in pairs(ns.db.global.contacts) do
            if c and c.status == "joined" then totalJoined = totalJoined + 1 end
        end
        GameTooltip:AddLine("Contacts: " .. W.countKeys(ns.db.global.contacts), C.dim[1], C.dim[2], C.dim[3])
        GameTooltip:AddDoubleLine("Recrues (total):", tostring(totalJoined), C.dim[1], C.dim[2], C.dim[3], C.gold[1], C.gold[2], C.gold[3])
        GameTooltip:AddLine("Blacklist: " .. W.countKeys(ns.db.global.blacklist), C.dim[1], C.dim[2], C.dim[3])
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- Tab Switching (with smooth fade transitions)
---------------------------------------------------------------------------
SwitchTab = function(tabKey)
    local previousTab = UI.active
    UI.active = tabKey

    -- Fade out previous panel, fade in new panel
    for key, panel in pairs(tabPanels) do
        if key == previousTab and key ~= tabKey and panel:IsShown() then
            -- Fade out previous tab
            panel._fadeOut:Play()
        elseif key == tabKey then
            -- Fade in new tab
            panel:Show()
            panel._fadeIn:Play()
        end
    end

    -- Update button visual state with smooth transitions + animated indicator target
    for key, btn in pairs(tabBtns) do
        if key == tabKey then
            btn.t:SetTextColor(C.text[1], C.text[2], C.text[3])
            btn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.10)
            -- Calculate position relative to the tab bar
            local bar = btn:GetParent()
            if bar and btn:GetLeft() and bar:GetLeft() then
                local relX = btn:GetLeft() - bar:GetLeft() + 4
                local w = btn:GetWidth() - 8
                tabIndicator._tgtX = relX
                tabIndicator._tgtW = math.max(1, w)
            end
        else
            btn.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            btn:SetBackdropColor(0, 0, 0, 0)
        end
    end

    RefreshCurrent()
end

---------------------------------------------------------------------------
-- Refresh Helpers
---------------------------------------------------------------------------
local refreshFuncs = {
    Scanner  = function() ns.UI_RefreshScanner()  end,
    Queue    = function() ns.UI_RefreshQueue()    end,
    Inbox    = function() ns.UI_RefreshInbox()    end,
    Settings = function() ns.UI_RefreshSettings() end,
    Logs     = function() ns.UI_RefreshLogs()     end,
    Help     = function() ns.UI_RefreshHelp()     end,
}

UpdateStatusBar = function()
    if not UI.statsText then return end
    local contacts = W.countKeys(ns.db.global.contacts)
    local queue    = #ns.DB_QueueList()
    local bl       = W.countKeys(ns.db.global.blacklist)
    local blColor  = bl > 0 and "ff6b6b" or "5c5f6a"
    UI.statsText:SetText(
        ("Contacts: |cff00aaff%d|r   |cff3a3d48|||r   File: |cffFFD700%d|r   |cff3a3d48|||r   Blacklist: |cff%s%d|r"):format(
            contacts, queue, blColor, bl
        )
    )
    -- Session stats summary (right side, green highlights)
    if UI.sessionText and ns.sessionStats then
        local ss = ns.sessionStats
        local joinStr = ss.recruitsJoined > 0
            and (", |cffFFD700" .. ss.recruitsJoined .. "|r recrues") or ""
        UI.sessionText:SetText(
            ("Session: |cff33e07a%d|r inv, |cff33e07a%d|r msg, |cff00aaff%d|r trouves%s"):format(
                ss.invitesSent, ss.whispersSent, ss.playersFound, joinStr
            )
        )
    end
    if ns.Minimap_UpdateBadge then ns.Minimap_UpdateBadge() end
end

UpdateBadges = function()
    for _, tab in ipairs(TABS) do
        local btn = tabBtns[tab.key]
        if btn and tab.badge then
            local text = tab.badge() or ""
            local hadBadge = btn.badge:GetText() ~= ""
            btn.badge:SetText(text)

            -- Pulse animation when badge appears or changes to non-zero
            if text ~= "" and not hadBadge then
                if btn.badgePulse then
                    btn.badgePulse:Play()
                end
            elseif text == "" and btn.badgePulse then
                btn.badgePulse:Stop()
            end

            local base  = btn.t:GetStringWidth() + 28
            local extra = text ~= "" and (btn.badge:GetStringWidth() + 6) or 0
            btn:SetWidth(base + extra)
        end
    end
end

RefreshCurrent = function()
    local fn = refreshFuncs[UI.active]
    if fn then fn() end
    UpdateStatusBar()
    UpdateBadges()
end

---------------------------------------------------------------------------
-- Scanner auto-refresh ticker (updates cooldown/awaiting state)
---------------------------------------------------------------------------
local scanTicker

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function ns.UI_Init()
    if UI.mainFrame then return end

    local f = CreateMainFrame()
    CreateTabs(f)
    CreateContent(f)
    CreateStatusBar(f)
    f:Hide()

    -- Default to Scanner tab
    SwitchTab("Scanner")

    -- Tick every 0.5s: update UI state (cooldown, awaiting)
    local lastTickState = ""
    scanTicker = C_Timer.NewTicker(0.5, function()
        local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}

        if not UI.mainFrame or not UI.mainFrame:IsShown() then return end
        if UI.active ~= "Scanner" then return end
        if st.awaiting or ((st.cooldownRemaining or 0) > 0) or st.scanning then
            local stateKey = (st.scanning and "1" or "0")
                .. (st.awaiting and "1" or "0")
                .. tostring(math.floor((st.cooldownRemaining or 0) + 0.5))
                .. tostring(st.querySent or 0)
            if stateKey ~= lastTickState then
                lastTickState = stateKey
                RefreshCurrent()
            end
        else
            lastTickState = ""
        end
    end)
end

function ns.UI_Toggle()
    if not UI.mainFrame then return end
    if UI.mainFrame:IsShown() then
        UI.mainFrame:Hide()
    else
        UI.mainFrame:Show()
        RefreshCurrent()
    end
end

function ns.UI_Refresh()
    if not UI.mainFrame or not UI.mainFrame:IsShown() then return end
    RefreshCurrent()
end

-- Public API for tab switching (for keybinds)
function ns.UI_SwitchTab(tabKey)
    if not UI.mainFrame then return end
    SwitchTab(tabKey)
end
