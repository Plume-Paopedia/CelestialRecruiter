local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local SOLID = W.SOLID
local EDGE  = W.EDGE

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Main UI Frame, Tabs, Status Bar & Public API
-- Enhanced with animations and micro-interactions
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
    {key = "Scanner",   label = "|TInterface\\Icons\\INV_Misc_Spyglass_03:14:14:0:0|t |cff00aaffScanner|r",    badge = ns.UI_ScannerBadge, tip = "Recherche de joueurs via /who."},
    {key = "Queue",     label = "|TInterface\\Icons\\Spell_ChargePositive:14:14:0:0|t |cffFFD700File d'attente|r", badge = ns.UI_QueueBadge, tip = "Joueurs en attente de recrutement."},
    {key = "Inbox",     label = "|TInterface\\Icons\\INV_Letter_15:14:14:0:0|t |cff33e07aBoite|r",       badge = ns.UI_InboxBadge, tip = "Messages recus et conversations."},
    {key = "Analytics", label = "|TInterface\\Icons\\INV_Misc_StoneTablet_05:14:14:0:0|t |cffFF69B4Analytiques|r",  badge = ns.UI_AnalyticsBadge, tip = "Statistiques et objectifs de recrutement."},
    {key = "Settings",  label = "|TInterface\\Icons\\Trade_Engineering:14:14:0:0|t |cff888888Reglages|r", tip = "Configuration de l'addon."},
    {key = "Logs",      label = "|TInterface\\Icons\\INV_Misc_Book_09:14:14:0:0|t |cff888888Journaux|r", tip = "Journal des actions effectuees."},
    {key = "Help",      label = "|TInterface\\Icons\\INV_Misc_QuestionMark:14:14:0:0|t |cff888888Aide|r", tip = "Guide d'utilisation et commandes."},
}

local tabBtns    = {}
local tabPanels  = {}
local tabIndicator

---------------------------------------------------------------------------
-- Forward declarations
---------------------------------------------------------------------------
local SwitchTab, RefreshCurrent, UpdateStatusBar, UpdateBadges

