local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Analytics Tab with Interactive Charts
-- Beautiful data visualizations for recruitment insights
-- ═══════════════════════════════════════════════════════════════════

local ad = {}  -- analytics data references

---------------------------------------------------------------------------
-- Build Analytics Tab
---------------------------------------------------------------------------
function ns.UI_BuildAnalytics(panel)
    local scroll = W.MakeScroll(panel)
    scroll.frame:SetPoint("TOPLEFT", 8, -8)
    scroll.frame:SetPoint("BOTTOMRIGHT", -8, 8)

    local content = scroll.child
    local yOffset = -10
    local chartWidth = 860  -- safe default width

    -- Header
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetText("|TInterface\\Icons\\INV_Misc_StoneTablet_05:14:14:0:0|t Analytiques et apercu")
    header:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    yOffset = yOffset - 40

    -- ═══════════════════════════════════════════════════
    -- Section 1: Summary Cards
    -- ═══════════════════════════════════════════════════
    local summaryLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryLabel:SetPoint("TOPLEFT", 16, yOffset)
    summaryLabel:SetText("|TInterface\\Icons\\Spell_Holy_BorrowedTime:14:14:0:0|t Resume global")
    summaryLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 30

    -- Create 4 stat cards
    local cardW = 200
    local cardH = 60
    local cardSpacing = 10
    ad.cards = {}

    local cardDefs = {
        {key = "contacted", label = "Contactes",  icon = "|TInterface\\Icons\\INV_Letter_15:14:14:0:0|t", color = C.accent},
        {key = "invited",   label = "Invites",    icon = "|TInterface\\Icons\\Spell_ChargePositive:14:14:0:0|t", color = C.green},
        {key = "joined",    label = "Recrues",    icon = "|TInterface\\Icons\\Achievement_GuildPerk_EverybodysFriend:14:14:0:0|t", color = C.gold},
        {key = "conversion",label = "Conversion", icon = "|TInterface\\Icons\\INV_Misc_EngGizmos_20:14:14:0:0|t", color = {1, 0.41, 0.71}},
    }

    for i, def in ipairs(cardDefs) do
        local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
        card:SetSize(cardW, cardH)
        card:SetPoint("TOPLEFT", 16 + (i - 1) * (cardW + cardSpacing), yOffset)
        card:SetBackdrop({
            bgFile = W.SOLID, edgeFile = W.EDGE,
            edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        card:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.8)
        card:SetBackdropBorderColor(def.color[1], def.color[2], def.color[3], 0.4)

        -- Accent bar on left
        local bar = card:CreateTexture(nil, "OVERLAY")
        bar:SetTexture(W.SOLID)
        bar:SetWidth(3)
        bar:SetPoint("TOPLEFT", 3, -3)
        bar:SetPoint("BOTTOMLEFT", 3, 3)
        bar:SetVertexColor(def.color[1], def.color[2], def.color[3], 0.8)

        -- Icon
        local icon = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon:SetPoint("LEFT", 14, 0)
        icon:SetText(def.icon)

        -- Value (big number)
        local value = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        value:SetPoint("TOPLEFT", 40, -8)
        value:SetText("0")
        value:SetTextColor(C.text[1], C.text[2], C.text[3])

        -- Label
        local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", 40, 8)
        label:SetText(def.label)
        label:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        ad.cards[def.key] = {frame = card, value = value, label = label}
    end

    yOffset = yOffset - cardH - 20

    -- ═══════════════════════════════════════════════════
    -- Section 2: Conversion Funnel (Bar Chart)
    -- ═══════════════════════════════════════════════════
    local funnelLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    funnelLabel:SetPoint("TOPLEFT", 16, yOffset)
    funnelLabel:SetText("|TInterface\\Icons\\INV_Misc_EngGizmos_20:14:14:0:0|t Entonnoir de conversion")
    funnelLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    -- Funnel visual (horizontal bars showing pipeline)
    ad.funnelBars = {}
    local funnelDefs = {
        {key = "contacted", label = "Contactes",  color = C.accent},
        {key = "invited",   label = "Invites",    color = C.orange},
        {key = "joined",    label = "Recrues",    color = C.green},
    }

    for i, def in ipairs(funnelDefs) do
        local barH = 28
        local barFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        barFrame:SetSize(chartWidth - 40, barH)
        barFrame:SetPoint("TOPLEFT", 20, yOffset)
        barFrame:SetBackdrop({bgFile = W.SOLID})
        barFrame:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.5)

        -- Fill bar
        local fill = barFrame:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(W.SOLID)
        fill:SetPoint("TOPLEFT", 0, 0)
        fill:SetPoint("BOTTOMLEFT", 0, 0)
        fill:SetWidth(1)
        fill:SetVertexColor(def.color[1], def.color[2], def.color[3], 0.7)

        -- Label
        local lbl = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", 8, 0)
        lbl:SetTextColor(C.text[1], C.text[2], C.text[3])
        lbl:SetText(def.label .. ": 0")

        -- Percentage
        local pct = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pct:SetPoint("RIGHT", -8, 0)
        pct:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        pct:SetText("0%")

        ad.funnelBars[def.key] = {frame = barFrame, fill = fill, label = lbl, pct = pct}
        yOffset = yOffset - barH - 4
    end

    yOffset = yOffset - 15

    -- ═══════════════════════════════════════════════════
    -- Section 3: Best Hours (Heatmap-style bar chart)
    -- ═══════════════════════════════════════════════════
    local hoursLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hoursLabel:SetPoint("TOPLEFT", 16, yOffset)
    hoursLabel:SetText("|TInterface\\Icons\\INV_Misc_PocketWatch_01:14:14:0:0|t Meilleurs horaires de recrutement")
    hoursLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.hourBars = {}
    local hourBarW = math.floor((chartWidth - 40) / 24)
    local hourBarMaxH = 80

    for h = 0, 23 do
        local barFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        barFrame:SetSize(hourBarW - 1, hourBarMaxH)
        barFrame:SetPoint("BOTTOMLEFT", 20 + h * hourBarW, yOffset - hourBarMaxH)
        barFrame:SetBackdrop({bgFile = W.SOLID})
        barFrame:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.3)

        -- Fill bar (grows from bottom)
        local fill = barFrame:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(W.SOLID)
        fill:SetPoint("BOTTOMLEFT", 0, 0)
        fill:SetPoint("BOTTOMRIGHT", 0, 0)
        fill:SetHeight(1)
        fill:SetVertexColor(C.green[1], C.green[2], C.green[3], 0.7)

        -- Hour label
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOP", barFrame, "BOTTOM", 0, -2)
        lbl:SetText(string.format("%02d", h))
        lbl:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

        -- Tooltip
        barFrame:EnableMouse(true)
        barFrame._hour = h
        barFrame._fill = fill
        barFrame:SetScript("OnEnter", function(self)
            self._fill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(string.format("%02dh - %02dh", h, h + 1))
            GameTooltip:AddLine("Activite: " .. tostring(self._activity or 0), 1, 1, 1)
            GameTooltip:Show()
        end)
        barFrame:SetScript("OnLeave", function(self)
            self._fill:SetVertexColor(C.green[1], C.green[2], C.green[3], 0.7)
            GameTooltip:Hide()
        end)

        ad.hourBars[h] = {frame = barFrame, fill = fill}
    end

    yOffset = yOffset - hourBarMaxH - 25

    -- ═══════════════════════════════════════════════════
    -- Section 4: Class Distribution
    -- ═══════════════════════════════════════════════════
    local classLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classLabel:SetPoint("TOPLEFT", 16, yOffset)
    classLabel:SetText("|TInterface\\Icons\\Achievement_General_StayClassy:14:14:0:0|t Distribution par classe")
    classLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.classBars = {}
    local classBarH = 22

    local allClasses = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
        "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
        "DRUID", "DEMONHUNTER", "EVOKER"
    }

    for i, classFile in ipairs(allClasses) do
        local barFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        barFrame:SetSize(chartWidth - 40, classBarH)
        barFrame:SetPoint("TOPLEFT", 20, yOffset)
        barFrame:SetBackdrop({bgFile = W.SOLID})
        barFrame:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], (i % 2 == 0) and 0.2 or 0.35)

        -- Fill bar
        local fill = barFrame:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(W.SOLID)
        fill:SetPoint("TOPLEFT", 0, 0)
        fill:SetPoint("BOTTOMLEFT", 0, 0)
        fill:SetWidth(1)

        local cr, cg, cb = W.classRGB(classFile)
        if cr then
            fill:SetVertexColor(cr, cg, cb, 0.6)
        else
            fill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.6)
        end

        -- Class name
        local lbl = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 8, 0)
        if cr then
            lbl:SetTextColor(cr, cg, cb)
        else
            lbl:SetTextColor(C.text[1], C.text[2], C.text[3])
        end
        lbl:SetText(classFile)

        -- Count
        local count = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        count:SetPoint("RIGHT", -8, 0)
        count:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        count:SetText("0")

        ad.classBars[classFile] = {frame = barFrame, fill = fill, label = lbl, count = count}
        yOffset = yOffset - classBarH - 2
    end

    yOffset = yOffset - 15

    -- ═══════════════════════════════════════════════════
    -- Section 5: Template Performance
    -- ═══════════════════════════════════════════════════
    local tplLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tplLabel:SetPoint("TOPLEFT", 16, yOffset)
    tplLabel:SetText("|TInterface\\Icons\\INV_Scroll_02:14:14:0:0|t Performance des templates")
    tplLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.tplContainer = CreateFrame("Frame", nil, content)
    ad.tplContainer:SetSize(chartWidth - 40, 120)
    ad.tplContainer:SetPoint("TOPLEFT", 20, yOffset)
    yOffset = yOffset - 140

    -- ═══════════════════════════════════════════════════
    -- Section 6: Trends (week over week)
    -- ═══════════════════════════════════════════════════
    local trendsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trendsLabel:SetPoint("TOPLEFT", 16, yOffset)
    trendsLabel:SetText("|TInterface\\Icons\\INV_Misc_StoneTablet_05:14:14:0:0|t Tendances (cette semaine vs la precedente)")
    trendsLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 30

    ad.trendCards = {}
    local trendDefs = {
        {key = "contacted", label = "Contactes"},
        {key = "invited",   label = "Invites"},
        {key = "joined",    label = "Recrues"},
    }

    for i, def in ipairs(trendDefs) do
        local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
        card:SetSize(250, 50)
        card:SetPoint("TOPLEFT", 16 + (i - 1) * 260, yOffset)
        card:SetBackdrop({
            bgFile = W.SOLID, edgeFile = W.EDGE,
            edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        card:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.6)
        card:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)

        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 10, -8)
        lbl:SetText(def.label)
        lbl:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local thisWeek = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        thisWeek:SetPoint("BOTTOMLEFT", 10, 8)
        thisWeek:SetText("0")
        thisWeek:SetTextColor(C.text[1], C.text[2], C.text[3])

        local change = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        change:SetPoint("BOTTOMRIGHT", -10, 8)
        change:SetText("+0%")
        change:SetTextColor(C.green[1], C.green[2], C.green[3])

        ad.trendCards[def.key] = {frame = card, thisWeek = thisWeek, change = change}
    end

    yOffset = yOffset - 70

    -- ═══════════════════════════════════════════════════
    -- Section 7: Succes et Progression
    -- ═══════════════════════════════════════════════════
    local goalsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goalsLabel:SetPoint("TOPLEFT", 16, yOffset)
    goalsLabel:SetText("|TInterface\\Icons\\Achievement_General_StayClassy:14:14:0:0|t Succes et Progression")
    goalsLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 30

    -- Achievement progress: "X / 25 succes debloques" with progress bar
    local achProgressFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    achProgressFrame:SetSize(chartWidth - 40, 50)
    achProgressFrame:SetPoint("TOPLEFT", 20, yOffset)
    achProgressFrame:SetBackdrop({
        bgFile = W.SOLID, edgeFile = W.EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    achProgressFrame:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.7)
    achProgressFrame:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.3)

    -- Left accent bar
    local achAccent = achProgressFrame:CreateTexture(nil, "OVERLAY")
    achAccent:SetTexture(W.SOLID)
    achAccent:SetWidth(3)
    achAccent:SetPoint("TOPLEFT", 3, -3)
    achAccent:SetPoint("BOTTOMLEFT", 3, 3)
    achAccent:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.8)

    ad.achProgressText = achProgressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ad.achProgressText:SetPoint("TOPLEFT", 14, -8)
    ad.achProgressText:SetText("|TInterface\\Icons\\Achievement_General_StayClassy:14:14:0:0|t 0 / 25 succes debloques")
    ad.achProgressText:SetTextColor(C.text[1], C.text[2], C.text[3])

    ad.achProgressPct = achProgressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.achProgressPct:SetPoint("TOPRIGHT", -12, -8)
    ad.achProgressPct:SetText("0%")
    ad.achProgressPct:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    -- Full-width progress bar
    local achBarBg = CreateFrame("Frame", nil, achProgressFrame, "BackdropTemplate")
    achBarBg:SetSize(chartWidth - 80, 8)
    achBarBg:SetPoint("BOTTOMLEFT", 14, 8)
    achBarBg:SetBackdrop({bgFile = W.SOLID})
    achBarBg:SetBackdropColor(1, 1, 1, 0.06)

    ad.achBarFill = achBarBg:CreateTexture(nil, "OVERLAY")
    ad.achBarFill:SetTexture(W.SOLID)
    ad.achBarFill:SetPoint("TOPLEFT")
    ad.achBarFill:SetPoint("BOTTOMLEFT")
    ad.achBarFill:SetWidth(1)
    ad.achBarFill:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.8)
    ad._achBarBg = achBarBg

    yOffset = yOffset - 60

    -- Streak display: 3 small cards showing daily login, daily recruit, weekly goal
    ad.streakCards = {}
    local streakDefs = {
        {key = "dailyLogin",   label = "Connexion",   icon = "|TInterface\\Icons\\Spell_Holy_BorrowedTime:14:14:0:0|t"},
        {key = "dailyRecruit", label = "Recrutement", icon = "|TInterface\\Icons\\Ability_Warrior_BattleShout:14:14:0:0|t"},
        {key = "weeklyGoal",   label = "Semaine",     icon = "|TInterface\\Icons\\Achievement_General_StayClassy:14:14:0:0|t"},
    }
    local streakCardW = math.floor((chartWidth - 60) / 3)
    local streakCardH = 55

    for i, def in ipairs(streakDefs) do
        local sCard = CreateFrame("Frame", nil, content, "BackdropTemplate")
        sCard:SetSize(streakCardW, streakCardH)
        sCard:SetPoint("TOPLEFT", 20 + (i - 1) * (streakCardW + 10), yOffset)
        sCard:SetBackdrop({
            bgFile = W.SOLID, edgeFile = W.EDGE,
            edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        sCard:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.6)
        sCard:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)

        local sIcon = sCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sIcon:SetPoint("TOPLEFT", 8, -6)
        sIcon:SetText(def.icon .. " " .. def.label)
        sIcon:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local sCurrent = sCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        sCurrent:SetPoint("BOTTOMLEFT", 10, 8)
        sCurrent:SetText("0j")
        sCurrent:SetTextColor(C.green[1], C.green[2], C.green[3])

        local sBest = sCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sBest:SetPoint("BOTTOMRIGHT", -8, 10)
        sBest:SetText("max: 0")
        sBest:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

        ad.streakCards[def.key] = {frame = sCard, current = sCurrent, best = sBest}
    end

    yOffset = yOffset - streakCardH - 15

    -- Next milestone: name + progress bar + "X remaining"
    local milestoneFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    milestoneFrame:SetSize(chartWidth - 40, 42)
    milestoneFrame:SetPoint("TOPLEFT", 20, yOffset)
    milestoneFrame:SetBackdrop({
        bgFile = W.SOLID, edgeFile = W.EDGE,
        edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    milestoneFrame:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.5)
    milestoneFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.25)

    ad.milestoneTitle = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.milestoneTitle:SetPoint("TOPLEFT", 10, -6)
    ad.milestoneTitle:SetText("Prochain objectif : -")
    ad.milestoneTitle:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

    ad.milestoneRemaining = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.milestoneRemaining:SetPoint("TOPRIGHT", -10, -6)
    ad.milestoneRemaining:SetText("")
    ad.milestoneRemaining:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Milestone progress bar
    local msBarBg = CreateFrame("Frame", nil, milestoneFrame, "BackdropTemplate")
    msBarBg:SetSize(chartWidth - 80, 6)
    msBarBg:SetPoint("BOTTOMLEFT", 10, 8)
    msBarBg:SetBackdrop({bgFile = W.SOLID})
    msBarBg:SetBackdropColor(1, 1, 1, 0.06)

    ad.msBarFill = msBarBg:CreateTexture(nil, "OVERLAY")
    ad.msBarFill:SetTexture(W.SOLID)
    ad.msBarFill:SetPoint("TOPLEFT")
    ad.msBarFill:SetPoint("BOTTOMLEFT")
    ad.msBarFill:SetWidth(1)
    ad.msBarFill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    ad._msBarBg = msBarBg

    yOffset = yOffset - 52

    -- Recent achievements: last 5 unlocked with name, icon, and unlock date
    local recentAchLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recentAchLabel:SetPoint("TOPLEFT", 20, yOffset)
    recentAchLabel:SetText("Succes recents:")
    recentAchLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    yOffset = yOffset - 18

    ad.recentAchRows = {}
    local achRowH = 24
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(chartWidth - 40, achRowH)
        row:SetPoint("TOPLEFT", 20, yOffset)
        row:SetBackdrop({bgFile = W.SOLID})
        row:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], (i % 2 == 0) and 0.2 or 0.35)

        local achIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        achIcon:SetPoint("LEFT", 8, 0)
        achIcon:SetText("")
        achIcon:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

        local achName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        achName:SetPoint("LEFT", 30, 0)
        achName:SetText("")
        achName:SetTextColor(C.text[1], C.text[2], C.text[3])

        local achDate = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        achDate:SetPoint("RIGHT", -8, 0)
        achDate:SetText("")
        achDate:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

        ad.recentAchRows[i] = {row = row, icon = achIcon, name = achName, date = achDate}
        row:Hide()

        yOffset = yOffset - achRowH - 2
    end

    yOffset = yOffset - 15

    -- ═══════════════════════════════════════════════════
    -- Section 8: Dashboard Widgets
    -- ═══════════════════════════════════════════════════
    local widgetsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widgetsLabel:SetPoint("TOPLEFT", 16, yOffset)
    widgetsLabel:SetText("|TInterface\\Icons\\Trade_Engineering:14:14:0:0|t Tableau de bord")
    widgetsLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 30

    -- Dashboard widgets container
    if ns.DashboardWidgets and ns.DashboardWidgets.Build then
        local widgetContainer = CreateFrame("Frame", nil, content)
        widgetContainer:SetPoint("TOPLEFT", 16, yOffset)
        widgetContainer:SetPoint("RIGHT", content, "RIGHT", -16, 0)
        widgetContainer:SetWidth(chartWidth - 40)

        local widgetHeight = ns.DashboardWidgets:Build(widgetContainer)
        widgetContainer:SetHeight(widgetHeight)
        yOffset = yOffset - widgetHeight - 20
        ad._widgetContainer = widgetContainer
    end

    -- ═══════════════════════════════════════════════════
    -- Section 9: A/B Test Results
    -- ═══════════════════════════════════════════════════
    local abLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abLabel:SetPoint("TOPLEFT", 16, yOffset)
    abLabel:SetText("|TInterface\\Icons\\INV_Alchemy_Potion_02:14:14:0:0|t Tests A/B")
    abLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.abContainer = CreateFrame("Frame", nil, content)
    ad.abContainer:SetPoint("TOPLEFT", 20, yOffset)
    ad.abContainer:SetSize(chartWidth - 40, 180)

    -- A/B Test info
    ad.abTestInfo = ad.abContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.abTestInfo:SetPoint("TOPLEFT", 0, 0)
    ad.abTestInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.abTestInfo:SetText("Aucun test A/B configure.")

    ad.abVariantRows = {}
    for i = 1, 5 do
        local y = -(i - 1) * 30 - 20
        local row = CreateFrame("Frame", nil, ad.abContainer, "BackdropTemplate")
        row:SetSize(chartWidth - 40, 26)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetBackdrop({bgFile = W.SOLID})
        row:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], (i % 2 == 0) and 0.2 or 0.35)

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("LEFT", 8, 0)
        name:SetTextColor(C.text[1], C.text[2], C.text[3])

        local sent = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sent:SetPoint("LEFT", 120, 0)
        sent:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local replies = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        replies:SetPoint("LEFT", 200, 0)
        replies:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local joined = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        joined:SetPoint("LEFT", 280, 0)
        joined:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local rate = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rate:SetPoint("LEFT", 360, 0)
        rate:SetTextColor(C.green[1], C.green[2], C.green[3])

        local fill = row:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(W.SOLID)
        fill:SetPoint("TOPLEFT", 440, -2)
        fill:SetPoint("BOTTOMLEFT", 440, 2)
        fill:SetWidth(1)
        fill:SetVertexColor(C.purple[1], C.purple[2], C.purple[3], 0.5)

        ad.abVariantRows[i] = {row = row, name = name, sent = sent, replies = replies, joined = joined, rate = rate, fill = fill}
        row:Hide()
    end

    yOffset = yOffset - 200

    -- ═══════════════════════════════════════════════════
    -- Section 10: Campaign Overview
    -- ═══════════════════════════════════════════════════
    local campLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    campLabel:SetPoint("TOPLEFT", 16, yOffset)
    campLabel:SetText("|TInterface\\Icons\\INV_Banner_02:14:14:0:0|t Campagnes de recrutement")
    campLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.campContainer = CreateFrame("Frame", nil, content)
    ad.campContainer:SetPoint("TOPLEFT", 20, yOffset)
    ad.campContainer:SetSize(chartWidth - 40, 200)

    ad.campInfo = ad.campContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.campInfo:SetPoint("TOPLEFT", 0, 0)
    ad.campInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.campInfo:SetText("Aucune campagne configuree.")

    ad.campRows = {}
    for i = 1, 5 do
        local y = -(i - 1) * 50 - 20
        local row = CreateFrame("Frame", nil, ad.campContainer, "BackdropTemplate")
        row:SetSize(chartWidth - 40, 46)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetBackdrop({bgFile = W.SOLID, edgeFile = W.EDGE, edgeSize = 8, insets = {left = 2, right = 2, top = 2, bottom = 2}})
        row:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.6)
        row:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", 10, -6)
        name:SetTextColor(C.text[1], C.text[2], C.text[3])

        local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("TOPRIGHT", -10, -6)
        status:SetTextColor(C.green[1], C.green[2], C.green[3])

        local stats = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        stats:SetPoint("BOTTOMLEFT", 10, 6)
        stats:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        -- Progress bar
        local barBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
        barBg:SetSize(200, 5)
        barBg:SetPoint("BOTTOMRIGHT", -10, 8)
        barBg:SetBackdrop({bgFile = W.SOLID})
        barBg:SetBackdropColor(1, 1, 1, 0.06)

        local barFill = barBg:CreateTexture(nil, "OVERLAY")
        barFill:SetTexture(W.SOLID)
        barFill:SetPoint("TOPLEFT")
        barFill:SetPoint("BOTTOMLEFT")
        barFill:SetWidth(1)
        barFill:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.8)

        ad.campRows[i] = {row = row, name = name, status = status, stats = stats, barBg = barBg, barFill = barFill}
        row:Hide()
    end

    yOffset = yOffset - 280

    -- ═══════════════════════════════════════════════════
    -- Section 11: Classement Guilde
    -- ═══════════════════════════════════════════════════
    local guildLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildLabel:SetPoint("TOPLEFT", 16, yOffset)
    guildLabel:SetText("|TInterface\\Icons\\Achievement_GuildPerk_EverybodysFriend:14:14:0:0|t Classement Guilde")
    guildLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.guildInfo = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.guildInfo:SetPoint("TOPLEFT", 20, yOffset)
    ad.guildInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.guildInfo:SetText("Classement des recruteurs de la guilde utilisant CelestialRecruiter.")
    yOffset = yOffset - 20

    -- Header row
    local guildHeaderRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    guildHeaderRow:SetSize(chartWidth - 40, 22)
    guildHeaderRow:SetPoint("TOPLEFT", 20, yOffset)
    guildHeaderRow:SetBackdrop({bgFile = W.SOLID})
    guildHeaderRow:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.15)

    local ghRank = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghRank:SetPoint("LEFT", 8, 0); ghRank:SetWidth(30); ghRank:SetText("#")
    ghRank:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    local ghName = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghName:SetPoint("LEFT", 42, 0); ghName:SetWidth(180); ghName:SetText("Joueur")
    ghName:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    local ghTier = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghTier:SetPoint("LEFT", 226, 0); ghTier:SetWidth(80); ghTier:SetText("Palier")
    ghTier:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    local ghJoined = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghJoined:SetPoint("LEFT", 310, 0); ghJoined:SetWidth(80); ghJoined:SetText("Recrues")
    ghJoined:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    local ghContacted = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghContacted:SetPoint("LEFT", 394, 0); ghContacted:SetWidth(80); ghContacted:SetText("Contactes")
    ghContacted:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    local ghToday = guildHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ghToday:SetPoint("LEFT", 478, 0); ghToday:SetWidth(100); ghToday:SetText("Aujourd'hui")
    ghToday:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    yOffset = yOffset - 24

    ad.guildRows = {}
    local guildRowH = 26
    for i = 1, 15 do
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(chartWidth - 40, guildRowH)
        row:SetPoint("TOPLEFT", 20, yOffset)
        row:SetBackdrop({bgFile = W.SOLID})
        row:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], (i % 2 == 0) and 0.2 or 0.35)

        local rRank = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rRank:SetPoint("LEFT", 8, 0); rRank:SetWidth(30); rRank:SetJustifyH("CENTER")
        rRank:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

        local rName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rName:SetPoint("LEFT", 42, 0); rName:SetWidth(180); rName:SetJustifyH("LEFT")
        rName:SetWordWrap(false)

        local rTier = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rTier:SetPoint("LEFT", 226, 0); rTier:SetWidth(80); rTier:SetJustifyH("LEFT")

        local rJoined = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rJoined:SetPoint("LEFT", 310, 0); rJoined:SetWidth(80); rJoined:SetJustifyH("CENTER")
        rJoined:SetTextColor(C.green[1], C.green[2], C.green[3])

        local rContacted = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rContacted:SetPoint("LEFT", 394, 0); rContacted:SetWidth(80); rContacted:SetJustifyH("CENTER")
        rContacted:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        local rToday = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rToday:SetPoint("LEFT", 478, 0); rToday:SetWidth(100); rToday:SetJustifyH("CENTER")
        rToday:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

        ad.guildRows[i] = {row = row, rank = rRank, name = rName, tier = rTier, joined = rJoined, contacted = rContacted, today = rToday}
        row:Hide()
        yOffset = yOffset - guildRowH - 1
    end

    yOffset = yOffset - 15

    -- ═══════════════════════════════════════════════════
    -- Section 12: Catalogue des Succes
    -- ═══════════════════════════════════════════════════
    local catalogLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catalogLabel:SetPoint("TOPLEFT", 16, yOffset)
    catalogLabel:SetText("|TInterface\\Icons\\Achievement_General:14:14:0:0|t Catalogue des succes")
    catalogLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.catalogInfo = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.catalogInfo:SetPoint("TOPLEFT", 20, yOffset)
    ad.catalogInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.catalogInfo:SetText("Tous les succes disponibles et leur progression.")
    yOffset = yOffset - 20

    ad.catalogRows = {}
    ad.catalogHeaders = {}
    local catalogRowH = 32

    -- Pre-build 4 category headers + up to 12 rows per category (48 max)
    local catDefs = {
        {key = "recrutement", label = "Recrutement", color = C.accent},
        {key = "social",      label = "Social",      color = C.green},
        {key = "dedication",  label = "Dedication",  color = C.orange},
        {key = "mastery",     label = "Maitrise",    color = C.purple},
    }

    for ci, cat in ipairs(catDefs) do
        local catHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catHeader:SetPoint("TOPLEFT", 20, yOffset)
        catHeader:SetText(cat.label)
        catHeader:SetTextColor(cat.color[1], cat.color[2], cat.color[3])
        ad.catalogHeaders[cat.key] = {header = catHeader, yBase = yOffset}
        yOffset = yOffset - 22

        for i = 1, 12 do
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(chartWidth - 60, catalogRowH)
            row:SetPoint("TOPLEFT", 30, yOffset)
            row:SetBackdrop({bgFile = W.SOLID})
            row:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], (i % 2 == 0) and 0.2 or 0.35)

            -- Left accent bar (colored by unlock status)
            local accentBar = row:CreateTexture(nil, "OVERLAY")
            accentBar:SetTexture(W.SOLID)
            accentBar:SetWidth(3)
            accentBar:SetPoint("TOPLEFT", 0, 0)
            accentBar:SetPoint("BOTTOMLEFT", 0, 0)

            -- Icon placeholder
            local rIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rIcon:SetPoint("LEFT", 8, 0)
            rIcon:SetWidth(24)
            rIcon:SetJustifyH("CENTER")

            -- Name
            local rName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rName:SetPoint("LEFT", 36, 4)
            rName:SetWidth(300)
            rName:SetJustifyH("LEFT")
            rName:SetWordWrap(false)

            -- Description
            local rDesc = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rDesc:SetPoint("LEFT", 36, -8)
            rDesc:SetWidth(400)
            rDesc:SetJustifyH("LEFT")
            rDesc:SetWordWrap(false)

            -- Status (right side)
            local rStatus = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rStatus:SetPoint("RIGHT", -8, 0)
            rStatus:SetWidth(140)
            rStatus:SetJustifyH("RIGHT")

            local rowKey = cat.key .. "_" .. i
            ad.catalogRows[rowKey] = {row = row, icon = rIcon, name = rName, desc = rDesc, status = rStatus, accent = accentBar}
            row:Hide()
            yOffset = yOffset - catalogRowH - 1
        end

        yOffset = yOffset - 10
    end

    yOffset = yOffset - 20

    -- Set scroll content height
    scroll:SetH(math.abs(yOffset) + 20)

    -- Store references
    ns._analyticsData = ad
    ns._analyticsScroll = scroll
