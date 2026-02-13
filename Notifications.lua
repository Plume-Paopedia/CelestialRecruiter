local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- =====================================================================
-- CelestialRecruiter  --  Premium Toast Notification System
-- Regular toasts, celebration banners, and achievement toasts
-- with smooth animations, hover pause, sound, and stacking
-- =====================================================================

local max, min, abs = math.max, math.min, math.abs

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local TOAST_W         = 320
local TOAST_H         = 56
local TOAST_MARGIN    = 8
local MAX_TOASTS      = 5

local CELEBRATE_W     = 500
local CELEBRATE_H     = 70

local ACHIEVE_W       = 400
local ACHIEVE_H       = 60

local ANIM_IN_DUR     = 0.40   -- slide-in duration
local ANIM_OUT_DUR    = 0.30   -- slide-out duration
local ELASTIC_OVER    = 1.08   -- slight overshoot for elastic feel

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local toasts       = {}         -- active regular toasts (ordered top to bottom)
local toastPool    = {}         -- recycled regular toast frames
local celebrateFrame = nil      -- single celebration frame (reused)
local achieveFrame   = nil      -- single achievement frame (reused)

-- Forward declarations
local ReleaseToast, RepositionAll

---------------------------------------------------------------------------
-- Utility: clamp
---------------------------------------------------------------------------
local function clamp(v, lo, hi) return max(lo, min(hi, v)) end

---------------------------------------------------------------------------
-- Utility: Create a smooth timer-bar shrink via OnUpdate
-- Uses elapsed-based lerp so it looks silky at any frame rate.
---------------------------------------------------------------------------
local function AttachTimerBar(frame, barTex, fullWidth, duration)
    frame._tb_elapsed = 0
    frame._tb_duration = duration
    frame._tb_fullW = fullWidth
    frame._tb_paused = false
    barTex:SetWidth(fullWidth)
    barTex:Show()
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self._tb_paused then return end
        self._tb_elapsed = self._tb_elapsed + elapsed
        local pct = 1 - (self._tb_elapsed / self._tb_duration)
        if pct <= 0 then
            barTex:SetWidth(1)
            barTex:Hide()
            self:SetScript("OnUpdate", nil)
            return
        end
        barTex:SetWidth(max(1, self._tb_fullW * pct))
    end)
end

---------------------------------------------------------------------------
-- Utility: Create a pulsing glow animation group on a texture
-- Fades alpha between lo and hi in a loop.
---------------------------------------------------------------------------
local function MakePulse(tex, lo, hi, period)
    local ag = tex:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(lo)
    a:SetToAlpha(hi)
    a:SetDuration(period / 2)
    a:SetSmoothing("IN_OUT")
    return ag
end

-- =====================================================================
--  REGULAR TOASTS
-- =====================================================================

