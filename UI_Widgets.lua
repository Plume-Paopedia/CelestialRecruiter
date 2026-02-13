local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  UI Widget Library
-- Shared color palette, constants, and reusable widget factories
-- ═══════════════════════════════════════════════════════════════════

local W = {}
ns.UIWidgets = W

local SOLID = "Interface\\Buttons\\WHITE8x8"
local EDGE  = "Interface\\Tooltips\\UI-Tooltip-Border"
local ROW_H = 28
local max, min = math.max, math.min
local pairs, ipairs, tostring = pairs, ipairs, tostring
local unpack = unpack

W.SOLID = SOLID
W.EDGE  = EDGE
W.ROW_H = ROW_H

---------------------------------------------------------------------------
-- Color Palette
---------------------------------------------------------------------------
local C = {
    bg        = {0.05, 0.06, 0.11, 0.97},
    panel     = {0.08, 0.09, 0.16, 0.90},
    row1      = {0.10, 0.12, 0.21, 0.50},
    row2      = {0.07, 0.08, 0.15, 0.30},
    hover     = {0.16, 0.22, 0.38, 0.65},
    border    = {0.20, 0.26, 0.46, 0.60},
    accent    = {0.00, 0.68, 1.00},
    accentDark= {0.00, 0.35, 0.55},
    gold      = {1.00, 0.84, 0.00},
    purple    = {0.58, 0.40, 1.00},
    text      = {0.92, 0.93, 0.96},
    dim       = {0.55, 0.58, 0.66},
    muted     = {0.36, 0.38, 0.46},
    green     = {0.20, 0.88, 0.48},
    orange    = {1.00, 0.70, 0.28},
    red       = {1.00, 0.40, 0.40},
}
W.C = C

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function W.reasonFr(why)
    if not why then return "" end
    local map = {
        ["scan complete"]                            = "scan terminé",
        ["waiting WHO result"]                       = "attente réponse WHO",
        ["who api unavailable"]                      = "API /who indisponible",
        ["SendWho blocked (needs hardware click)"]   = "SendWho bloqué (clic matériel requis)",
        ["scanner not active"]                       = "scanner inactif",
        ["no query generated"]                       = "aucune requête générée",
        ["invite_api_blocked"]                       = "invitation bloquée (clic matériel requis)",
        ["invalid_target"]                           = "cible invalide",
        ["invalid target"]                           = "cible invalide",
        ["no_opt_in"]                                = "pas d'opt-in",
        ["not_in_guild"]                             = "personnage non guildé",
        ["missing_permission"]                       = "droit d'invitation manquant",
        ["empty_template"]                           = "modèle vide",
        ["blacklisted"]                              = "joueur blacklisté",
        ["ignored"]                                  = "joueur ignoré",
        ["cooldown"]                                 = "cooldown actif",
        ["rate limit (minute)"]                      = "limite actions/min",
        ["rate limit (whisper/hour)"]                = "limite messages/h",
        ["rate limit (invite/hour)"]                 = "limite invites/h",
        ["target AFK recently"]                      = "joueur AFK récent",
        ["target DND recently"]                      = "joueur DND récent",
        ["self target"]                              = "cible = toi-même",
    }
    if map[why] then return map[why] end
    local inst = tostring(why):match("^instance %((.+)%)$")
    if inst then return "bloqué en instance (" .. inst .. ")" end
    local w = tostring(why):match("^wait%s+([%d%.]+s)$")
    if w then return "attendre " .. w end
    return tostring(why)
end

function W.classHex(classFile)
    local cc = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local c = cc and classFile and cc[classFile]
    return c and c.colorStr or "ffffffff"
end

function W.classRGB(classFile)
    local cc = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local c = cc and classFile and cc[classFile]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

function W.matchSearch(query, ...)
    if not query or query == "" then return true end
    local blob = ""
    for i = 1, select("#", ...) do
        blob = blob .. " " .. (select(i, ...) or "")
    end
    return ns.Util_Lower(blob):find(query, 1, true) ~= nil
end

function W.logColor(kind)
    local map = {
        ERR="ff6b6b", SKIP="ffb347", INV="66ff99", IN="8bc5ff",
        QUEUE="ffd966", BL="ff8a80", IGNORE="ffb347", AFK="c6a8ff",
        DND="c6a8ff", SCAN="7ad3ff", OUT="dddddd",
    }
    return map[kind] or "dddddd"
