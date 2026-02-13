local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Toast Notifications System
-- Smooth slide-in notifications with progress timer bar
-- ═══════════════════════════════════════════════════════════════════

local toasts = {}
local TOAST_WIDTH = 300
local TOAST_HEIGHT = 52
local TOAST_MARGIN = 6
local MAX_TOASTS = 4

local function CreateToast()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(100)
    f:SetAlpha(0)
    f:Hide()

    -- Sleek dark backdrop
    f:SetBackdrop({
        bgFile = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    f:SetBackdropColor(0.06, 0.07, 0.12, 0.92)
    f:SetBackdropBorderColor(0.15, 0.18, 0.28, 0.50)

    -- Accent glow bar on left edge
    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(W.SOLID)
    glow:SetWidth(3)
    glow:SetPoint("TOPLEFT", 3, -3)
    glow:SetPoint("BOTTOMLEFT", 3, 3)
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    f._glow = glow

    -- Icon (left side)
    local icon = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    icon:SetPoint("LEFT", 14, 0)
    icon:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    f._icon = icon

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 2)
    title:SetPoint("RIGHT", -12, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(C.text[1], C.text[2], C.text[3])
    f._title = title

    -- Message
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    msg:SetPoint("RIGHT", -12, 0)
    msg:SetJustifyH("LEFT")
    msg:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    f._msg = msg

    -- Timer progress bar (thin line at bottom)
    local timerBar = f:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture(W.SOLID)
    timerBar:SetHeight(2)
    timerBar:SetPoint("BOTTOMLEFT", 3, 2)
    timerBar:SetWidth(TOAST_WIDTH - 6)
    timerBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    f._timerBar = timerBar

    -- Close button (subtle)
    local close = CreateFrame("Button", nil, f)
    close:SetSize(14, 14)
    close:SetPoint("TOPRIGHT", -4, -4)
    close.t = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.t:SetPoint("CENTER")
    close.t:SetText("×")
    close.t:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    close:SetAlpha(0)
    close:SetScript("OnClick", function()
        if f._hideTimer then f._hideTimer:Cancel() end
        if f._timerTicker then f._timerTicker:Cancel() end
        f._slideOut:Play()
    end)

    -- Show close button on hover
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        close:SetAlpha(1)
        close.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        -- Pause auto-hide on hover
        if self._hideTimer then
            self._hideTimer:Cancel()
            self._hideTimer = nil
        end
        if self._timerTicker then
            self._timerTicker:Cancel()
            self._timerTicker = nil
        end
    end)
    f:SetScript("OnLeave", function(self)
        close:SetAlpha(0)
        -- Resume auto-hide (2s remaining)
        self._hideTimer = C_Timer.NewTimer(2, function()
            self._slideOut:Play()
        end)
    end)

    close:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
        s:SetAlpha(1)
    end)
    close:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    end)

    -- Slide-in animation (translate left + fade in)
    f._slideIn = f:CreateAnimationGroup()
    local si_translate = f._slideIn:CreateAnimation("Translation")
    si_translate:SetOffset(-50, 0)
    si_translate:SetDuration(0.4)
    si_translate:SetSmoothing("OUT")
    local si_alpha = f._slideIn:CreateAnimation("Alpha")
    si_alpha:SetFromAlpha(0)
    si_alpha:SetToAlpha(1)
    si_alpha:SetDuration(0.3)
    si_alpha:SetSmoothing("OUT")
    f._slideIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)

    -- Slide-out animation (slide right + fade)
    f._slideOut = f:CreateAnimationGroup()
    local so_translate = f._slideOut:CreateAnimation("Translation")
    so_translate:SetOffset(TOAST_WIDTH + TOAST_MARGIN, 0)
    so_translate:SetDuration(0.3)
    so_translate:SetSmoothing("IN")
    local so_alpha = f._slideOut:CreateAnimation("Alpha")
    so_alpha:SetFromAlpha(1)
    so_alpha:SetToAlpha(0)
    so_alpha:SetDuration(0.25)
    so_alpha:SetSmoothing("IN")
    so_alpha:SetStartDelay(0.05)
    f._slideOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        if f._timerTicker then f._timerTicker:Cancel(); f._timerTicker = nil end
        -- Remove from active toasts and reposition
        for i = #toasts, 1, -1 do
            if toasts[i] == f then
                table.remove(toasts, i)
                break
            end
        end
        ns.Notifications_RepositionToasts()
    end)

    return f
end

local toastPool = {}

local function GetToast()
    local toast = table.remove(toastPool, 1)
    if not toast then
        toast = CreateToast()
    end
    return toast
end

local function ReleaseToast(toast)
    toast:Hide()
    toast:SetAlpha(0)
    table.insert(toastPool, toast)
end

-- Smooth reposition with animation
function ns.Notifications_RepositionToasts()
    local yOffset = -TOAST_MARGIN
    for _, toast in ipairs(toasts) do
        toast:ClearAllPoints()
        toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -TOAST_MARGIN, yOffset)
        yOffset = yOffset - TOAST_HEIGHT - TOAST_MARGIN
    end
end

-- type: "success" (green), "error" (red), "info" (blue), "warning" (orange)
function ns.Notifications_Show(title, message, toastType, duration)
    toastType = toastType or "info"
    duration = duration or 4

    -- Remove oldest toast if we have too many
    if #toasts >= MAX_TOASTS then
        local oldest = table.remove(toasts, 1)
        if oldest._hideTimer then oldest._hideTimer:Cancel() end
        if oldest._timerTicker then oldest._timerTicker:Cancel() end
        oldest._slideOut:Play()
    end

    local toast = GetToast()

    -- Set colors based on type
    local glowColor = C.accent
    local iconText = "★"
    if toastType == "success" then
        glowColor = C.green
        iconText = "✓"
    elseif toastType == "error" then
        glowColor = C.red
        iconText = "✖"
    elseif toastType == "warning" then
        glowColor = C.orange
        iconText = "⚠"
    end

    toast._glow:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0.9)
    toast._icon:SetText(iconText)
    toast._icon:SetTextColor(glowColor[1], glowColor[2], glowColor[3])
    toast._timerBar:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0.4)
    toast._timerBar:SetWidth(TOAST_WIDTH - 6)

    toast._title:SetText(title or "")
    toast._msg:SetText(message or "")

    table.insert(toasts, toast)
    ns.Notifications_RepositionToasts()

    toast:Show()
    toast._slideIn:Stop()
    toast:SetAlpha(0)
    toast._slideIn:Play()

    -- Animate timer bar shrink
    local barFullWidth = TOAST_WIDTH - 6
    local elapsed = 0
    local interval = 0.03
    if toast._timerTicker then toast._timerTicker:Cancel() end
    toast._timerTicker = C_Timer.NewTicker(interval, function(ticker)
        elapsed = elapsed + interval
        local remaining = 1 - (elapsed / duration)
        if remaining <= 0 then
            toast._timerBar:SetWidth(1)
            ticker:Cancel()
            return
        end
        toast._timerBar:SetWidth(math.max(1, barFullWidth * remaining))
    end)

    -- Auto-hide after duration
    if toast._hideTimer then toast._hideTimer:Cancel() end
    toast._hideTimer = C_Timer.NewTimer(duration, function()
        if toast._timerTicker then toast._timerTicker:Cancel(); toast._timerTicker = nil end
        toast._slideOut:Play()
    end)
end

-- Convenience functions
function ns.Notifications_Success(title, message)
    ns.Notifications_Show(title, message, "success", 3)
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