---------------------------------------------------------------------------
-- Create a single regular toast frame (pooled)
---------------------------------------------------------------------------
local function CreateToast()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(TOAST_W, TOAST_H)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(100)
    f:SetAlpha(0)
    f:Hide()

    -- Dark backdrop
    f:SetBackdrop({
        bgFile   = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.06, 0.07, 0.12, 0.94)
    f:SetBackdropBorderColor(0.15, 0.18, 0.28, 0.55)

    -- Left accent bar (3 px)
    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(W.SOLID)
    glow:SetWidth(3)
    glow:SetPoint("TOPLEFT", 3, -3)
    glow:SetPoint("BOTTOMLEFT", 3, 3)
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    f._glow = glow

    -- Icon glow backdrop (soft pulse on appear)
    local iconBg = f:CreateTexture(nil, "ARTWORK")
    iconBg:SetTexture(W.SOLID)
    iconBg:SetSize(28, 28)
    iconBg:SetPoint("LEFT", 11, 0)
    iconBg:SetVertexColor(0, 0, 0, 0)
    f._iconBg = iconBg
    f._iconPulse = MakePulse(iconBg, 0, 0.18, 1.6)

    -- Icon symbol
    local icon = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    icon:SetPoint("LEFT", 14, 0)
    icon:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    f._icon = icon

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 2)
    title:SetPoint("RIGHT", -28, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(C.text[1], C.text[2], C.text[3])
    f._title = title

    -- Message
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    msg:SetPoint("RIGHT", -28, 0)
    msg:SetJustifyH("LEFT")
    msg:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    f._msg = msg

    -- Timer bar (thin gradient-feel line at bottom)
    local timerBg = f:CreateTexture(nil, "ARTWORK")
    timerBg:SetTexture(W.SOLID)
    timerBg:SetHeight(2)
    timerBg:SetPoint("BOTTOMLEFT", 3, 2)
    timerBg:SetPoint("BOTTOMRIGHT", -3, 2)
    timerBg:SetVertexColor(1, 1, 1, 0.04)
    f._timerBg = timerBg

    local timerBar = f:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture(W.SOLID)
    timerBar:SetHeight(2)
    timerBar:SetPoint("BOTTOMLEFT", 3, 2)
    timerBar:SetWidth(TOAST_W - 6)
    timerBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.50)
    f._timerBar = timerBar

    -- Close button (appears on hover)
    local close = CreateFrame("Button", nil, f)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -4, -4)
    close.t = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.t:SetPoint("CENTER")
    close.t:SetText("x")
    close.t:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    close:SetAlpha(0)
    close:SetScript("OnClick", function()
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._tb_paused = true
        f._slideOut:Play()
    end)
    close:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
        s:SetAlpha(1)
    end)
    close:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    end)
    f._close = close

    -- Hover: show close, pause timer
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        close:SetAlpha(1)
        close.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        -- Pause auto-hide
        if self._hideTimer then
            self._hideTimer:Cancel()
            self._hideTimer = nil
        end
        self._tb_paused = true
        -- Lighten backdrop
        self:SetBackdropBorderColor(0.22, 0.26, 0.42, 0.75)
    end)
    f:SetScript("OnLeave", function(self)
        close:SetAlpha(0)
        self:SetBackdropBorderColor(0.15, 0.18, 0.28, 0.55)
        -- Cancel any previous timer before creating a new one
        if self._hideTimer then
            self._hideTimer:Cancel()
            self._hideTimer = nil
        end
        -- Resume timer with 2s remaining
        self._tb_paused = false
        self._hideTimer = C_Timer.NewTimer(2, function()
            if self:IsVisible() then
                self._tb_paused = true
                self._slideOut:Play()
            end
        end)
    end)

    -- Slide-in animation (from right: -60 -> 0, fade 0 -> 1)
    f._slideIn = f:CreateAnimationGroup()
    local si_t = f._slideIn:CreateAnimation("Translation")
    si_t:SetOffset(-60, 0)       -- start 60px to the right, slide left
    si_t:SetDuration(ANIM_IN_DUR)
    si_t:SetSmoothing("OUT")
    local si_a = f._slideIn:CreateAnimation("Alpha")
    si_a:SetFromAlpha(0)
    si_a:SetToAlpha(1)
    si_a:SetDuration(ANIM_IN_DUR * 0.75)
    si_a:SetSmoothing("OUT")
    f._slideIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)

    -- Slide-out animation (slide right + fade out)
    f._slideOut = f:CreateAnimationGroup()
    local so_t = f._slideOut:CreateAnimation("Translation")
    so_t:SetOffset(TOAST_W + TOAST_MARGIN, 0)
    so_t:SetDuration(ANIM_OUT_DUR)
    so_t:SetSmoothing("IN")
    local so_a = f._slideOut:CreateAnimation("Alpha")
    so_a:SetFromAlpha(1)
    so_a:SetToAlpha(0)
    so_a:SetDuration(ANIM_OUT_DUR * 0.85)
    so_a:SetSmoothing("IN")
    so_a:SetStartDelay(0.04)
    f._slideOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        f:SetScript("OnUpdate", nil)
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._iconPulse:Stop()
        -- Remove from active list
        for i = #toasts, 1, -1 do
            if toasts[i] == f then
                table.remove(toasts, i)
                break
            end
        end
        ReleaseToast(f)
        RepositionAll()
    end)

    return f
end

local function GetToast()
    return table.remove(toastPool, 1) or CreateToast()
end

ReleaseToast = function(toast)
    toast:Hide()
    toast:SetAlpha(0)
    toast:SetScript("OnUpdate", nil)
    table.insert(toastPool, toast)
end