end

function W.countKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function W.statusDotColor(status)
    local map = {
        new       = {C.accent[1], C.accent[2], C.accent[3]},
        contacted = {C.orange[1], C.orange[2], C.orange[3]},
        invited   = {C.green[1],  C.green[2],  C.green[3]},
        joined    = {C.gold[1],   C.gold[2],   C.gold[3]},
        ignored   = {C.muted[1],  C.muted[2],  C.muted[3]},
    }
    local c = map[status or "new"] or map.new
    return c[1], c[2], c[3]
end

---------------------------------------------------------------------------
-- Widget: Styled Panel
---------------------------------------------------------------------------
function W.MakePanel(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    f:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
    f:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
    return f
end

---------------------------------------------------------------------------
-- Widget: Button
-- style: "p"=primary, "s"=success, "d"=danger, "n"=neutral
---------------------------------------------------------------------------
function W.MakeBtn(parent, text, w, style, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, 24)
    local norms = {
        p = {0.06, 0.30, 0.55, 0.90},
        d = {0.50, 0.10, 0.10, 0.85},
        s = {0.10, 0.40, 0.22, 0.85},
        n = {0.14, 0.16, 0.24, 0.85},
    }
    local hovs = {
        p = {0.10, 0.42, 0.72, 1.00},
        d = {0.65, 0.15, 0.15, 1.00},
        s = {0.14, 0.52, 0.30, 1.00},
        n = {0.22, 0.25, 0.38, 1.00},
    }
    local nc = norms[style or "n"] or norms.n
    local hc = hovs[style or "n"] or hovs.n
    b:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    b:SetBackdropColor(unpack(nc))
    b:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.35)
    -- Top highlight line for depth/bevel
    local hl = b:CreateTexture(nil, "OVERLAY")
    hl:SetTexture(SOLID)
    hl:SetHeight(1)
    hl:SetPoint("TOPLEFT", 3, -2)
    hl:SetPoint("TOPRIGHT", -3, -2)
    hl:SetVertexColor(1, 1, 1, 0.08)

    -- Hover glow overlay
    local glow = b:CreateTexture(nil, "ARTWORK")
    glow:SetTexture(SOLID)
    glow:SetAllPoints()
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
    glow:Hide()

    b.t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.t:SetPoint("CENTER")
    b.t:SetText(text)
    b.t:SetTextColor(unpack(C.text))
    b._nc, b._hc, b._off, b._glow = nc, hc, false, glow

    -- Smooth color transitions
    b._targetR, b._targetG, b._targetB, b._targetA = unpack(nc)
    b._currentR, b._currentG, b._currentB, b._currentA = unpack(nc)

    b:SetScript("OnUpdate", function(s, elapsed)
        -- Lerp to target color
        local speed = 8
        local dr = (s._targetR - s._currentR) * elapsed * speed
        local dg = (s._targetG - s._currentG) * elapsed * speed
        local db = (s._targetB - s._currentB) * elapsed * speed
        local da = (s._targetA - s._currentA) * elapsed * speed

        if math.abs(dr) < 0.001 and math.abs(dg) < 0.001 and math.abs(db) < 0.001 and math.abs(da) < 0.001 then
            s._currentR, s._currentG, s._currentB, s._currentA = s._targetR, s._targetG, s._targetB, s._targetA
        else
            s._currentR = s._currentR + dr
            s._currentG = s._currentG + dg
            s._currentB = s._currentB + db
            s._currentA = s._currentA + da
        end

        s:SetBackdropColor(s._currentR, s._currentG, s._currentB, s._currentA)
    end)

    b:SetScript("OnEnter", function(s)
        if not s._off then
            s._targetR, s._targetG, s._targetB, s._targetA = unpack(s._hc)
            s._glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.10)
            s._glow:Show()

            -- Subtle sparkle effect on hover
            if ns.ParticleSystem and ns.ParticleSystem.PlayHoverEffect then
                ns.ParticleSystem:PlayHoverEffect(s)
            end
        end
    end)
    b:SetScript("OnLeave", function(s)
        if not s._off then
            s._targetR, s._targetG, s._targetB, s._targetA = unpack(s._nc)
        end
        s._glow:Hide()
    end)
    b:SetScript("OnClick", function(s)
        if not s._off and onClick then
            -- Click feedback: quick brighten
            local pr, pg, pb, pa = unpack(s._hc)
            s:SetBackdropColor(math.min(1, pr * 1.2), math.min(1, pg * 1.2), math.min(1, pb * 1.2), pa)
            C_Timer.After(0.08, function()
                if s._targetR then
                    s._currentR, s._currentG, s._currentB, s._currentA = s._targetR, s._targetG, s._targetB, s._targetA
                end
            end)

            -- Click effect with particles
            if ns.ParticleSystem and ns.ParticleSystem.PlayClickEffect then
                ns.ParticleSystem:PlayClickEffect(s)
            end

            onClick()
        end
    end)
    function b:SetLabel(t) self.t:SetText(t) end
    function b:SetOff(v)
        self._off = v
        self:SetAlpha(v and 0.35 or 1)
        if v then
            self:SetBackdropColor(0.10, 0.10, 0.14, 0.5)
            self._glow:Hide()
        end
    end
    return b
