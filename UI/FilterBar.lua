local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local SOLID = W.SOLID
local EDGE  = W.EDGE
local format = string.format
local pairs, ipairs, unpack = pairs, ipairs, unpack
local max, min, abs = math.max, math.min, math.abs

-- =====================================================================
-- CelestialRecruiter  --  Reusable Filter Bar Widget
-- Exposes W.MakeFilterBar(parent, context, onChanged)
-- Two-row panel (82px) with class buttons, level range, status chips,
-- source/race dropdowns, cross-realm/opt-in checkboxes, and reset.
-- =====================================================================

local PANEL_H = 82  -- fully expanded height
local CLASS_BTN_SIZE = 22
local CLASS_BTN_GAP = 2
local CHIP_W = 68
local CHIP_H = 20
local LERP_SPEED = 10

-- 2-letter abbreviations for class buttons
local CLASS_ABBR = {
    WARRIOR     = "GU",
    PALADIN     = "PA",
    HUNTER      = "CH",
    ROGUE       = "VO",
    PRIEST      = "PR",
    DEATHKNIGHT = "DK",
    SHAMAN      = "SA",
    MAGE        = "MA",
    WARLOCK     = "DE",
    MONK        = "MO",
    DRUID       = "DR",
    DEMONHUNTER = "DH",
    EVOKER      = "EV",
}

-- Status chips: key, French label, color, tooltip
local STATUS_CHIPS = {
    { key = "new",       label = "Nouv.",    color = {C.accent[1], C.accent[2], C.accent[3]}, tip = "Joueurs jamais contactes." },
    { key = "contacted", label = "Contact\195\169", color = {C.orange[1], C.orange[2], C.orange[3]}, tip = "Joueurs deja contactes par message." },
    { key = "invited",   label = "Invit\195\169",   color = {C.green[1],  C.green[2],  C.green[3]}, tip = "Joueurs invites dans la guilde." },
    { key = "joined",    label = "Rejoint",  color = {C.gold[1],   C.gold[2],   C.gold[3]}, tip = "Joueurs ayant rejoint la guilde." },
    { key = "ignored",   label = "Ignor\195\169",   color = {C.muted[1],  C.muted[2],  C.muted[3]}, tip = "Joueurs temporairement ignores." },
}