---------------------------------------------------------------------------
-- Reposition all active toasts (regular + specials)
-- Celebration is centered at top. Achievement below it. Regulars stacked
-- in top-right below any specials.
---------------------------------------------------------------------------
RepositionAll = function()
    -- Calculate vertical offset for regular toasts
    local yStart = -TOAST_MARGIN

    -- Push regulars down if celebration or achievement are visible
    if celebrateFrame and celebrateFrame:IsShown() then
        yStart = yStart - CELEBRATE_H - TOAST_MARGIN
    end
    if achieveFrame and achieveFrame:IsShown() then
        yStart = yStart - ACHIEVE_H - TOAST_MARGIN
    end

    for _, toast in ipairs(toasts) do
        toast:ClearAllPoints()
        toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -TOAST_MARGIN, yStart)
        yStart = yStart - TOAST_H - TOAST_MARGIN
    end
end

-- Expose for external use
function ns.Notifications_RepositionToasts()
    RepositionAll()
end

---------------------------------------------------------------------------
-- Show a regular toast
-- type: "success", "error", "warning", "info"
---------------------------------------------------------------------------
function ns.Notifications_Show(title, message, toastType, duration)
    toastType = toastType or "info"
    duration  = duration or 4

    -- Evict oldest if at capacity
    if #toasts >= MAX_TOASTS then
        local oldest = toasts[1]
        if oldest then
            if oldest._hideTimer then oldest._hideTimer:Cancel(); oldest._hideTimer = nil end
            oldest:SetScript("OnUpdate", nil)
            oldest._iconPulse:Stop()
            oldest:SetAlpha(0)
            oldest:Hide()
            table.remove(toasts, 1)
            ReleaseToast(oldest)
        end
    end

    local toast = GetToast()

    -- Type-specific styling
    local glowColor = C.accent
    local iconText  = "i"
    if toastType == "success" then
        glowColor = C.green;  iconText = "+"
    elseif toastType == "error" then
        glowColor = C.red;    iconText = "x"
    elseif toastType == "warning" then
        glowColor = C.orange;  iconText = "!"
    end

    toast._glow:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0.9)
    toast._icon:SetText(iconText)
    toast._icon:SetTextColor(glowColor[1], glowColor[2], glowColor[3])
    toast._iconBg:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0)
    toast._timerBar:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0.45)
    toast._timerBar:SetWidth(TOAST_W - 6)
    toast._timerBar:Show()
    toast._title:SetText(title or "")
    toast._msg:SetText(message or "")
    toast._tb_paused = false

    -- Insert and position
    table.insert(toasts, toast)
    RepositionAll()

    toast:Show()
    toast._slideIn:Stop()
    toast._slideOut:Stop()
    toast:SetAlpha(0)
    toast._slideIn:Play()

    -- Brief icon glow pulse on appear
    toast._iconPulse:Stop()
    toast._iconPulse:Play()
    C_Timer.After(2.0, function()
        if toast._iconPulse:IsPlaying() then
            toast._iconPulse:Stop()
            toast._iconBg:SetAlpha(0)
        end
    end)

    -- Timer bar shrink
    AttachTimerBar(toast, toast._timerBar, TOAST_W - 6, duration)

    -- Auto-hide
    if toast._hideTimer then toast._hideTimer:Cancel() end
    toast._hideTimer = C_Timer.NewTimer(duration, function()
        toast._tb_paused = true
        toast._slideOut:Play()
    end)

    -- Sound (only error gets a sound)
    if toastType == "error" then
        PlaySound(847)
    end
end

-- Convenience wrappers
function ns.Notifications_Success(title, message, duration)
    ns.Notifications_Show(title, message, "success", duration or 3)
end

function ns.Notifications_Error(title, message)
    ns.Notifications_Show(title, message, "error", 5)
end

function ns.Notifications_Warning(title, message)
    ns.Notifications_Show(title, message, "warning", 4)
end

function ns.Notifications_Info(title, message)
    ns.Notifications_Show(title, message, "info", 3)
end

-- =====================================================================
--  CELEBRATION TOAST  (recruit joins, big events)
-- =====================================================================