end

---------------------------------------------------------------------------
-- Widget: Scroll Area with thin scrollbar + empty state
---------------------------------------------------------------------------
function W.MakeScroll(parent)
    local f = W.MakePanel(parent)
    f:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.35)
    f:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.25)

    local sf = CreateFrame("ScrollFrame", nil, f)
    sf:SetPoint("TOPLEFT", 2, -2)
    sf:SetPoint("BOTTOMRIGHT", -10, 2)
    local ch = CreateFrame("Frame", nil, sf)
    ch:SetWidth(1)
    sf:SetScrollChild(ch)

    -- Thin scrollbar track
    local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
    track:SetWidth(4)
    track:SetPoint("TOPRIGHT", -3, -3)
    track:SetPoint("BOTTOMRIGHT", -3, 3)
    track:SetBackdrop({bgFile = SOLID})
    track:SetBackdropColor(1, 1, 1, 0.06)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetWidth(4)
    thumb:SetBackdrop({bgFile = SOLID})
    thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.25)
    thumb:SetPoint("TOP")
    thumb:SetHeight(30)
    thumb:Hide()

    -- Scrollbar hover: brighten thumb
    track:EnableMouse(true)
    track:SetScript("OnEnter", function() thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.50) end)
    track:SetScript("OnLeave", function() thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.25) end)

    local function updThumb()
        local mx = max(0, ch:GetHeight() - sf:GetHeight())
        if mx <= 0 then thumb:Hide(); return end
        thumb:Show()
        local r = sf:GetHeight() / ch:GetHeight()
        local th = max(18, track:GetHeight() * r)
        thumb:SetHeight(th)
        local sr = sf:GetVerticalScroll() / mx
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -sr * (track:GetHeight() - th))
    end

    -- Smooth scrolling with momentum
    sf._scrollVelocity = 0
    sf._targetScroll = 0
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(s, d)
        local mx = max(0, ch:GetHeight() - s:GetHeight())
        s._targetScroll = max(0, min(mx, s._targetScroll - d * ROW_H * 3))
        s._scrollVelocity = -d * ROW_H * 2  -- Add momentum
    end)

    -- Smooth scroll update with easing
    sf:SetScript("OnUpdate", function(s, elapsed)
        local mx = max(0, ch:GetHeight() - s:GetHeight())
        local current = s:GetVerticalScroll()

        -- Apply velocity decay (momentum)
        if math.abs(s._scrollVelocity) > 0.1 then
            s._scrollVelocity = s._scrollVelocity * (1 - elapsed * 8)
            s._targetScroll = s._targetScroll + s._scrollVelocity * elapsed * 60
            s._targetScroll = max(0, min(mx, s._targetScroll))
        else
            s._scrollVelocity = 0
        end

        -- Smooth lerp to target
        local diff = s._targetScroll - current
        if math.abs(diff) > 0.5 then
            local newScroll = current + diff * elapsed * 12
            s:SetVerticalScroll(max(0, min(mx, newScroll)))
            updThumb()
        elseif math.abs(diff) > 0.01 then
            s:SetVerticalScroll(s._targetScroll)
            updThumb()
        end
    end)
    sf:SetScript("OnSizeChanged", function(s)
        ch:SetWidth(s:GetWidth())
        updThumb()
    end)

    -- Empty state (gold icon + dim text)
    local ei = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    ei:SetPoint("CENTER", 0, 16)
    ei:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 0.35)
    ei:Hide()
    local et = ch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    et:SetPoint("TOP", ei, "BOTTOM", 0, -6)
    et:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    et:Hide()

    return {
        frame = f, sf = sf, child = ch, rows = {},
        updThumb = updThumb, _ei = ei, _et = et,
        ShowEmpty = function(self, icon, txt)
            self._ei:SetText(icon or "")
            self._ei:Show()
            self._et:SetText(txt)
            self._et:Show()
        end,
        HideEmpty = function(self)
            self._ei:Hide()
            self._et:Hide()
        end,
        SetH = function(self, h)
            ch:SetHeight(max(1, h))
            updThumb()
        end,
    }