---------------------------------------------------------------------------
-- Animation Helper: Smooth color lerp via OnUpdate
-- Drives border/backdrop color transitions over time for any frame.
---------------------------------------------------------------------------
local function StartColorLerp(frame, setFunc, fromR, fromG, fromB, fromA, toR, toG, toB, toA, duration)
    frame._colorLerp = {
        elapsed  = 0,
        duration = duration,
        fromR = fromR, fromG = fromG, fromB = fromB, fromA = fromA,
        toR = toR, toG = toG, toB = toB, toA = toA,
        setFunc = setFunc,
    }
    if not frame._colorLerpHooked then
        frame._colorLerpHooked = true
        local origOnUpdate = frame:GetScript("OnUpdate")
        frame:SetScript("OnUpdate", function(self, elapsed)
            if origOnUpdate then origOnUpdate(self, elapsed) end
            local cl = self._colorLerp
            if not cl then return end
            cl.elapsed = cl.elapsed + elapsed
            local t = math.min(1, cl.elapsed / cl.duration)
            -- Smooth ease-out
            local s = 1 - (1 - t) * (1 - t)
            local r = cl.fromR + (cl.toR - cl.fromR) * s
            local g = cl.fromG + (cl.toG - cl.fromG) * s
            local b = cl.fromB + (cl.toB - cl.fromB) * s
            local a = cl.fromA + (cl.toA - cl.fromA) * s
            cl.setFunc(self, r, g, b, a)
            if t >= 1 then
                self._colorLerp = nil
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Animation Helper: Tab hover color lerp (separate from the above so
-- both can coexist on the same button frame without conflicting)
---------------------------------------------------------------------------
local function SetupTabHoverLerp(btn)
    btn._hoverColor = {r = C.dim[1], g = C.dim[2], b = C.dim[3], a = 1}
    btn._hoverTarget = {r = C.dim[1], g = C.dim[2], b = C.dim[3], a = 1}
    btn._bgColor = {r = 0, g = 0, b = 0, a = 0}
    btn._bgTarget = {r = 0, g = 0, b = 0, a = 0}

    btn:SetScript("OnUpdate", function(self, elapsed)
        local speed = 8 * elapsed
        -- Lerp text color
        local hc, ht = self._hoverColor, self._hoverTarget
        local changed = false
        if math.abs(hc.r - ht.r) > 0.002 or math.abs(hc.g - ht.g) > 0.002
            or math.abs(hc.b - ht.b) > 0.002 or math.abs(hc.a - ht.a) > 0.002 then
            hc.r = hc.r + (ht.r - hc.r) * speed
            hc.g = hc.g + (ht.g - hc.g) * speed
            hc.b = hc.b + (ht.b - hc.b) * speed
            hc.a = hc.a + (ht.a - hc.a) * speed
            self.t:SetTextColor(hc.r, hc.g, hc.b, hc.a)
            changed = true
        end
        -- Lerp backdrop color
        local bc, bt = self._bgColor, self._bgTarget
        if math.abs(bc.r - bt.r) > 0.002 or math.abs(bc.g - bt.g) > 0.002
            or math.abs(bc.b - bt.b) > 0.002 or math.abs(bc.a - bt.a) > 0.002 then
            bc.r = bc.r + (bt.r - bc.r) * speed
            bc.g = bc.g + (bt.g - bc.g) * speed
            bc.b = bc.b + (bt.b - bc.b) * speed
            bc.a = bc.a + (bt.a - bc.a) * speed
            self:SetBackdropColor(bc.r, bc.g, bc.b, bc.a)
            changed = true
        end
        -- Snap when close enough
        if not changed then
            hc.r, hc.g, hc.b, hc.a = ht.r, ht.g, ht.b, ht.a
            bc.r, bc.g, bc.b, bc.a = bt.r, bt.g, bt.b, bt.a
            self.t:SetTextColor(ht.r, ht.g, ht.b, ht.a)
            self:SetBackdropColor(bt.r, bt.g, bt.b, bt.a)
        end
    end)
end

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

    -- === Enhancement #4a: Accent gradient line below title bar ===
    -- A 1px gradient line that fades from accent color (left) to transparent (right)
    local titleAccentLine = titleBar:CreateTexture(nil, "OVERLAY")
    titleAccentLine:SetTexture(SOLID)
    titleAccentLine:SetHeight(1)
    titleAccentLine:SetPoint("BOTTOMLEFT", 0, -1)
    titleAccentLine:SetPoint("BOTTOMRIGHT", 0, -1)
    titleAccentLine:SetGradient("HORIZONTAL",
        CreateColor(C.accent[1], C.accent[2], C.accent[3], 0.45),
        CreateColor(C.accent[1], C.accent[2], C.accent[3], 0.0))

    -- Original accent line under title bar (slightly above the gradient one)
    local titleLine = titleBar:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture(SOLID)
    titleLine:SetHeight(1)
    titleLine:SetPoint("BOTTOMLEFT", 0, 0)
    titleLine:SetPoint("BOTTOMRIGHT", 0, 0)
    titleLine:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.20)

    -- Gold star with gentle pulse
    local star = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    star:SetPoint("LEFT", 8, 0)
    star:SetText("|TInterface\\Icons\\INV_Jewelry_Ring_03:16:16:0:0|t")
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
    ver:SetText("v3.4.0")
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
    closeBtn:SetScript("OnClick", function()
        -- Trigger close animation instead of immediate hide
        if f._closeAnim and not f._closeAnim:IsPlaying() then
            f._closeAnim:Play()
        else
            f:Hide()
        end
    end)
    W.AddTooltip(closeBtn, "Fermer", "Fermer la fenetre CelestialRecruiter.")

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

    -- === Enhancement #4b: Search box focus glow texture ===
    local searchGlow = search:CreateTexture(nil, "BACKGROUND")
    searchGlow:SetTexture(SOLID)
    searchGlow:SetPoint("TOPLEFT", -1, 1)
    searchGlow:SetPoint("BOTTOMRIGHT", 1, -1)
    searchGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)

    W.AddTooltip(search, "Recherche", "Filtrer les resultats de l'onglet actif par nom.")

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

    -- === Enhancement #4b: Smooth search focus border transition ===
    search:SetScript("OnEditFocusGained", function(s)
        -- Animate border from default to accent color
        StartColorLerp(s,
            function(self, r, g, b, a) self:SetBackdropBorderColor(r, g, b, a) end,
            C.border[1], C.border[2], C.border[3], 0.4,
            C.accent[1], C.accent[2], C.accent[3], 0.7,
            0.2)
        -- Animate glow appearance
        searchGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
        searchPH:Hide()
    end)
    search:SetScript("OnEditFocusLost", function(s)
        -- Animate border from accent back to default
        StartColorLerp(s,
            function(self, r, g, b, a) self:SetBackdropBorderColor(r, g, b, a) end,
            C.accent[1], C.accent[2], C.accent[3], 0.7,
            C.border[1], C.border[2], C.border[3], 0.4,
            0.25)
        -- Fade glow out
        searchGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
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

    -- === Enhancement #1: Frame Open Animation ===
    -- Scale from 0.95 to 1.0 + fade from 0 to 1 (0.2s, OUT easing)
    local openAG = f:CreateAnimationGroup()
    local openFade = openAG:CreateAnimation("Alpha")
    openFade:SetFromAlpha(0)
    openFade:SetToAlpha(1)
    openFade:SetDuration(0.2)
    openFade:SetSmoothing("OUT")
    local openScale = openAG:CreateAnimation("Scale")
    openScale:SetScaleFrom(0.95, 0.95)
    openScale:SetScaleTo(1, 1)
    openScale:SetDuration(0.2)
    openScale:SetSmoothing("OUT")
    openScale:SetOrigin("CENTER", 0, 0)
    openAG:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)
    f._openAnim = openAG

    -- === Enhancement #1: Frame Close Animation ===
    -- Scale from 1.0 to 0.95 + fade from 1 to 0 (0.15s, IN easing)
    local closeAG = f:CreateAnimationGroup()
    local closeFade = closeAG:CreateAnimation("Alpha")
    closeFade:SetFromAlpha(1)
    closeFade:SetToAlpha(0)
    closeFade:SetDuration(0.15)
    closeFade:SetSmoothing("IN")
    local closeScale = closeAG:CreateAnimation("Scale")
    closeScale:SetScaleFrom(1, 1)
    closeScale:SetScaleTo(0.95, 0.95)
    closeScale:SetDuration(0.15)
    closeScale:SetSmoothing("IN")
    closeScale:SetOrigin("CENTER", 0, 0)
    closeAG:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        -- Reset alpha for next show
        f:SetAlpha(1)
    end)
    f._closeAnim = closeAG

    f:SetScript("OnShow", function()
        -- Stop close animation if it was playing (e.g., rapid toggle)
        if f._closeAnim:IsPlaying() then
            f._closeAnim:Stop()
        end
        f:SetAlpha(0)
        f._openAnim:Play()
    end)

    -- ESC to close (integrates with close animation)
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

    -- === Enhancement #2c: Active indicator line (animated sliding) ===
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
    local function tabIndicatorLerp(self, elapsed)
        local lf = 0.20
        local dx = math.abs(self._tgtX - self._curX)
        local dw = math.abs(self._tgtW - self._curW)
        if dx < 0.5 and dw < 0.5 then
            self._curX = self._tgtX
            self._curW = self._tgtW
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", self._curX, -2)
            self:SetWidth(math.max(1, self._curW))
            self:SetScript("OnUpdate", nil)
            return
        end
        self._curX = self._curX + (self._tgtX - self._curX) * lf
        self._curW = self._curW + (self._tgtW - self._curW) * lf
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", self._curX, -2)
        self:SetWidth(math.max(1, self._curW))
    end
    tabIndicator._lerpFn = tabIndicatorLerp
    tabIndicator:SetScript("OnUpdate", tabIndicatorLerp)

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
        btn._lastBadgeText = ""

        -- === Enhancement #3: Badge pulse animation (bounces on count change) ===
        btn.badgePulse = btn.badge:CreateAnimationGroup()
        btn.badgePulse:SetLooping("BOUNCE")
        local bp = btn.badgePulse:CreateAnimation("Scale")
        bp:SetScaleFrom(1, 1)
        bp:SetScaleTo(1.2, 1.2)
        bp:SetDuration(0.8)
        bp:SetSmoothing("IN_OUT")
        bp:SetOrigin("LEFT", 0, 0)

        -- === Enhancement #3: Badge pop animation (plays once on count change) ===
        btn.badgePop = btn.badge:CreateAnimationGroup()
        local popScale = btn.badgePop:CreateAnimation("Scale")
        popScale:SetScaleFrom(1.4, 1.4)
        popScale:SetScaleTo(1, 1)
        popScale:SetDuration(0.25)
        popScale:SetSmoothing("OUT")
        popScale:SetOrigin("LEFT", 0, 0)
        local popAlpha = btn.badgePop:CreateAnimation("Alpha")
        popAlpha:SetFromAlpha(0.5)
        popAlpha:SetToAlpha(1)
        popAlpha:SetDuration(0.25)
        popAlpha:SetSmoothing("OUT")
        btn.badgePop:SetScript("OnFinished", function()
            btn.badge:SetAlpha(1)
        end)

        -- === Enhancement #3: Badge glow texture (accent-colored halo) ===
        btn.badgeGlow = btn:CreateTexture(nil, "ARTWORK")
        btn.badgeGlow:SetTexture(SOLID)
        btn.badgeGlow:SetSize(28, 16)
        btn.badgeGlow:SetPoint("CENTER", btn.badge, "CENTER", 0, 0)
        btn.badgeGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
        -- Badge glow pulse animation
        btn.badgeGlowAnim = btn.badgeGlow:CreateAnimationGroup()
        btn.badgeGlowAnim:SetLooping("BOUNCE")
        local glowAlpha = btn.badgeGlowAnim:CreateAnimation("Alpha")
        glowAlpha:SetFromAlpha(0)
        glowAlpha:SetToAlpha(0.25)
        glowAlpha:SetDuration(0.6)
        glowAlpha:SetSmoothing("IN_OUT")

        local tw = btn.t:GetStringWidth() + 28
        btn:SetWidth(tw)
        btn._key = tab.key

        -- === Enhancement #2b: Smooth tab hover color transitions ===
        SetupTabHoverLerp(btn)

        btn:SetScript("OnClick", function()
            -- Quick click feedback
            btn._bgTarget.r = C.accent[1]
            btn._bgTarget.g = C.accent[2]
            btn._bgTarget.b = C.accent[3]
            btn._bgTarget.a = 0.20
            C_Timer.After(0.08, function()
                if UI.active == btn._key then
                    btn._bgTarget.r = C.accent[1]
                    btn._bgTarget.g = C.accent[2]
                    btn._bgTarget.b = C.accent[3]
                    btn._bgTarget.a = 0.10
                else
                    btn._bgTarget.r = 0
                    btn._bgTarget.g = 0
                    btn._bgTarget.b = 0
                    btn._bgTarget.a = 0
                end
            end)
            SwitchTab(tab.key)
        end)
        btn:SetScript("OnEnter", function(s)
            if UI.active ~= s._key then
                s._bgTarget.r = C.accent[1]
                s._bgTarget.g = C.accent[2]
                s._bgTarget.b = C.accent[3]
                s._bgTarget.a = 0.08
                s._hoverTarget.r = C.text[1]
                s._hoverTarget.g = C.text[2]
                s._hoverTarget.b = C.text[3]
                s._hoverTarget.a = 0.85
            end
        end)
        btn:SetScript("OnLeave", function(s)
            if UI.active ~= s._key then
                s._bgTarget.r = 0
                s._bgTarget.g = 0
                s._bgTarget.b = 0
                s._bgTarget.a = 0
                s._hoverTarget.r = C.dim[1]
                s._hoverTarget.g = C.dim[2]
                s._hoverTarget.b = C.dim[3]
                s._hoverTarget.a = 1
            end
        end)

        if tab.tip then
            W.AddTooltip(btn, tab.key, tab.tip)
        end

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
        panel._fadeIn:SetScript("OnFinished", function()
            panel:SetAlpha(1)
        end)

        panel._fadeOut = panel:CreateAnimationGroup()
        local fadeOut = panel._fadeOut:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.12)
        fadeOut:SetSmoothing("IN")
        panel._fadeOut:SetScript("OnFinished", function()
            panel:SetAlpha(0)
            panel:Hide()
        end)

        -- === Enhancement #5: Smooth content refresh animation ===
        -- Fades to 0.7 then back to 1.0 for a "refreshing" visual pulse
        panel._refreshDim = panel:CreateAnimationGroup()
        local dimAlpha = panel._refreshDim:CreateAnimation("Alpha")
        dimAlpha:SetFromAlpha(1)
        dimAlpha:SetToAlpha(0.7)
        dimAlpha:SetDuration(0.08)
        dimAlpha:SetSmoothing("IN")
        dimAlpha:SetOrder(1)
        local brightAlpha = panel._refreshDim:CreateAnimation("Alpha")
        brightAlpha:SetFromAlpha(0.7)
        brightAlpha:SetToAlpha(1)
        brightAlpha:SetDuration(0.15)
        brightAlpha:SetSmoothing("OUT")
        brightAlpha:SetOrder(2)
        panel._refreshDim:SetScript("OnFinished", function()
            panel:SetAlpha(1)
        end)

        tabPanels[tab.key] = panel
    end

    -- Build each tab's content once
    ns.UI_BuildScanner(tabPanels.Scanner)
    ns.UI_BuildQueue(tabPanels.Queue)
    ns.UI_BuildInbox(tabPanels.Inbox)
    ns.UI_BuildAnalytics(tabPanels.Analytics)
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

    -- Top separator gradient (transparent -> accent -> transparent)
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
        GameTooltip:AddDoubleLine("Session demarree :", ns.Util_FormatAgo(ss.startedAt), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Scans lances :", tostring(ss.scansStarted), C.dim[1], C.dim[2], C.dim[3], C.accent[1], C.accent[2], C.accent[3])
        GameTooltip:AddDoubleLine("Joueurs trouves :", tostring(ss.playersFound), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Ajoutes en file :", tostring(ss.queueAdded), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        GameTooltip:AddDoubleLine("Invitations envoyees :", tostring(ss.invitesSent), C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
        GameTooltip:AddDoubleLine("Messages envoyes :", tostring(ss.whispersSent), C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
        GameTooltip:AddDoubleLine("Nouvelles recrues :", tostring(ss.recruitsJoined), C.dim[1], C.dim[2], C.dim[3], C.gold[1], C.gold[2], C.gold[3])
        GameTooltip:AddLine(" ")
        -- Total recruits (all time, from contacts with status "joined")
        local totalJoined = 0
        for _, c in pairs(ns.db.global.contacts or {}) do
            if c and c.status == "joined" then totalJoined = totalJoined + 1 end
        end
        GameTooltip:AddLine("Contacts : " .. W.countKeys(ns.db.global.contacts), C.dim[1], C.dim[2], C.dim[3])
        GameTooltip:AddDoubleLine("Recrues (total) :", tostring(totalJoined), C.dim[1], C.dim[2], C.dim[3], C.gold[1], C.gold[2], C.gold[3])
        GameTooltip:AddLine("Blacklist : " .. W.countKeys(ns.db.global.blacklist), C.dim[1], C.dim[2], C.dim[3])
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

    -- Mark this as a tab switch so RefreshCurrent plays the refresh animation
    UI._isTabSwitch = true

    -- Fade out previous panel, fade in new panel
    for key, panel in pairs(tabPanels) do
        if key == previousTab and key ~= tabKey and panel:IsShown() then
            -- Stop any ongoing animations before starting fade out
            panel._fadeIn:Stop()
            panel._fadeOut:Stop()
            if panel._refreshDim:IsPlaying() then panel._refreshDim:Stop() end
            -- Fade out previous tab
            panel._fadeOut:Play()
        elseif key == tabKey then
            -- Stop any ongoing animations before starting fade in
            panel._fadeIn:Stop()
            panel._fadeOut:Stop()
            if panel._refreshDim:IsPlaying() then panel._refreshDim:Stop() end
            -- Ensure alpha is reset before showing
            panel:SetAlpha(0)
            -- Fade in new tab
            panel:Show()
            panel._fadeIn:Play()
        end
    end

    -- Update button visual state with smooth transitions + animated indicator target
    for key, btn in pairs(tabBtns) do
        if key == tabKey then
            -- Set lerp targets for active tab
            btn._hoverTarget.r = C.text[1]
            btn._hoverTarget.g = C.text[2]
            btn._hoverTarget.b = C.text[3]
            btn._hoverTarget.a = 1
            btn._bgTarget.r = C.accent[1]
            btn._bgTarget.g = C.accent[2]
            btn._bgTarget.b = C.accent[3]
            btn._bgTarget.a = 0.10
            -- Calculate position relative to the tab bar
            local bar = btn:GetParent()
            if bar and btn:GetLeft() and bar:GetLeft() then
                local relX = btn:GetLeft() - bar:GetLeft() + 4
                local w = btn:GetWidth() - 8
                tabIndicator._tgtX = relX
                tabIndicator._tgtW = math.max(1, w)
                -- Restart lerp if stopped
                if not tabIndicator:GetScript("OnUpdate") then
                    tabIndicator:SetScript("OnUpdate", tabIndicator._lerpFn)
                end
            end
        else
            -- Set lerp targets for inactive tabs
            btn._hoverTarget.r = C.dim[1]
            btn._hoverTarget.g = C.dim[2]
            btn._hoverTarget.b = C.dim[3]
            btn._hoverTarget.a = 1
            btn._bgTarget.r = 0
            btn._bgTarget.g = 0
            btn._bgTarget.b = 0
            btn._bgTarget.a = 0
        end
    end

    RefreshCurrent()
    UI._isTabSwitch = false
end

---------------------------------------------------------------------------
-- Refresh Helpers
---------------------------------------------------------------------------
local refreshFuncs = {
    Scanner   = function() ns.UI_RefreshScanner()   end,
    Queue     = function() ns.UI_RefreshQueue()     end,
    Inbox     = function() ns.UI_RefreshInbox()     end,
    Analytics = function() ns.UI_RefreshAnalytics() end,
    Settings  = function() ns.UI_RefreshSettings()  end,
    Logs      = function() ns.UI_RefreshLogs()      end,
    Help      = function() ns.UI_RefreshHelp()      end,
}

UpdateStatusBar = function()
    if not UI.statsText then return end
    local contacts = W.countKeys(ns.db.global.contacts)
    local queue    = ns.DB_QueueCount and ns.DB_QueueCount() or #ns.DB_QueueList()
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
            local prevText = btn._lastBadgeText or ""
            btn.badge:SetText(text)

            -- === Enhancement #3: Animated badge behavior ===
            if text ~= "" then
                if prevText == "" then
                    -- Badge just appeared: start pulsing + play pop + start glow
                    if btn.badgePulse and not btn.badgePulse:IsPlaying() then
                        btn.badgePulse:Play()
                    end
                    if btn.badgePop then
                        btn.badgePop:Play()
                    end
                    -- Start glow animation for new notification
                    if btn.badgeGlowAnim and not btn.badgeGlowAnim:IsPlaying() then
                        btn.badgeGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
                        btn.badgeGlowAnim:Play()
                    end
                elseif text ~= prevText then
                    -- Count changed: play pop animation to draw attention
                    if btn.badgePop then
                        btn.badge:SetAlpha(1)
                        btn.badgePop:Play()
                    end
                    -- Refresh glow
                    if btn.badgeGlowAnim then
                        btn.badgeGlowAnim:Stop()
                        btn.badgeGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
                        btn.badgeGlowAnim:Play()
                    end
                end
            else
                -- Badge gone: stop all badge animations
                if btn.badgePulse and btn.badgePulse:IsPlaying() then
                    btn.badgePulse:Stop()
                end
                if btn.badgeGlowAnim and btn.badgeGlowAnim:IsPlaying() then
                    btn.badgeGlowAnim:Stop()
                    btn.badgeGlow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
                end
            end

            btn._lastBadgeText = text

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

    -- === Enhancement #5: Play refresh dim/brighten on manual refresh or tab switch ===
    -- Only do this when explicitly triggered (tab switch or manual), not on ticker auto-refresh
    if UI._isManualRefresh or UI._isTabSwitch then
        local panel = tabPanels[UI.active]
        if panel and panel:IsShown() and panel:GetAlpha() >= 0.99 then
            if not panel._refreshDim:IsPlaying() and not panel._fadeIn:IsPlaying() then
                panel._refreshDim:Play()
            end
        end
        UI._isManualRefresh = false
    end
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
    ns._mainFrame = f

    -- Default to Scanner tab
    SwitchTab("Scanner")

    -- Tick every 0.5s: update UI state (cooldown, awaiting)
    local lastTickState = ""
    scanTicker = C_Timer.NewTicker(0.5, function()
        local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}

        if not UI.mainFrame or not UI.mainFrame:IsShown() then return end
        if UI.active ~= "Scanner" then return end
        if st.awaiting or ((st.cooldownRemaining or 0) > 0) or st.scanning or st.autoScanWaiting or st.autoScanReady then
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
        -- Use close animation instead of immediate hide
        if UI.mainFrame._closeAnim and not UI.mainFrame._closeAnim:IsPlaying() then
            UI.mainFrame._closeAnim:Play()
        else
            UI.mainFrame:Hide()
        end
    else
        UI.mainFrame:Show()
        RefreshCurrent()
    end
end

local _refreshPending = false
local _lastRefreshTime = 0
local REFRESH_THROTTLE = 0.3  -- max 1 refresh per 0.3s

function ns.UI_Refresh()
    if not UI.mainFrame or not UI.mainFrame:IsShown() then return end
    local now = GetTime and GetTime() or 0
    if (now - _lastRefreshTime) >= REFRESH_THROTTLE then
        _lastRefreshTime = now
        _refreshPending = false
        UI._isManualRefresh = true
        RefreshCurrent()
    elseif not _refreshPending then
        _refreshPending = true
        C_Timer.After(REFRESH_THROTTLE - (now - _lastRefreshTime), function()
            _refreshPending = false
            if UI.mainFrame and UI.mainFrame:IsShown() then
                _lastRefreshTime = GetTime and GetTime() or 0
                RefreshCurrent()
            end
        end)
    end
end

-- Public API for tab switching (for keybinds)
function ns.UI_SwitchTab(tabKey)
    if not UI.mainFrame then return end
    SwitchTab(tabKey)
end