local function CreateCelebrateFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(CELEBRATE_W, CELEBRATE_H)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(120)
    f:SetAlpha(0)
    f:Hide()

    -- Rich dark-gold backdrop
    f:SetBackdrop({
        bgFile   = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 12,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.12, 0.10, 0.04, 0.96)
    f:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.65)

    -- Inner gold accent line top
    local topLine = f:CreateTexture(nil, "OVERLAY")
    topLine:SetTexture(W.SOLID)
    topLine:SetHeight(2)
    topLine:SetPoint("TOPLEFT", 4, -3)
    topLine:SetPoint("TOPRIGHT", -4, -3)
    topLine:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.5)
    f._topLine = topLine

    -- Inner gold accent line bottom
    local botLine = f:CreateTexture(nil, "OVERLAY")
    botLine:SetTexture(W.SOLID)
    botLine:SetHeight(2)
    botLine:SetPoint("BOTTOMLEFT", 4, 3)
    botLine:SetPoint("BOTTOMRIGHT", -4, 3)
    botLine:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.35)
    f._botLine = botLine

    -- Pulsing gold border glow overlay (full frame, slightly larger)
    local borderGlow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    borderGlow:SetPoint("TOPLEFT", -2, 2)
    borderGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    borderGlow:SetBackdrop({
        edgeFile = W.EDGE,
        edgeSize = 14,
    })
    borderGlow:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.4)
    f._borderGlow = borderGlow

    -- Pulse the border glow
    local glowTex = borderGlow:CreateTexture(nil, "OVERLAY")
    glowTex:SetAllPoints()
    glowTex:SetTexture(W.SOLID)
    glowTex:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0)
    f._glowPulse = MakePulse(glowTex, 0, 0.06, 2.0)

    -- Star icon LEFT
    local starL = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    starL:SetPoint("LEFT", 16, 0)
    starL:SetText("*")
    starL:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 0.9)
    f._starL = starL
    f._starLPulse = MakePulse(starL, 0.5, 1.0, 1.4)

    -- Star icon RIGHT
    local starR = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    starR:SetPoint("RIGHT", -16, 0)
    starR:SetText("*")
    starR:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 0.9)
    f._starR = starR
    f._starRPulse = MakePulse(starR, 0.5, 1.0, 1.4)

    -- Title (centered, larger)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetJustifyH("CENTER")
    title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    f._title = title

    -- Message (centered, below title)
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msg:SetPoint("TOP", title, "BOTTOM", 0, -4)
    msg:SetJustifyH("CENTER")
    msg:SetTextColor(C.text[1], C.text[2], C.text[3])
    f._msg = msg

    -- Timer bar at bottom
    local timerBar = f:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture(W.SOLID)
    timerBar:SetHeight(2)
    timerBar:SetPoint("BOTTOMLEFT", 4, 6)
    timerBar:SetWidth(CELEBRATE_W - 8)
    timerBar:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.5)
    f._timerBar = timerBar

    -- Slide-in from top (slide down)
    f._slideIn = f:CreateAnimationGroup()
    local ci_t = f._slideIn:CreateAnimation("Translation")
    ci_t:SetOffset(0, 60)       -- start above, slide down
    ci_t:SetDuration(ANIM_IN_DUR)
    ci_t:SetSmoothing("OUT")
    local ci_a = f._slideIn:CreateAnimation("Alpha")
    ci_a:SetFromAlpha(0)
    ci_a:SetToAlpha(1)
    ci_a:SetDuration(ANIM_IN_DUR * 0.75)
    ci_a:SetSmoothing("OUT")
    f._slideIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)

    -- Slide-out upward
    f._slideOut = f:CreateAnimationGroup()
    local co_t = f._slideOut:CreateAnimation("Translation")
    co_t:SetOffset(0, CELEBRATE_H + TOAST_MARGIN)
    co_t:SetDuration(ANIM_OUT_DUR)
    co_t:SetSmoothing("IN")
    local co_a = f._slideOut:CreateAnimation("Alpha")
    co_a:SetFromAlpha(1)
    co_a:SetToAlpha(0)
    co_a:SetDuration(ANIM_OUT_DUR * 0.85)
    co_a:SetSmoothing("IN")
    co_a:SetStartDelay(0.04)
    f._slideOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        f:SetScript("OnUpdate", nil)
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._glowPulse:Stop()
        f._starLPulse:Stop()
        f._starRPulse:Stop()
        RepositionAll()
    end)

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.t = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.t:SetPoint("CENTER")
    close.t:SetText("x")
    close.t:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 0.6)
    close:SetAlpha(0)
    close:SetScript("OnClick", function()
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._tb_paused = true
        f._slideOut:Play()
    end)
    close:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
        s:SetAlpha(1)
    end)
    close:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 0.6)
    end)

    -- Hover: pause, show close
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        close:SetAlpha(1)
        if self._hideTimer then self._hideTimer:Cancel(); self._hideTimer = nil end
        self._tb_paused = true
    end)
    f:SetScript("OnLeave", function(self)
        close:SetAlpha(0)
        self._tb_paused = false
        self._hideTimer = C_Timer.NewTimer(2, function()
            self._tb_paused = true
            self._slideOut:Play()
        end)
    end)

    return f