end

---------------------------------------------------------------------------
-- Widget: Custom Dropdown
---------------------------------------------------------------------------
function W.MakeDropdown(parent, w, items, cur, onChange)
    local dd = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dd:SetSize(w, 22)
    dd:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    dd:SetBackdropColor(0.07, 0.08, 0.14, 0.9)
    dd:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)

    dd.t = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dd.t:SetPoint("LEFT", 6, 0)
    dd.t:SetPoint("RIGHT", -16, 0)
    dd.t:SetJustifyH("LEFT")
    dd.t:SetTextColor(unpack(C.text))

    local ar = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ar:SetPoint("RIGHT", -4, 0)
    ar:SetText("v")
    ar:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Popup menu
    local m = CreateFrame("Frame", nil, dd, "BackdropTemplate")
    m:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 10, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    m:SetBackdropColor(0.07, 0.08, 0.14, 0.98)
    m:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.4)
    m:SetWidth(w)
    m:SetPoint("TOP", dd, "BOTTOM", 0, -2)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:Hide()

    local mh = 4
    for _, it in ipairs(items) do
        local b = CreateFrame("Button", nil, m)
        b:SetSize(w - 8, 20)
        b:SetPoint("TOPLEFT", 4, -mh)
        mh = mh + 20
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetTexture(SOLID)
        b.bg:SetVertexColor(0, 0, 0, 0)
        b.tx = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.tx:SetPoint("LEFT", 4, 0)
        b.tx:SetText(it.label)
        b.tx:SetTextColor(unpack(C.text))
        b:SetScript("OnEnter", function(s)
            s.bg:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.12)
        end)
        b:SetScript("OnLeave", function(s)
            s.bg:SetVertexColor(0, 0, 0, 0)
        end)
        b:SetScript("OnClick", function()
            dd._v = it.value
            dd.t:SetText(it.label)
            m:Hide()
            if onChange then onChange(it.value) end
        end)
    end
    m:SetHeight(mh + 4)

    dd:EnableMouse(true)
    dd:SetScript("OnMouseDown", function()
        if m:IsShown() then m:Hide() else m:Show() end
    end)

    dd._v = cur
    for _, it in ipairs(items) do
        if it.value == cur then dd.t:SetText(it.label); break end
    end

    function dd:SetVal(v)
        self._v = v
        for _, it in ipairs(items) do
            if it.value == v then self.t:SetText(it.label); break end
        end
    end
    function dd:GetVal() return self._v end
    return dd
end

