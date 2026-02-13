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
    header:SetText("|cffFFD700* Analytics & Insights|r")
    header:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    yOffset = yOffset - 40

    -- ═══════════════════════════════════════════════════
    -- Section 1: Summary Cards
    -- ═══════════════════════════════════════════════════
    local summaryLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryLabel:SetPoint("TOPLEFT", 16, yOffset)
    summaryLabel:SetText("|cff00aaff>|r Resume de session")
    summaryLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 30

    -- Create 4 stat cards
    local cardW = 200
    local cardH = 60
    local cardSpacing = 10
    ad.cards = {}

    local cardDefs = {
        {key = "contacted", label = "Contactes", icon = "|cff00aaffO|r", color = C.accent},
        {key = "invited",   label = "Invites",   icon = "|cff33e07a+|r", color = C.green},
        {key = "joined",    label = "Recrues",   icon = "|cffFFD700*|r", color = C.gold},
        {key = "conversion",label = "Conversion", icon = "|cffFF69B4%|r", color = {1, 0.41, 0.71}},
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
    funnelLabel:SetText("|cff00aaff>|r Funnel de conversion")
    funnelLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    -- Funnel visual (horizontal bars showing pipeline)
    ad.funnelBars = {}
    local funnelDefs = {
        {key = "contacted", label = "Contactes",  color = C.accent},
        {key = "invited",   label = "Invites",    color = C.orange},
        {key = "joined",    label = "Rejoints",   color = C.green},
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
    hoursLabel:SetText("|cff00aaff>|r Meilleurs horaires de recrutement")
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
    classLabel:SetText("|cff00aaff>|r Distribution par classe")
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
    tplLabel:SetText("|cff00aaff>|r Performance des templates")
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
    trendsLabel:SetText("|cff00aaff>|r Tendances (semaine actuelle vs precedente)")
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
    -- Section 7: Dashboard Widgets
    -- ═══════════════════════════════════════════════════
    local widgetsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widgetsLabel:SetPoint("TOPLEFT", 16, yOffset)
    widgetsLabel:SetText("|cff00aaff>|r Tableau de bord")
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
    -- Section 8: A/B Test Results
    -- ═══════════════════════════════════════════════════
    local abLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abLabel:SetPoint("TOPLEFT", 16, yOffset)
    abLabel:SetText("|cff9370DB>|r Tests A/B")
    abLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.abContainer = CreateFrame("Frame", nil, content)
    ad.abContainer:SetPoint("TOPLEFT", 20, yOffset)
    ad.abContainer:SetSize(chartWidth - 40, 180)

    -- A/B Test info
    ad.abTestInfo = ad.abContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.abTestInfo:SetPoint("TOPLEFT", 0, 0)
    ad.abTestInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.abTestInfo:SetText("Aucun test A/B configure")

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
    -- Section 9: Campaign Overview
    -- ═══════════════════════════════════════════════════
    local campLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    campLabel:SetPoint("TOPLEFT", 16, yOffset)
    campLabel:SetText("|cffFF8C00>|r Campagnes de recrutement")
    campLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    ad.campContainer = CreateFrame("Frame", nil, content)
    ad.campContainer:SetPoint("TOPLEFT", 20, yOffset)
    ad.campContainer:SetSize(chartWidth - 40, 200)

    ad.campInfo = ad.campContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ad.campInfo:SetPoint("TOPLEFT", 0, 0)
    ad.campInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    ad.campInfo:SetText("Aucune campagne configuree")

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
        for _, def in ipairs({"contacted", "invited", "joined"}) do
            local bar = ad.funnelBars[def]
            if bar then
                local val = funnelVals[def] or 0
                local pct = maxVal > 0 and (val / maxVal) or 0
                bar.fill:SetWidth(math.max(1, maxWidth * pct))
                bar.label:SetText(def:sub(1,1):upper() .. def:sub(2) .. ": " .. tostring(val))
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

    -- 6. Dashboard Widgets
    if ns.DashboardWidgets and ns.DashboardWidgets.Refresh then
        ns.DashboardWidgets:Refresh()
    end

    -- 7. A/B Test Results
    if ad.abVariantRows and ns.ABTesting and ns.ABTesting.GetAllTests then
        local ok, tests = pcall(ns.ABTesting.GetAllTests, ns.ABTesting)
        if not ok then tests = {} end
        if tests and #tests > 0 then
            local latestTest = tests[1]
            ad.abTestInfo:SetText(("Test: %s  |  Status: %s  |  Min. echantillons: %d"):format(
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
                    row.name:SetText((r.templateId or "?") .. (r.isWinner and " |cffFFD700*|r" or ""))
                    row.sent:SetText(("Env: %d"):format(r.sent or 0))
                    row.replies:SetText(("Rep: %d"):format(r.replies or 0))
                    row.joined:SetText(("Rec: %d"):format(r.joined or 0))
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
            ad.abTestInfo:SetText("Aucun test A/B configure. Creez-en un dans les reglages.")
            for _, row in ipairs(ad.abVariantRows) do
                row.row:Hide()
            end
        end
    end

    -- 8. Campaign Overview
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
            ad.campInfo:SetText("Aucune campagne configuree. Creez-en une via /cr.")
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