end

---------------------------------------------------------------------------
-- ns.Notifications_Celebrate(title, message, duration)
-- Full-width gold banner at top center. Only 1 at a time.
---------------------------------------------------------------------------
function ns.Notifications_Celebrate(title, message, duration)
    duration = duration or 7

    if not celebrateFrame then
        celebrateFrame = CreateCelebrateFrame()
    end

    local f = celebrateFrame

    -- If already showing, cancel previous timers
    if f:IsShown() then
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._slideOut:Stop()
        f:SetScript("OnUpdate", nil)
    end

    f._title:SetText(title or "")
    f._msg:SetText(message or "")
    f._tb_paused = false
    f._timerBar:SetWidth(CELEBRATE_W - 8)
    f._timerBar:Show()

    -- Position: centered at top of screen
    f:ClearAllPoints()
    f:SetPoint("TOP", UIParent, "TOP", 0, -TOAST_MARGIN)

    f:Show()
    f._slideIn:Stop()
    f:SetAlpha(0)
    f._slideIn:Play()

    -- Start glow and star pulses
    f._glowPulse:Play()
    f._starLPulse:Play()
    f._starRPulse:Play()

    -- Timer bar shrink
    AttachTimerBar(f, f._timerBar, CELEBRATE_W - 8, duration)

    -- Auto-hide
    f._hideTimer = C_Timer.NewTimer(duration, function()
        f._tb_paused = true
        f._slideOut:Play()
    end)

    -- Push regular toasts down
    RepositionAll()

    -- Achievement fanfare
    PlaySound(8960)
end

-- =====================================================================
--  ACHIEVEMENT TOAST  (purple themed, with icon)
-- =====================================================================

local function CreateAchieveFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(ACHIEVE_W, ACHIEVE_H)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(115)
    f:SetAlpha(0)
    f:Hide()

    -- Dark purple backdrop
    f:SetBackdrop({
        bgFile   = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 11,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.09, 0.06, 0.14, 0.96)
    f:SetBackdropBorderColor(C.purple[1], C.purple[2], C.purple[3], 0.55)

    -- Top accent line
    local topLine = f:CreateTexture(nil, "OVERLAY")
    topLine:SetTexture(W.SOLID)
    topLine:SetHeight(2)
    topLine:SetPoint("TOPLEFT", 4, -3)
    topLine:SetPoint("TOPRIGHT", -4, -3)
    topLine:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0.45)

    -- Pulsing purple border glow
    local borderGlow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    borderGlow:SetPoint("TOPLEFT", -1, 1)
    borderGlow:SetPoint("BOTTOMRIGHT", 1, -1)
    borderGlow:SetBackdrop({
        edgeFile = W.EDGE,
        edgeSize = 13,
    })
    borderGlow:SetBackdropBorderColor(C.purple[1], C.purple[2], C.purple[3], 0.3)

    local glowOverlay = borderGlow:CreateTexture(nil, "OVERLAY")
    glowOverlay:SetAllPoints()
    glowOverlay:SetTexture(W.SOLID)
    glowOverlay:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0)
    f._glowPulse = MakePulse(glowOverlay, 0, 0.05, 2.0)

    -- Icon area (left side, achievement-style)
    local iconBg = f:CreateTexture(nil, "ARTWORK")
    iconBg:SetTexture(W.SOLID)
    iconBg:SetSize(38, 38)
    iconBg:SetPoint("LEFT", 10, 0)
    iconBg:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0.15)
    f._iconBg = iconBg

    local iconBorder = f:CreateTexture(nil, "OVERLAY")
    iconBorder:SetTexture(W.SOLID)
    iconBorder:SetSize(40, 40)
    iconBorder:SetPoint("CENTER", iconBg, "CENTER")
    iconBorder:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0.3)
    -- This acts as a subtle frame around the icon area

    local iconText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconText:SetPoint("CENTER", iconBg, "CENTER")
    iconText:SetTextColor(C.purple[1], C.purple[2], C.purple[3])
    iconText:SetText("!")
    f._iconText = iconText

    -- Title (right of icon)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 12, 2)
    title:SetPoint("RIGHT", -28, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(C.purple[1], C.purple[2], C.purple[3])
    f._title = title

    -- Message
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    msg:SetPoint("RIGHT", -28, 0)
    msg:SetJustifyH("LEFT")
    msg:SetTextColor(C.text[1], C.text[2], C.text[3])
    f._msg = msg

    -- Timer bar
    local timerBar = f:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture(W.SOLID)
    timerBar:SetHeight(2)
    timerBar:SetPoint("BOTTOMLEFT", 4, 3)
    timerBar:SetWidth(ACHIEVE_W - 8)
    timerBar:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0.45)
    f._timerBar = timerBar

    -- Slide-in from top
    f._slideIn = f:CreateAnimationGroup()
    local ai_t = f._slideIn:CreateAnimation("Translation")
    ai_t:SetOffset(0, 50)
    ai_t:SetDuration(ANIM_IN_DUR)
    ai_t:SetSmoothing("OUT")
    local ai_a = f._slideIn:CreateAnimation("Alpha")
    ai_a:SetFromAlpha(0)
    ai_a:SetToAlpha(1)
    ai_a:SetDuration(ANIM_IN_DUR * 0.75)
    ai_a:SetSmoothing("OUT")
    f._slideIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)

    -- Slide-out upward
    f._slideOut = f:CreateAnimationGroup()
    local ao_t = f._slideOut:CreateAnimation("Translation")
    ao_t:SetOffset(0, ACHIEVE_H + TOAST_MARGIN)
    ao_t:SetDuration(ANIM_OUT_DUR)
    ao_t:SetSmoothing("IN")
    local ao_a = f._slideOut:CreateAnimation("Alpha")
    ao_a:SetFromAlpha(1)
    ao_a:SetToAlpha(0)
    ao_a:SetDuration(ANIM_OUT_DUR * 0.85)
    ao_a:SetSmoothing("IN")
    ao_a:SetStartDelay(0.04)
    f._slideOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        f:SetScript("OnUpdate", nil)
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._glowPulse:Stop()
        RepositionAll()
    end)

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -5, -5)
    close.t = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.t:SetPoint("CENTER")
    close.t:SetText("x")
    close.t:SetTextColor(C.purple[1], C.purple[2], C.purple[3], 0.6)
    close:SetAlpha(0)
    close:SetScript("OnClick", function()
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._tb_paused = true
        f._slideOut:Play()
    end)
    close:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
        s:SetAlpha(1)
    end)
    close:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.purple[1], C.purple[2], C.purple[3], 0.6)
    end)

    -- Hover: pause, show close
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        close:SetAlpha(1)
        if self._hideTimer then self._hideTimer:Cancel(); self._hideTimer = nil end
        self._tb_paused = true
    end)
    f:SetScript("OnLeave", function(self)
        close:SetAlpha(0)
        self._tb_paused = false
        self._hideTimer = C_Timer.NewTimer(2, function()
            self._tb_paused = true
            self._slideOut:Play()
        end)
    end)

    return f
