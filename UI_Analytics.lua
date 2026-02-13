local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Analytics Tab with Interactive Charts
-- Beautiful data visualizations for recruitment insights
-- ═══════════════════════════════════════════════════════════════════

local charts = {}

---------------------------------------------------------------------------
-- Build Analytics Tab
---------------------------------------------------------------------------
function ns.UI_BuildAnalytics(panel)
    local scroll = W.MakeScroll(panel)
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -4, 4)

    local content = scroll.content
    local yOffset = -10

    -- Header
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetText("|cffFFD700📊 Analytics & Insights|r")
    header:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    yOffset = yOffset - 40

    -- Section 1: Conversion Funnel
    local funnelLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    funnelLabel:SetPoint("TOPLEFT", 16, yOffset)
    funnelLabel:SetText("|cff00aaff▸|r Funnel de conversion")
    funnelLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    local funnelChart = CreateFrame("Frame", nil, content)
    funnelChart:SetSize(scroll:GetWidth() - 40, 120)
    funnelChart:SetPoint("TOPLEFT", 20, yOffset)
    charts.funnel = funnelChart
    yOffset = yOffset - 140

    -- Section 2: Daily Trends (Line Chart)
    local trendsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trendsLabel:SetPoint("TOPLEFT", 16, yOffset)
    trendsLabel:SetText("|cff00aaff▸|r Tendances quotidiennes (30 derniers jours)")
    trendsLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    local trendsChart = CreateFrame("Frame", nil, content)
    trendsChart:SetSize(scroll:GetWidth() - 40, 150)
    trendsChart:SetPoint("TOPLEFT", 20, yOffset)
    charts.trends = trendsChart
    yOffset = yOffset - 170

    -- Section 3: Class Distribution (Pie Chart)
    local classLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classLabel:SetPoint("TOPLEFT", 16, yOffset)
    classLabel:SetText("|cff00aaff▸|r Distribution par classe")
    classLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    local classChart = CreateFrame("Frame", nil, content)
    classChart:SetSize(200, 200)
    classChart:SetPoint("TOPLEFT", 20, yOffset)
    charts.class = classChart
    yOffset = yOffset - 220

    -- Section 4: Best Hours (Heatmap)
    local hoursLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hoursLabel:SetPoint("TOPLEFT", 16, yOffset)
    hoursLabel:SetText("|cff00aaff▸|r Meilleurs horaires de recrutement")
    hoursLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    local hoursChart = CreateFrame("Frame", nil, content)
    hoursChart:SetSize(scroll:GetWidth() - 40, 100)
    hoursChart:SetPoint("TOPLEFT", 20, yOffset)
    charts.hours = hoursChart
    yOffset = yOffset - 120

    -- Section 5: Template Performance (Bar Chart)
    local templateLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    templateLabel:SetPoint("TOPLEFT", 16, yOffset)
    templateLabel:SetText("|cff00aaff▸|r Performance des templates")
    templateLabel:SetTextColor(C.text[1], C.text[2], C.text[3])
    yOffset = yOffset - 25

    local templateChart = CreateFrame("Frame", nil, content)
    templateChart:SetSize(scroll:GetWidth() - 40, 150)
    templateChart:SetPoint("TOPLEFT", 20, yOffset)
    charts.template = templateChart
    yOffset = yOffset - 170

    -- Set content height
    content:SetHeight(math.abs(yOffset) + 20)

    -- Store references
    ns._analyticsCharts = charts
    ns._analyticsScroll = scroll
end