---------------------------------------------------------------------------
-- Helper: make a small toggle button (class or status chip)
---------------------------------------------------------------------------
local function MakeToggle(parent, w, h)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetBackdrop({
        bgFile = SOLID, edgeFile = EDGE,
        edgeSize = 6, insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    btn.t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.t:SetPoint("CENTER")
    btn:EnableMouse(true)
    return btn
end

---------------------------------------------------------------------------
-- W.MakeFilterBar(parent, context, onChanged)
--   parent    : the tab panel frame
--   context   : "queue" or "inbox" (for independent expand state)
--   onChanged : callback(effectiveHeight) called when filters change or
--               the panel animates (so the caller can reposition scroll)
--
-- Returns fb object with :Toggle(), :SyncFromFilters(), :GetEffectiveHeight()
---------------------------------------------------------------------------
function W.MakeFilterBar(parent, context, onChanged)
    local Filters = ns.Filters

    local fb = {}
    fb.expanded = false
    fb._targetH = 0
    fb._currentH = 0

    ---------------------------------------------------------------------------
    -- Outer clipping container
    ---------------------------------------------------------------------------
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(0)
    container:SetPoint("TOPLEFT", 8, -44)
    container:SetPoint("TOPRIGHT", -8, -44)
    container:SetClipsChildren(true)
    fb.container = container

    ---------------------------------------------------------------------------
    -- Inner content frame (always PANEL_H tall, slides in/out)
    ---------------------------------------------------------------------------
    local content = CreateFrame("Frame", nil, container, "BackdropTemplate")
    content:SetHeight(PANEL_H)
    content:SetPoint("TOPLEFT")
    content:SetPoint("TOPRIGHT")
    content:SetBackdrop({bgFile = SOLID})
    content:SetBackdropColor(0.06, 0.07, 0.13, 0.85)
    fb.content = content

    -- Subtle bottom border
    local botLine = content:CreateTexture(nil, "OVERLAY")
    botLine:SetTexture(SOLID)
    botLine:SetHeight(1)
    botLine:SetPoint("BOTTOMLEFT")
    botLine:SetPoint("BOTTOMRIGHT")
    botLine:SetVertexColor(C.border[1], C.border[2], C.border[3], 0.3)

    ---------------------------------------------------------------------------
    -- ROW 1: Class buttons + Level range  (y offset = -4 from top)
    ---------------------------------------------------------------------------
    local row1Y = -4
    local classBtns = {}
    fb.classBtns = classBtns

    local classes = Filters.availableClasses
    if not classes or #classes == 0 then
        -- Fallback: init wasn't called yet, we'll sync later
        classes = {}
    end

    local xOff = 6
    for i, cls in ipairs(classes) do
        local btn = MakeToggle(content, CLASS_BTN_SIZE, CLASS_BTN_SIZE)
        btn:SetPoint("TOPLEFT", xOff, row1Y)
        xOff = xOff + CLASS_BTN_SIZE + CLASS_BTN_GAP

        local cr, cg, cb = W.classRGB(cls.file)
        btn._classFile = cls.file
        btn._cr, btn._cg, btn._cb = cr, cg, cb

        -- Label: 2-letter abbreviation
        local abbr = CLASS_ABBR[cls.file] or cls.name:sub(1, 2):upper()
        btn.t:SetText(abbr)
        btn.t:SetFont(btn.t:GetFont(), 9, "OUTLINE")

        -- Default inactive look
        btn:SetBackdropColor(cr * 0.25, cg * 0.25, cb * 0.25, 0.7)
        btn:SetBackdropBorderColor(cr * 0.5, cg * 0.5, cb * 0.5, 0.5)
        btn.t:SetTextColor(cr, cg, cb, 0.8)
        btn._active = false

        -- Tooltip
        btn:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(cls.name)
            GameTooltip:Show()
            if not s._active then
                s:SetBackdropColor(cr * 0.35, cg * 0.35, cb * 0.35, 0.85)
            end
        end)
        btn:SetScript("OnLeave", function(s)
            GameTooltip:Hide()
            if not s._active then
                s:SetBackdropColor(cr * 0.25, cg * 0.25, cb * 0.25, 0.7)
            end
        end)

        btn:SetScript("OnClick", function(s)
            Filters:ToggleClass(cls.file)
            fb:SyncFromFilters()
            if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
        end)

        classBtns[cls.file] = btn
    end

    -- Level range: label + 2 editboxes
    local lvlLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lvlLabel:SetPoint("TOPLEFT", xOff + 10, row1Y - 4)
    lvlLabel:SetText("Niv")
    lvlLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    local function makeLvlBox(anchorTo, anchorPoint, offsetX)
        local eb = CreateFrame("EditBox", nil, content, "BackdropTemplate")
        eb:SetSize(40, 20)
        eb:SetPoint("LEFT", anchorTo, anchorPoint, offsetX, 0)
        eb:SetBackdrop({
            bgFile = SOLID, edgeFile = EDGE,
            edgeSize = 6, insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        eb:SetBackdropColor(0.05, 0.06, 0.11, 0.85)
        eb:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
        eb:SetFontObject(GameFontHighlightSmall)
        eb:SetTextInsets(4, 4, 0, 0)
        eb:SetAutoFocus(false)
        eb:SetNumeric(true)
        eb:SetMaxLetters(3)
        eb:SetScript("OnEditFocusGained", function(s)
            s:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
        end)
        eb:SetScript("OnEditFocusLost", function(s)
            s:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.4)
        end)
        return eb
    end

    fb.lvlMinEB = makeLvlBox(lvlLabel, "RIGHT", 6)
    local dash = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dash:SetPoint("LEFT", fb.lvlMinEB, "RIGHT", 3, 0)
    dash:SetText("-")
    dash:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    fb.lvlMaxEB = makeLvlBox(dash, "RIGHT", 3)

    local function applyLevelRange()
        local minV = tonumber(fb.lvlMinEB:GetText())
        local maxV = tonumber(fb.lvlMaxEB:GetText())
        if minV and minV <= 0 then minV = nil end
        if maxV and maxV <= 0 then maxV = nil end
        Filters:SetLevelRange(minV, maxV)
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end
    fb.lvlMinEB:SetScript("OnEnterPressed", function(s) s:ClearFocus(); applyLevelRange() end)
    fb.lvlMinEB:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    fb.lvlMaxEB:SetScript("OnEnterPressed", function(s) s:ClearFocus(); applyLevelRange() end)
    fb.lvlMaxEB:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)

    ---------------------------------------------------------------------------
    -- ROW 2: Status chips, Source DD, xRealm, OptIn, Race DD, Reset
    ---------------------------------------------------------------------------
    local row2Y = -(CLASS_BTN_SIZE + 10)

    -- Status chips
    local chipBtns = {}
    fb.chipBtns = chipBtns
    local chipX = 6

    for _, chip in ipairs(STATUS_CHIPS) do
        local btn = MakeToggle(content, CHIP_W, CHIP_H)
        btn:SetPoint("TOPLEFT", chipX, row2Y)
        chipX = chipX + CHIP_W + 3

        -- Colored dot
        btn.dot = btn:CreateTexture(nil, "OVERLAY")
        btn.dot:SetTexture(SOLID)
        btn.dot:SetSize(6, 6)
        btn.dot:SetPoint("LEFT", 5, 0)
        btn.dot:SetVertexColor(chip.color[1], chip.color[2], chip.color[3])

        btn.t:SetPoint("CENTER", 4, 0)
        btn.t:SetText(chip.label)
        btn.t:SetFont(btn.t:GetFont(), 9)
        btn._chipKey = chip.key
        btn._chipColor = chip.color
        btn._active = false

        -- Default inactive
        btn:SetBackdropColor(0.08, 0.09, 0.15, 0.7)
        btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)
        btn.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        btn:SetScript("OnEnter", function(s)
            if not s._active then
                s:SetBackdropColor(0.12, 0.14, 0.22, 0.85)
            end
        end)
        btn:SetScript("OnLeave", function(s)
            if not s._active then
                s:SetBackdropColor(0.08, 0.09, 0.15, 0.7)
            end
        end)
        btn:SetScript("OnClick", function(s)
            Filters:ToggleStatus(chip.key)
            fb:SyncFromFilters()
            if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
        end)

        W.AddTooltip(btn, chip.label, chip.tip)

        chipBtns[chip.key] = btn
    end

    -- Source dropdown
    local sourceItems = {
        {value = "_all",    label = "Source"},
        {value = "scanner", label = "Scanner"},
        {value = "inbox",   label = "Boite"},
    }
    fb.sourceDD = W.MakeDropdown(content, 80, sourceItems, "_all", function(v)
        Filters.active.source = (v ~= "_all") and v or nil
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end)
    fb.sourceDD:SetPoint("TOPLEFT", chipX + 4, row2Y)
    W.AddTooltip(fb.sourceDD, "Source", "Filtrer par origine du contact (scanner ou boite).")

    -- Cross-realm checkbox
    fb.xRealmCheck = W.MakeCheck(content, "Inter-r.", function()
        return Filters.active.crossRealm == true
    end, function(v)
        Filters:SetCrossRealm(v and true or nil)
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end)
    fb.xRealmCheck:SetPoint("LEFT", fb.sourceDD, "RIGHT", 10, 0)
    W.AddTooltip(fb.xRealmCheck, "Inter-royaume", "N'afficher que les joueurs d'autres royaumes.")

    -- Opt-in checkbox
    fb.optInCheck = W.MakeCheck(content, "Opt-in", function()
        return Filters.active.optedIn == true
    end, function(v)
        Filters:SetOptedIn(v and true or nil)
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end)
    fb.optInCheck:SetPoint("LEFT", fb.xRealmCheck.label, "RIGHT", 10, 0)
    W.AddTooltip(fb.optInCheck, "Opt-in", "N'afficher que les joueurs ayant utilise le mot cle.")

    -- Race dropdown (populated dynamically)
    local raceItems = {{value = "_all", label = "Race"}}
    fb.raceDD = W.MakeDropdown(content, 90, raceItems, "_all", function(v)
        -- Clear all race filters, then toggle if specific
        Filters.active.races = {}
        if v ~= "_all" then
            Filters.active.races[v] = true
        end
        fb:SyncFromFilters()
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end)
    fb.raceDD:SetPoint("LEFT", fb.optInCheck.label, "RIGHT", 10, 0)

    -- Reset button
    fb.resetBtn = W.MakeBtn(content, "Reset", 58, "d", function()
        Filters:Reset()
        fb:SyncFromFilters()
        if onChanged then onChanged(fb:GetEffectiveHeight(), true) end
    end)
    fb.resetBtn:SetPoint("LEFT", fb.raceDD, "RIGHT", 6, 0)
    W.AddTooltip(fb.resetBtn, "Reset filtres", "Reinitialise tous les filtres actifs.")

    ---------------------------------------------------------------------------
    -- Refresh race dropdown items dynamically
    ---------------------------------------------------------------------------
    function fb:RefreshRaceDropdown()
        local races = Filters:GetAvailableRaces()
        local items = {{value = "_all", label = "Race"}}
        for _, race in ipairs(races) do
            items[#items + 1] = {value = race, label = race}
        end

        -- Recreate dropdown (simple approach: destroy old, create new)
        local oldDD = self.raceDD
        local anchorTo = self.optInCheck.label
        local newDD = W.MakeDropdown(content, 90, items, "_all", function(v)
            Filters.active.races = {}
            if v ~= "_all" then
                Filters.active.races[v] = true
            end
            self:SyncFromFilters()
            if onChanged then onChanged(self:GetEffectiveHeight(), true) end
        end)
        newDD:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
        self.raceDD = newDD
        self.resetBtn:ClearAllPoints()
        self.resetBtn:SetPoint("LEFT", newDD, "RIGHT", 6, 0)
        oldDD:Hide()
    end

    ---------------------------------------------------------------------------
    -- Animation: OnUpdate lerp for height
    ---------------------------------------------------------------------------
    container:SetScript("OnUpdate", function(self, elapsed)
        local diff = fb._targetH - fb._currentH
        if abs(diff) < 0.5 then
            fb._currentH = fb._targetH
        else
            fb._currentH = fb._currentH + diff * min(1, elapsed * LERP_SPEED)
        end

        self:SetHeight(max(0.1, fb._currentH))

        -- Fade content alpha proportionally
        local alpha = fb._targetH > 0 and (fb._currentH / PANEL_H) or 0
        content:SetAlpha(max(0, min(1, alpha)))

        -- Continuously notify parent of height changes during animation
        if abs(diff) >= 0.5 and onChanged then
            onChanged(fb._currentH)
        end
    end)

    ---------------------------------------------------------------------------
    -- SyncFromFilters: update visual state from Filters.active
    ---------------------------------------------------------------------------
    function fb:SyncFromFilters()
        -- Class buttons
        for file, btn in pairs(classBtns) do
            local active = Filters.active.classes[file] and true or false
            btn._active = active
            local cr, cg, cb = btn._cr, btn._cg, btn._cb
            if active then
                btn:SetBackdropColor(cr * 0.35, cg * 0.35, cb * 0.35, 0.95)
                btn:SetBackdropBorderColor(cr, cg, cb, 0.9)
                btn.t:SetTextColor(1, 1, 1, 1)
            else
                btn:SetBackdropColor(cr * 0.25, cg * 0.25, cb * 0.25, 0.7)
                btn:SetBackdropBorderColor(cr * 0.5, cg * 0.5, cb * 0.5, 0.5)
                btn.t:SetTextColor(cr, cg, cb, 0.8)
            end
        end

        -- Status chips
        for key, btn in pairs(chipBtns) do
            local active = Filters.active.status[key] and true or false
            btn._active = active
            local col = btn._chipColor
            if active then
                btn:SetBackdropColor(col[1] * 0.25, col[2] * 0.25, col[3] * 0.25, 0.9)
                btn:SetBackdropBorderColor(col[1], col[2], col[3], 0.7)
                btn.t:SetTextColor(col[1], col[2], col[3])
            else
                btn:SetBackdropColor(0.08, 0.09, 0.15, 0.7)
                btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)
                btn.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            end
        end

        -- Level range
        if Filters.active.levelMin then
            fb.lvlMinEB:SetText(tostring(Filters.active.levelMin))
        else
            fb.lvlMinEB:SetText("")
        end
        if Filters.active.levelMax then
            fb.lvlMaxEB:SetText(tostring(Filters.active.levelMax))
        else
            fb.lvlMaxEB:SetText("")
        end

        -- Source dropdown
        fb.sourceDD:SetVal(Filters.active.source or "_all")

        -- Checkboxes
        fb.xRealmCheck:SetChecked(Filters.active.crossRealm == true)
        fb.optInCheck:SetChecked(Filters.active.optedIn == true)

        -- Race dropdown
        local activeRace = "_all"
        for race in pairs(Filters.active.races) do
            activeRace = race
            break
        end
        fb.raceDD:SetVal(activeRace)
    end

    ---------------------------------------------------------------------------
    -- Toggle expand / collapse
    ---------------------------------------------------------------------------
    function fb:Toggle()
        self.expanded = not self.expanded
        self._targetH = self.expanded and PANEL_H or 0
        -- Refresh race dropdown when expanding
        if self.expanded then
            self:RefreshRaceDropdown()
            self:SyncFromFilters()
        end
    end

    ---------------------------------------------------------------------------
    -- GetEffectiveHeight
    ---------------------------------------------------------------------------
    function fb:GetEffectiveHeight()
        return self.expanded and PANEL_H or 0
    end

    -- Initial sync
    fb:SyncFromFilters()

    return fb
end