end

---------------------------------------------------------------------------
-- ns.Notifications_Achievement(title, message, icon)
-- Purple achievement-style toast below celebration, above regulars.
---------------------------------------------------------------------------
function ns.Notifications_Achievement(title, message, icon)
    local duration = 6

    if not achieveFrame then
        achieveFrame = CreateAchieveFrame()
    end

    local f = achieveFrame

    -- If already showing, cancel previous
    if f:IsShown() then
        if f._hideTimer then f._hideTimer:Cancel(); f._hideTimer = nil end
        f._slideOut:Stop()
        f:SetScript("OnUpdate", nil)
    end

    f._title:SetText(title or "")
    f._msg:SetText(message or "")
    f._iconText:SetText(icon or "!")
    f._tb_paused = false
    f._timerBar:SetWidth(ACHIEVE_W - 8)
    f._timerBar:Show()

    -- Position: centered, below celebration if present
    f:ClearAllPoints()
    local yOff = -TOAST_MARGIN
    if celebrateFrame and celebrateFrame:IsShown() then
        yOff = yOff - CELEBRATE_H - TOAST_MARGIN
    end
    f:SetPoint("TOP", UIParent, "TOP", 0, yOff)

    f:Show()
    f._slideIn:Stop()
    f:SetAlpha(0)
    f._slideIn:Play()

    f._glowPulse:Play()

    -- Timer bar shrink
    AttachTimerBar(f, f._timerBar, ACHIEVE_W - 8, duration)

    -- Auto-hide
    f._hideTimer = C_Timer.NewTimer(duration, function()
        f._tb_paused = true
        f._slideOut:Play()
    end)

    -- Push regular toasts down
    RepositionAll()

    -- Level-up sound
    PlaySound(888)
end