end

---------------------------------------------------------------------------
-- Refresh Analytics Data
---------------------------------------------------------------------------
function ns.UI_RefreshAnalytics()
    if not ns.Statistics then return end
    if not ad.cards then return end

    -- 1. Summary Cards — count actual contact statuses from DB (reliable)
    local realContacted, realInvited, realJoined = 0, 0, 0
    if ns.db and ns.db.global and ns.db.global.contacts then
        for _, c in pairs(ns.db.global.contacts) do
            if c.status == "contacted" then
                realContacted = realContacted + 1
            elseif c.status == "invited" then
                realInvited = realInvited + 1
            elseif c.status == "joined" then
                realJoined = realJoined + 1
            end
        end
    end
    -- In the funnel: contacted = everyone we reached out to (contacted + invited + joined)
    -- invited = everyone we guild-invited (invited + joined)
    -- joined = everyone who actually joined
    local funnelContacted = realContacted + realInvited + realJoined
    local funnelInvited = realInvited + realJoined
    local funnelJoined = realJoined
    local conversionPct = funnelContacted > 0 and (funnelJoined / funnelContacted * 100) or 0

    if ad.cards.contacted then
        ad.cards.contacted.value:SetText(tostring(funnelContacted))
    end
    if ad.cards.invited then
        ad.cards.invited.value:SetText(tostring(funnelInvited))
    end
    if ad.cards.joined then
        ad.cards.joined.value:SetText(tostring(funnelJoined))
    end
    if ad.cards.conversion then
        ad.cards.conversion.value:SetText(string.format("%.1f%%", conversionPct))
    end

    -- 2. Conversion Funnel — use same real counts
    if ad.funnelBars then
        local maxVal = math.max(1, funnelContacted)
        local maxWidth = (ad.funnelBars.contacted and ad.funnelBars.contacted.frame:GetWidth()) or 400

        local funnelVals = {
            contacted = funnelContacted,
            invited = funnelInvited,
            joined = funnelJoined,
        }
        local funnelLabels = {
            contacted = "Contactes",
            invited = "Invites",
            joined = "Recrues",
        }
        for _, def in ipairs({"contacted", "invited", "joined"}) do
            local bar = ad.funnelBars[def]
            if bar then
                local val = funnelVals[def] or 0
                local pct = maxVal > 0 and (val / maxVal) or 0
                bar.fill:SetWidth(math.max(1, maxWidth * pct))
                bar.label:SetText((funnelLabels[def] or def) .. ": " .. tostring(val))
                bar.pct:SetText(string.format("%.0f%%", pct * 100))
            end
        end
    end

    -- 3. Best Hours
    if ad.hourBars and ns.Statistics and ns.Statistics.GetBestHours then
        local hOk, bestHours = pcall(ns.Statistics.GetBestHours, ns.Statistics)
        if not hOk or not bestHours then bestHours = {} end
        local hourData = {}
        local maxActivity = 1

        for _, hourInfo in ipairs(bestHours) do
            if hourInfo and hourInfo.hour then
                hourData[hourInfo.hour] = hourInfo.activity or 0
                maxActivity = math.max(maxActivity, hourInfo.activity or 0)
            end
        end

        for h = 0, 23 do
            local bar = ad.hourBars[h]
            if bar then
                local activity = hourData[h] or 0
                bar.frame._activity = activity
                local ratio = activity / maxActivity
                bar.fill:SetHeight(math.max(1, ratio * 78))

                -- Color intensity based on activity
                local intensity = 0.3 + ratio * 0.7
                bar.fill:SetVertexColor(
                    C.green[1] * intensity,
                    C.green[2] * intensity,
                    C.green[3] * intensity,
                    0.7
                )
            end
        end
    end

    -- 4. Class Distribution
    if ad.classBars and ns.Statistics and ns.Statistics.GetClassDistribution then
        local dOk, distribution, total = pcall(ns.Statistics.GetClassDistribution, ns.Statistics)
        if not dOk then distribution, total = {}, 0 end
        total = math.max(1, total or 1)
        local maxWidth = 400

        -- Build lookup
        local classData = {}
        for _, cd in ipairs(distribution) do
            classData[cd.class] = cd.recruited or 0
        end

        for classFile, bar in pairs(ad.classBars) do
            local recruited = classData[classFile] or 0
            local pct = recruited / total
            bar.fill:SetWidth(math.max(1, maxWidth * pct))
            bar.count:SetText(tostring(recruited) .. " (" .. string.format("%.0f%%", pct * 100) .. ")")
        end
    end

    -- 5. Trends (week over week)
    if ad.trendCards and ns.Statistics and ns.Statistics.GetTrends then
        local tOk, trends = pcall(ns.Statistics.GetTrends, ns.Statistics)
        if tOk and trends then
            for _, key in ipairs({"contacted", "invited", "joined"}) do
                local card = ad.trendCards[key]
                if card then
                    local thisWeekVal = trends.thisWeek and trends.thisWeek[key] or 0
                    card.thisWeek:SetText(tostring(thisWeekVal))

                    local changeVal = trends[key .. "Change"] or 0
                    if changeVal > 0 then
                        card.change:SetText(string.format("+%.0f%%", changeVal))
                        card.change:SetTextColor(C.green[1], C.green[2], C.green[3])
                    elseif changeVal < 0 then
                        card.change:SetText(string.format("%.0f%%", changeVal))
                        card.change:SetTextColor(C.red[1], C.red[2], C.red[3])
                    else
                        card.change:SetText("=")
                        card.change:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
                    end
                end
            end
        end
    end

    -- 6. Succes et Progression
    if ns.Goals and ns.Goals.GetProgress then
        local gOk, goalsProgress = pcall(ns.Goals.GetProgress, ns.Goals)
        if gOk and goalsProgress then
            -- Achievement progress bar and text
            if ad.achProgressText then
                ad.achProgressText:SetText(
                    "|TInterface\\Icons\\Achievement_General_StayClassy:14:14:0:0|t " .. tostring(goalsProgress.unlocked) .. " / " .. tostring(goalsProgress.total) .. " succes debloques"
                )
            end
            if ad.achProgressPct then
                ad.achProgressPct:SetText(tostring(goalsProgress.percentage) .. "%")
            end
            if ad.achBarFill and ad._achBarBg then
                local achPct = goalsProgress.total > 0 and (goalsProgress.unlocked / goalsProgress.total) or 0
                ad.achBarFill:SetWidth(math.max(1, ad._achBarBg:GetWidth() * achPct))
            end

            -- Recent achievements
            if ad.recentAchRows then
                local unlocks = goalsProgress.recentUnlocks or {}
                for i = 1, 5 do
                    local row = ad.recentAchRows[i]
                    if row then
                        if i <= #unlocks then
                            local u = unlocks[i]
                            row.icon:SetText(u.icon or "|TInterface\\Icons\\Achievement_General:14:14:0:0|t")
                            row.name:SetText(u.name or "?")
                            if u.unlockedAt and u.unlockedAt > 0 then
                                row.date:SetText(date("%d/%m/%Y %H:%M", u.unlockedAt))
                            else
                                row.date:SetText("")
                            end
                            row.row:Show()
                        else
                            row.row:Hide()
                        end
                    end
                end
            end
        end
    end

    -- Streak cards
    if ad.streakCards and ns.Goals and ns.Goals.GetStreaks then
        local sOk, streaks = pcall(ns.Goals.GetStreaks, ns.Goals)
        if sOk and streaks then
            for _, sKey in ipairs({"dailyLogin", "dailyRecruit", "weeklyGoal"}) do
                local sCard = ad.streakCards[sKey]
                local sData = streaks[sKey]
                if sCard and sData then
                    local suffix = (sKey == "weeklyGoal") and "s" or "j"
                    sCard.current:SetText(tostring(sData.current) .. suffix)
                    sCard.best:SetText("max: " .. tostring(sData.best))
                end
            end
        end
    end

    -- Next milestone
    if ad.milestoneTitle and ns.Goals and ns.Goals.GetNextMilestone then
        local mOk, milestone = pcall(ns.Goals.GetNextMilestone, ns.Goals)
        if mOk and milestone then
            ad.milestoneTitle:SetText("Prochain objectif : " .. (milestone.name or "?"))
            ad.milestoneRemaining:SetText(tostring(milestone.remaining) .. " restants")
            if ad.msBarFill and ad._msBarBg then
                local msPct = milestone.target > 0 and (milestone.current / milestone.target) or 0
                msPct = math.max(0, math.min(1, msPct))
                ad.msBarFill:SetWidth(math.max(1, ad._msBarBg:GetWidth() * msPct))
            end
        else
            ad.milestoneTitle:SetText("Prochain objectif : Tous debloques !")
            ad.milestoneTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            ad.milestoneRemaining:SetText("")
            if ad.msBarFill and ad._msBarBg then
                ad.msBarFill:SetWidth(ad._msBarBg:GetWidth())
            end
        end
    end

    -- 7. Dashboard Widgets
    if ns.DashboardWidgets and ns.DashboardWidgets.Refresh then
        ns.DashboardWidgets:Refresh()
    end

    -- 8. A/B Test Results
    if ad.abVariantRows and ns.ABTesting and ns.ABTesting.GetAllTests then
        local ok, tests = pcall(ns.ABTesting.GetAllTests, ns.ABTesting)
        if not ok then tests = {} end
        if tests and #tests > 0 then
            local latestTest = tests[1]
            ad.abTestInfo:SetText(("Test: %s  |  Statut: %s  |  Min. echantillons: %d"):format(
                latestTest.name or "?",
                latestTest.status or "?",
                latestTest.minSamples or 0
            ))

            local rok, results = pcall(ns.ABTesting.GetTestResults, ns.ABTesting, latestTest.id)
            if not rok then results = {} end
            local maxSent = 1
            for _, r in ipairs(results) do
                if (r.sent or 0) > maxSent then maxSent = r.sent end
            end

            for i = 1, 5 do
                local row = ad.abVariantRows[i]
                if i <= #results then
                    local r = results[i]
                    row.name:SetText((r.templateId or "?") .. (r.isWinner and " |TInterface\\Icons\\Achievement_General:14:14:0:0|t" or ""))
                    row.sent:SetText(("Envoyes: %d"):format(r.sent or 0))
                    row.replies:SetText(("Reponses: %d"):format(r.replies or 0))
                    row.joined:SetText(("Recrues: %d"):format(r.joined or 0))
                    row.rate:SetText(("Score: %.1f%%"):format((r.score or 0) * 100))
                    row.fill:SetWidth(math.max(1, 200 * ((r.sent or 0) / maxSent)))

                    if r.isWinner then
                        row.name:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
                    else
                        row.name:SetTextColor(C.text[1], C.text[2], C.text[3])
                    end
                    row.row:Show()
                else
                    row.row:Hide()
                end
            end
        else
            ad.abTestInfo:SetText("Aucun test A/B configure. Cree-en un dans les reglages.")
            for _, row in ipairs(ad.abVariantRows) do
                row.row:Hide()
            end
        end
    end

    -- 9. Guild Leaderboard
    if ad.guildRows and ns.Leaderboard and ns.Leaderboard.GetGuildRanking then
        local rOk, ranking = pcall(ns.Leaderboard.GetGuildRanking, ns.Leaderboard)
        if not rOk then ranking = {} end

        if ad.guildInfo then
            if #ranking > 1 then
                ad.guildInfo:SetText(("Classement des %d recruteurs de la guilde utilisant CelestialRecruiter."):format(#ranking))
            elseif #ranking == 1 then
                ad.guildInfo:SetText("Vous etes le seul recruteur avec CelestialRecruiter dans la guilde.")
            else
                ad.guildInfo:SetText("Aucune donnee de guilde disponible.")
            end
        end

        for i = 1, 15 do
            local row = ad.guildRows[i]
            if row then
                if i <= #ranking then
                    local data = ranking[i]
                    -- Rank
                    if i == 1 then
                        row.rank:SetText("|cffFFD7001|r")
                    elseif i == 2 then
                        row.rank:SetText("|cffC0C0C02|r")
                    elseif i == 3 then
                        row.rank:SetText("|cffCD7F323|r")
                    else
                        row.rank:SetText(tostring(i))
                        row.rank:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
                    end

                    -- Name (highlight self)
                    local displayName = (data.name or "?"):match("^([^%-]+)") or data.name or "?"
                    if data.isSelf then
                        row.name:SetText("|cff00aaff" .. displayName .. "|r |cff555555(vous)|r")
                    else
                        row.name:SetText(displayName)
                        row.name:SetTextColor(C.text[1], C.text[2], C.text[3])
                    end

                    -- Tier
                    local tierInfo = ns.Leaderboard:GetTierLabel(data.tier)
                    row.tier:SetText(tierInfo.name)
                    row.tier:SetTextColor(tierInfo.color[1], tierInfo.color[2], tierInfo.color[3])

                    -- Stats
                    row.joined:SetText(tostring(data.totalJoined or 0))
                    row.contacted:SetText(tostring(data.totalContacted or 0))
                    row.today:SetText(("J: %d  C: %d"):format(data.todayJoined or 0, data.todayContacted or 0))

                    row.row:Show()
                else
                    row.row:Hide()
                end
            end
        end
    end

    -- 10. Achievement Catalog
    if ad.catalogRows and ns.Goals and ns.Goals.GetAllAchievements then
        local aOk, allAch = pcall(ns.Goals.GetAllAchievements, ns.Goals)
        if aOk and allAch then
            -- Group by category
            local byCategory = {}
            for _, ach in ipairs(allAch) do
                local cat = ach.category or "recrutement"
                if not byCategory[cat] then byCategory[cat] = {} end
                byCategory[cat][#byCategory[cat] + 1] = ach
            end

            for _, catKey in ipairs({"recrutement", "social", "dedication", "mastery"}) do
                local items = byCategory[catKey] or {}
                for i = 1, 12 do
                    local rowKey = catKey .. "_" .. i
                    local row = ad.catalogRows[rowKey]
                    if row then
                        if i <= #items then
                            local ach = items[i]
                            row.icon:SetText(ach.icon or "|TInterface\\Icons\\Achievement_General:14:14:0:0|t")
                            row.name:SetText(ach.name or "?")
                            row.name:SetTextColor(C.text[1], C.text[2], C.text[3])
                            row.desc:SetText(ach.description or "")

                            if ach.unlocked then
                                row.accent:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.9)
                                row.desc:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
                                if ach.unlockedAt and ach.unlockedAt > 0 then
                                    row.status:SetText("|cff33e07aDebloque|r " .. date("%d/%m/%Y", ach.unlockedAt))
                                else
                                    row.status:SetText("|cff33e07aDebloque|r")
                                end
                                row.row:SetAlpha(1)
                            else
                                row.accent:SetVertexColor(C.muted[1], C.muted[2], C.muted[3], 0.4)
                                row.name:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
                                row.desc:SetTextColor(0.4, 0.4, 0.4)
                                row.status:SetText("|cffff6666Verrouille|r")
                                row.row:SetAlpha(0.7)
                            end

                            row.row:Show()
                        else
                            row.row:Hide()
                        end
                    end
                end
            end
        end
    end

    -- 11. Campaign Overview
    if ad.campRows and ns.Campaigns and ns.Campaigns.GetAll then
        local cOk, campaigns = pcall(ns.Campaigns.GetAll, ns.Campaigns)
        if not cOk then campaigns = {} end
        if campaigns and #campaigns > 0 then
            local gsOk, globalStats = pcall(ns.Campaigns.GetGlobalStats, ns.Campaigns)
            if not gsOk then globalStats = { campaigns = 0, active = 0, contacted = 0, joined = 0 } end
            ad.campInfo:SetText(("Total: %d campagnes | %d actives | %d contactes | %d recrues"):format(
                globalStats.campaigns or 0, globalStats.active or 0, globalStats.contacted or 0, globalStats.joined or 0
            ))

            for i = 1, 5 do
                local row = ad.campRows[i]
                if i <= #campaigns then
                    local camp = campaigns[i]
                    row.name:SetText(camp.name or "?")
                    row.name:Show()

                    local statusColors = {
                        draft = {C.dim[1], C.dim[2], C.dim[3]},
                        active = {C.green[1], C.green[2], C.green[3]},
                        paused = {C.orange[1], C.orange[2], C.orange[3]},
                        completed = {C.gold[1], C.gold[2], C.gold[3]},
                        archived = {C.muted[1], C.muted[2], C.muted[3]},
                    }
                    local sc = statusColors[camp.status] or statusColors.draft
                    row.status:SetText(camp.status or "draft")
                    row.status:SetTextColor(sc[1], sc[2], sc[3])

                    local cStats = camp.stats or {}
                    local cGoals = camp.goals or {}
                    row.stats:SetText(("Contactes: %d | Invites: %d | Recrues: %d/%d"):format(
                        cStats.contacted or 0, cStats.invited or 0, cStats.joined or 0, cGoals.targetJoined or 0
                    ))

                    -- Progress bar
                    local targetJ = cGoals.targetJoined or 0
                    local pct = targetJ > 0 and ((cStats.joined or 0) / targetJ) or 0
                    pct = math.min(1, pct)
                    row.barFill:SetWidth(math.max(1, row.barBg:GetWidth() * pct))

                    row.row:Show()
                else
                    row.row:Hide()
                end
            end
        else
            ad.campInfo:SetText("Aucune campagne configuree. Cree-en une via les reglages.")
            for _, row in ipairs(ad.campRows) do
                row.row:Hide()
            end
        end
    end
end

---------------------------------------------------------------------------
-- Analytics Badge
---------------------------------------------------------------------------
function ns.UI_AnalyticsBadge()
    -- Show active campaign/test count
    local badge = ""
    if ns.Campaigns and ns.Campaigns.GetActiveCampaigns then
        local ok, active = pcall(ns.Campaigns.GetActiveCampaigns, ns.Campaigns)
        if ok and active and #active > 0 then
            badge = "|cff33e07a" .. #active .. "|r"
        end
    end
    return badge
end