---------------------------------------------------------------------------
-- Widget: Labeled Text Input
---------------------------------------------------------------------------
function W.MakeInput(parent, label, w, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(w, 40)
    local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    l:SetPoint("TOPLEFT", 0, 0)
    l:SetText(label)
    l:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    local eb = CreateFrame("EditBox", nil, f, "BackdropTemplate")
    eb:SetPoint("TOPLEFT", 0, -14)
    eb:SetSize(w, 22)
    eb:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    eb:SetBackdropColor(0.05, 0.06, 0.11, 0.85)
    eb:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetText(get() or "")
    eb:SetScript("OnEnterPressed", function(s)
        set(s:GetText())
        s:ClearFocus()
    end)
    eb:SetScript("OnEscapePressed", function(s)
        s:SetText(get() or "")
        s:ClearFocus()
    end)
    eb:SetScript("OnEditFocusGained", function(s)
        s:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    end)
    eb:SetScript("OnEditFocusLost", function(s)
        s:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
    end)
    f.eb = eb
    return f
end

---------------------------------------------------------------------------
-- Widget: Labeled Number Input
---------------------------------------------------------------------------
function W.MakeNumInput(parent, label, w, get, set, fallback, minV, maxV)
    return W.MakeInput(parent, label, w,
        function() return tostring(get() or fallback) end,
        function(v) set(ns.Util_ToNumber(v, fallback, minV, maxV)) end
    )
end

---------------------------------------------------------------------------
-- Widget: Styled Checkbox
---------------------------------------------------------------------------
function W.MakeCheck(parent, label, get, set)
    local f = CreateFrame("CheckButton", nil, parent)
    f:SetSize(18, 18)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(SOLID)
    bg:SetVertexColor(0.06, 0.07, 0.12, 0.8)

    local bd = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bd:SetAllPoints()
    bd:SetBackdrop({edgeFile = EDGE, edgeSize = 8})
    bd:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)

    local ck = f:CreateTexture(nil, "OVERLAY")
    ck:SetSize(10, 10)
    ck:SetPoint("CENTER")
    ck:SetTexture(SOLID)
    ck:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    f:SetCheckedTexture(ck)

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.label:SetPoint("LEFT", f, "RIGHT", 6, 0)
    f.label:SetText(label)
    f.label:SetTextColor(C.text[1], C.text[2], C.text[3])

    -- Smooth check animation
    f._checkScale = f:CreateAnimationGroup()
    local scaleIn = f._checkScale:CreateAnimation("Scale")
    scaleIn:SetScaleFrom(0.5, 0.5)
    scaleIn:SetScaleTo(1, 1)
    scaleIn:SetDuration(0.15)
    scaleIn:SetSmoothing("OUT")
    scaleIn:SetOrigin("CENTER", 0, 0)

    f:SetChecked(get() and true or false)
    f:SetScript("OnClick", function(s)
        local checked = s:GetChecked() and true or false
        set(checked)
        if checked then
            -- Play check animation
            s._checkScale:Play()
        end
    end)
    f:SetScript("OnEnter", function()
        bd:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
        bg:SetVertexColor(0.08, 0.09, 0.15, 0.9)
    end)
    f:SetScript("OnLeave", function()
        bd:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)
        bg:SetVertexColor(0.06, 0.07, 0.12, 0.8)
    end)
    return f
end

---------------------------------------------------------------------------
-- Widget: Section Header (gold text with separator line)
---------------------------------------------------------------------------
function W.MakeHeader(parent, text)
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetText(text)
    h:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    return h
end

function W.MakeSeparator(parent, anchor)
    local sep = parent:CreateTexture(nil, "OVERLAY")
    sep:SetTexture(SOLID)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    sep:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    sep:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.3)
    return sep
end

---------------------------------------------------------------------------
-- Widget: Multi-line Text Area
---------------------------------------------------------------------------
function W.MakeTextArea(parent, label, w, h, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(w, h + 16)
    local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    l:SetPoint("TOPLEFT", 0, 0)
    l:SetText(label)
    l:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    local box = CreateFrame("ScrollFrame", nil, f, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 0, -14)
    box:SetSize(w, h)
    box:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    box:SetBackdropColor(0.05, 0.06, 0.11, 0.85)
    box:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)

    local eb = CreateFrame("EditBox", nil, box)
    eb:SetWidth(w - 16)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetTextInsets(6, 6, 4, 4)
    eb:SetText(get() or "")
    box:SetScrollChild(eb)

    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(s, d)
        local mx = max(0, eb:GetHeight() - s:GetHeight())
        s:SetVerticalScroll(max(0, min(mx, s:GetVerticalScroll() - d * 20)))
    end)

    eb:SetScript("OnTextChanged", function(s, isUser)
        if isUser then set(s:GetText() or "") end
    end)
    eb:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function()
        box:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    end)
    eb:SetScript("OnEditFocusLost", function()
        box:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
    end)

    f.box = box
    f.eb = eb
    function f:SetValue(txt) eb:SetText(txt or "") end
    return f
end

---------------------------------------------------------------------------
-- Widget: Info Block (read-only styled text for help pages)
---------------------------------------------------------------------------
function W.MakeInfoBlock(parent, text)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({bgFile = SOLID})
    f:SetBackdropColor(0.06, 0.07, 0.13, 0.6)
    f.t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.t:SetPoint("TOPLEFT", 10, -8)
    f.t:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.t:SetJustifyH("LEFT")
    f.t:SetSpacing(3)
    f.t:SetText(text)
    f.t:SetTextColor(C.text[1], C.text[2], C.text[3])
    function f:UpdateHeight()
        self:SetHeight(self.t:GetStringHeight() + 18)
    end
    return f
end

