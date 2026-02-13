local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Toast Notifications System
-- Elegant slide-in notifications for important events
-- ═══════════════════════════════════════════════════════════════════

local toasts = {}
local TOAST_WIDTH = 320
local TOAST_HEIGHT = 60
local TOAST_MARGIN = 8
local MAX_TOASTS = 5

local function CreateToast()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(100)
    f:SetAlpha(0)
    f:Hide()

    -- Modern glass-morphism backdrop
    f:SetBackdrop({
        bgFile = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    f:SetBackdropColor(0.08, 0.09, 0.16, 0.95)
    f:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.4)

    -- Accent glow bar on left edge
    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(W.SOLID)
    glow:SetWidth(3)
    glow:SetPoint("TOPLEFT", 4, -4)
    glow:SetPoint("BOTTOMLEFT", 4, 4)
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    f._glow = glow

    -- Icon (left side)
    local icon = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    icon:SetPoint("LEFT", 18, 0)
    icon:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    f._icon = icon

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    title:SetPoint("RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(C.text[1], C.text[2], C.text[3])
    f._title = title

    -- Message
    local msg = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    msg:SetPoint("RIGHT", -16, 0)
    msg:SetJustifyH("LEFT")
    msg:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    f._msg = msg

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    close.t = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.t:SetPoint("CENTER")
    close.t:SetText("×")
    close.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    close:SetScript("OnEnter", function(s)
        s.t:SetTextColor(C.red[1], C.red[2], C.red[3])
    end)
    close:SetScript("OnLeave", function(s)
        s.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    end)
    close:SetScript("OnClick", function()
        if f._hideTimer then f._hideTimer:Cancel() end
        f._fadeOut:Play()
    end)

    -- Slide-in animation (from right)
    f._slideIn = f:CreateAnimationGroup()
    local slideX = f._slideIn:CreateAnimation("Translation")
    slideX:SetOffset(-40, 0)
    slideX:SetDuration(0.3)
    slideX:SetSmoothing("OUT")
    local fadeIn = f._slideIn:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.25)
    fadeIn:SetSmoothing("OUT")
    f._slideIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)

    -- Fade-out animation
    f._fadeOut = f:CreateAnimationGroup()
    local fadeOut = f._fadeOut:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.2)
    fadeOut:SetSmoothing("IN")
    f._fadeOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()
        -- Remove from active toasts and reposition others
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

function ns.Notifications_RepositionToasts()
    local yOffset = -TOAST_MARGIN
    for i, toast in ipairs(toasts) do
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
        oldest._fadeOut:Play()
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

    toast._glow:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 0.8)
    toast._icon:SetText(iconText)
    toast._icon:SetTextColor(glowColor[1], glowColor[2], glowColor[3])
    toast:SetBackdropBorderColor(glowColor[1], glowColor[2], glowColor[3], 0.4)

    toast._title:SetText(title or "")
    toast._msg:SetText(message or "")

    table.insert(toasts, toast)
    ns.Notifications_RepositionToasts()

    toast:Show()
    toast._slideIn:Play()

    -- Auto-hide after duration
    if toast._hideTimer then toast._hideTimer:Cancel() end
    toast._hideTimer = C_Timer.NewTimer(duration, function()
        toast._fadeOut:Play()
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
