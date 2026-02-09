local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Minimap Button with Queue Count Badge
-- ═══════════════════════════════════════════════════════════════════

local ICON = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend"
local btn, badge

local function UpdatePosition()
    local angle = ns.db and ns.db.profile.minimapAngle or 220
    local rad = math.rad(angle)
    local r = 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", r * math.cos(rad), r * math.sin(rad))
end

local function UpdateBadge()
    if not badge then return end
    local n = ns.DB_QueueList and #ns.DB_QueueList() or 0
    if n > 0 then
        badge:SetText(n)
        badge:Show()
    else
        badge:Hide()
    end
end

function ns.Minimap_Init()
    if btn then return end

    btn = CreateFrame("Button", "CelestialRecruiterMinimapBtn", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Standard minimap button border
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("CENTER")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON)

    -- Queue count badge
    badge = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    badge:SetPoint("BOTTOM", 0, 2)
    badge:SetTextColor(1, 0.84, 0)
    badge:Hide()

    -- Click handlers
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if ns.Scanner_ScanStep then
                ns.Scanner_ScanStep(false)
            end
        else
            ns.UI_Toggle()
        end
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("CelestialRecruiter")
        local qn = ns.DB_QueueList and #ns.DB_QueueList() or 0
        GameTooltip:AddDoubleLine("File d'attente:", tostring(qn), 0.55, 0.58, 0.66, 1, 0.84, 0)
        local st = ns.Scanner_GetStats and ns.Scanner_GetStats() or {}
        if st.scanning then
            GameTooltip:AddDoubleLine("Scanner:", "actif", 0.55, 0.58, 0.66, 0, 0.68, 1)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00d1ffClic gauche:|r Ouvrir/fermer", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00d1ffClic droit:|r Lancer un scan", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Drag to reposition around minimap
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function()
        btn._dragging = true
    end)
    btn:SetScript("OnDragStop", function()
        btn._dragging = false
    end)
    btn:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if ns.db and ns.db.profile then
            ns.db.profile.minimapAngle = angle
        end
        UpdatePosition()
    end)

    UpdatePosition()
    UpdateBadge()

    if ns.db and ns.db.profile and ns.db.profile.showMinimapButton == false then
        btn:Hide()
    end
end

function ns.Minimap_UpdateBadge()
    UpdateBadge()
end

function ns.Minimap_SetShown(show)
    if btn then btn:SetShown(show) end
end