---------------------------------------------------------------------------
-- Helper: Set alternating row background
---------------------------------------------------------------------------
function W.SetRowBG(row, index)
    local bgc = (index % 2 == 0) and C.row2 or C.row1
    row._bgc = bgc
    row:SetBackdropColor(unpack(bgc))
end

---------------------------------------------------------------------------
-- Helper: Add subtle hover glow to a row frame
-- Call once after creating the row. Glow shows on hover, hides on leave.
---------------------------------------------------------------------------
function W.AddRowGlow(row)
    local glow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetTexture(SOLID)
    glow:SetAllPoints()
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0)
    glow:Hide()
    row._rowGlow = glow
    row:HookScript("OnEnter", function() glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.06); glow:Show() end)
    row:HookScript("OnLeave", function() glow:Hide() end)
end

---------------------------------------------------------------------------
-- Tooltip: Enriched player info on hover
---------------------------------------------------------------------------
function W.ShowPlayerTooltip(anchor, key, scanData)
    if not key or key == "" then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")

    local c = ns.DB_GetContact(key)
    local classFile = scanData and scanData.classFile

    -- Name
    if classFile and classFile ~= "" then
        GameTooltip:AddLine("|c" .. W.classHex(classFile) .. key .. "|r")
    else
        GameTooltip:AddLine(key, C.accent[1], C.accent[2], C.accent[3])
    end

    -- Level / class / race from scan data
    if scanData then
        local parts = {}
        if (scanData.level or 0) > 0 then
            parts[#parts + 1] = "Niv " .. scanData.level
        end
        if scanData.classLabel and scanData.classLabel ~= "" then
            parts[#parts + 1] = scanData.classLabel
        end
        if scanData.race and scanData.race ~= "" then
            parts[#parts + 1] = scanData.race
        end
        if #parts > 0 then
            GameTooltip:AddLine(table.concat(parts, "  "), C.dim[1], C.dim[2], C.dim[3])
        end
        if scanData.zone and scanData.zone ~= "" then
            GameTooltip:AddLine(scanData.zone, C.dim[1], C.dim[2], C.dim[3])
        end
        if scanData.crossRealm then
            GameTooltip:AddLine("Cross-realm", C.orange[1], C.orange[2], C.orange[3])
        end
    end

    -- Contact data
    if c then
        GameTooltip:AddLine(" ")
        local sr, sg, sb = W.statusDotColor(c.status)
        GameTooltip:AddDoubleLine("Statut:", c.status or "new", C.dim[1], C.dim[2], C.dim[3], sr, sg, sb)
        if c.source and c.source ~= "" then
            GameTooltip:AddDoubleLine("Source:", c.source, C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        end
        if c.optedIn then
            GameTooltip:AddDoubleLine("Opt-in:", "Oui", C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
        end

        GameTooltip:AddLine(" ")
        if (c.firstSeen or 0) > 0 then
            GameTooltip:AddDoubleLine("Premiere vue:", ns.Util_FormatAgo(c.firstSeen), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        end
        if (c.lastSeen or 0) > 0 then
            GameTooltip:AddDoubleLine("Derniere vue:", ns.Util_FormatAgo(c.lastSeen), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        end

        if (c.lastInviteAt or 0) > 0 then
            GameTooltip:AddDoubleLine("Derniere invitation:", ns.Util_FormatAgo(c.lastInviteAt), C.gold[1], C.gold[2], C.gold[3], C.text[1], C.text[2], C.text[3])
        else
            GameTooltip:AddDoubleLine("Derniere invitation:", "jamais", C.gold[1], C.gold[2], C.gold[3], C.muted[1], C.muted[2], C.muted[3])
        end

        if (c.lastWhisperIn or 0) > 0 then
            GameTooltip:AddDoubleLine("Dernier msg recu:", ns.Util_FormatAgo(c.lastWhisperIn), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        end
        if (c.lastWhisperOut or 0) > 0 then
            GameTooltip:AddDoubleLine("Dernier msg envoye:", ns.Util_FormatAgo(c.lastWhisperOut), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
        end

        if c.notes and c.notes ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Notes: " .. c.notes, C.dim[1], C.dim[2], C.dim[3], true)
        end
    else
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Derniere invitation:", "jamais", C.gold[1], C.gold[2], C.gold[3], C.muted[1], C.muted[2], C.muted[3])
    end

    GameTooltip:Show()
end

function W.HidePlayerTooltip()
    GameTooltip:Hide()
end