---------------------------------------------------------------------------
-- Refresh Analytics Data
---------------------------------------------------------------------------
function ns.UI_RefreshAnalytics()
    if not ns.Statistics then return end
    if not charts.funnel then return end

    -- Clear existing charts
    for _, chart in pairs(charts) do
        if chart.Clear then
            chart:Clear()
        else
            -- Clear children
            local children = {chart:GetChildren()}
            for _, child in ipairs(children) do
                child:Hide()
                child:SetParent(nil)
            end
            local regions = {chart:GetRegions()}
            for _, region in ipairs(regions) do
                if region.Hide then
                    region:Hide()
                end
            end
        end
    end

    -- 1. Conversion Funnel (Bar Chart)
    local rates = ns.Statistics:GetConversionRates()
    if rates and charts.funnel then
        local funnelData = {
            {label = "Contactés", value = rates.totalContacted, color = C.accent, tooltip = "Nombre total de joueurs contactés"},
            {label = "Invités", value = rates.totalInvited, color = C.orange, tooltip = string.format("%.1f%% des contactés", rates.contactToInvite or 0)},
            {label = "Rejoints", value = rates.totalJoined, color = C.green, tooltip = string.format("%.1f%% des invités", rates.inviteToJoin or 0)},
        }

        if ns.Charts and ns.Charts.CreateBarChart then
            ns.Charts:CreateBarChart(charts.funnel, charts.funnel:GetWidth(), charts.funnel:GetHeight(), funnelData, {animate = true})
        end
    end

    -- 2. Daily Trends (Line Chart)
    if charts.trends and ns.Statistics.GetDailyHistory then
        local history = ns.Statistics:GetDailyHistory()
        local trendData = {}

        -- Get last 30 days
        local today = time()
        for i = 29, 0, -1 do
            local date = date("%Y-%m-%d", today - (i * 86400))
            local dayData = history[date]
            table.insert(trendData, {
                label = date,
                value = dayData and (dayData.contacted or 0) or 0
            })
        end

        if ns.Charts and ns.Charts.CreateLineChart and #trendData > 0 then
            ns.Charts:CreateLineChart(charts.trends, charts.trends:GetWidth(), charts.trends:GetHeight(), trendData, {
                color = C.accent,
                showPoints = true,
                showGrid = true,
                animate = true
            })
        end
    end

    -- 3. Class Distribution (Pie Chart)
    if charts.class and ns.Statistics.GetClassDistribution then
        local distribution = ns.Statistics:GetClassDistribution()
        local pieData = {}

        for _, classData in ipairs(distribution) do
            local classColor = W.classRGB(classData.class)
            table.insert(pieData, {
                label = classData.class,
                value = classData.recruited,
                color = classColor and {classColor} or C.accent
            })
        end

        if ns.Charts and ns.Charts.CreatePieChart and #pieData > 0 then
            ns.Charts:CreatePieChart(charts.class, 200, pieData, {
                innerRadius = 0.6,
                animate = true
            })
        end
    end

    -- 4. Best Hours (Heatmap)
    if charts.hours and ns.Statistics.GetBestHours then
        local bestHours = ns.Statistics:GetBestHours()
        local heatmapData = {}

        -- Convert to heatmap format (single row, 24 columns)
        for i = 0, 23 do
            local found = false
            for _, hourData in ipairs(bestHours) do
                if hourData.hour == i then
                    heatmapData[i] = hourData.activity
                    found = true
                    break
                end
            end
            if not found then
                heatmapData[i] = 0
            end
        end

        if ns.Charts and ns.Charts.CreateHeatmap then
            ns.Charts:CreateHeatmap(charts.hours, charts.hours:GetWidth(), charts.hours:GetHeight(), heatmapData, {
                cols = 24,
                rows = 1,
                colorLow = C.panel,
                colorHigh = C.green
            })
        end
    end

    -- 5. Template Performance (Bar Chart)
    if charts.template and ns.Statistics.GetTemplatePerformance then
        local performance = ns.Statistics:GetTemplatePerformance()
        local barData = {}

        for _, tpl in ipairs(performance) do
            table.insert(barData, {
                label = tpl.template,
                value = tpl.successRate or 0,
                color = C.purple,
                tooltip = string.format("Utilisé: %d fois, Succès: %d (%.1f%%)", tpl.used, tpl.success, tpl.successRate or 0)
            })
        end

        if ns.Charts and ns.Charts.CreateBarChart and #barData > 0 then
            ns.Charts:CreateBarChart(charts.template, charts.template:GetWidth(), charts.template:GetHeight(), barData, {animate = true})
        end
    end
end

---------------------------------------------------------------------------
-- Analytics Badge (for tab notification)
---------------------------------------------------------------------------
function ns.UI_AnalyticsBadge()
    -- No badge needed for now
    return ""
end
