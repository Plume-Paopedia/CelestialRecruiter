local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Dashboard Widgets System
-- Customizable widget cards for the Analytics dashboard
-- ═══════════════════════════════════════════════════════════════════

ns.DashboardWidgets = ns.DashboardWidgets or {}
local DW = ns.DashboardWidgets

local WIDGET_PADDING = 8
local CARD_HEIGHT = 130
local CARD_WIDTH_FULL = 0   -- calculated at runtime
local CARD_WIDTH_HALF = 0

---------------------------------------------------------------------------
-- Widget Registry
---------------------------------------------------------------------------
local widgetTypes = {}

local function registerWidget(id, label, icon, buildFn, refreshFn)
    widgetTypes[id] = {
        id = id,
        label = label,
        icon = icon,
        build = buildFn,
        refresh = refreshFn,
    }
end

---------------------------------------------------------------------------
-- Helper: Create a Card Frame
---------------------------------------------------------------------------
local function CreateCard(parent, title, icon, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetHeight(height or CARD_HEIGHT)
    card:SetBackdrop({
        bgFile = W.SOLID,
        edgeFile = W.EDGE,
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    card:SetBackdropColor(0.07, 0.08, 0.14, 0.85)
    card:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.35)

    -- Top accent line
    local accent = card:CreateTexture(nil, "OVERLAY")
    accent:SetTexture(W.SOLID)
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", 3, -2)
    accent:SetPoint("TOPRIGHT", -3, -2)
    accent:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.4)
    card._accent = accent

    -- Title
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOPLEFT", 10, -10)
    titleText:SetText((icon or "") .. " " .. (title or ""))
    titleText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    card._title = titleText

    -- Content area
    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", 10, -28)
    content:SetPoint("BOTTOMRIGHT", -10, 8)
    card._content = content

    -- Hover effect
    card:EnableMouse(true)
    card:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        accent:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    end)
    card:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.35)
        accent:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.4)
    end)

    return card
end

---------------------------------------------------------------------------
-- Helper: Stat Value Display
---------------------------------------------------------------------------
local function CreateStatValue(parent, value, label, color, x, y)
    local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    valText:SetPoint("TOPLEFT", x or 0, y or 0)
    valText:SetText(tostring(value))
    valText:SetTextColor(color[1], color[2], color[3])

    local lblText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblText:SetPoint("TOPLEFT", valText, "BOTTOMLEFT", 0, -2)
    lblText:SetText(label)
    lblText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    return {val = valText, lbl = lblText}
end

---------------------------------------------------------------------------
-- Helper: Progress Bar
---------------------------------------------------------------------------
local function CreateProgressBar(parent, width, height, color)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetSize(width, height or 6)
    bar:SetBackdrop({bgFile = W.SOLID})
    bar:SetBackdropColor(1, 1, 1, 0.06)

    local fill = bar:CreateTexture(nil, "OVERLAY")
    fill:SetTexture(W.SOLID)
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    fill:SetWidth(1)
    fill:SetVertexColor(color[1], color[2], color[3], 0.8)
    bar._fill = fill

    function bar:SetProgress(pct)
        pct = math.max(0, math.min(1, pct))
        self._fill:SetWidth(math.max(1, self:GetWidth() * pct))
    end

    return bar
end

---------------------------------------------------------------------------
-- Widget: Session Overview
---------------------------------------------------------------------------
registerWidget("session_overview", "Session en cours", "|cff00aaff⏱|r",
    function(card)
        local c = card._content
        card._statWhispers = CreateStatValue(c, "0", "Messages", C.accent, 0, 0)
        card._statInvites = CreateStatValue(c, "0", "Invitations", C.green, 90, 0)
        card._statRecruits = CreateStatValue(c, "0", "Recrues", C.gold, 180, 0)
        card._statDuration = CreateStatValue(c, "0m", "Duree", C.dim, 270, 0)

        card._sessionBar = CreateProgressBar(c, 340, 4, C.accent)
        card._sessionBar:SetPoint("BOTTOMLEFT", 0, 4)
    end,
    function(card)
        local s = ns.sessionStats or {}
        card._statWhispers.val:SetText(tostring(s.whispersSent or 0))
        card._statInvites.val:SetText(tostring(s.invitesSent or 0))
        card._statRecruits.val:SetText(tostring(s.recruitsJoined or 0))

        local elapsed = s.startedAt and (time() - s.startedAt) or 0
        local mins = math.floor(elapsed / 60)
        card._statDuration.val:SetText(mins .. "m")

        -- Progress bar based on queue processing
        local total = (s.whispersSent or 0) + (s.invitesSent or 0)
        card._sessionBar:SetProgress(math.min(1, total / 50))
    end
)

---------------------------------------------------------------------------
-- Widget: Conversion Funnel
---------------------------------------------------------------------------
registerWidget("conversion_funnel", "Entonnoir de conversion", "|cff33e07a▼|r",
    function(card)
        local c = card._content
        local colors = {C.accent, C.orange, C.green, C.gold}
        local labels = {"Contactes", "Invites", "Recrues"}

        card._funnelBars = {}
        for i = 1, 3 do
            local y = -(i - 1) * 26
            local lbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", 0, y)
            lbl:SetText(labels[i])
            lbl:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            local bar = CreateProgressBar(c, 200, 8, colors[i])
            bar:SetPoint("TOPLEFT", 80, y - 2)

            local val = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            val:SetPoint("LEFT", bar, "RIGHT", 6, 0)
            val:SetTextColor(C.text[1], C.text[2], C.text[3])

            card._funnelBars[i] = {bar = bar, val = val}
        end
    end,
    function(card)
        if not ns.Statistics then return end
        local rates = ns.Statistics:GetConversionRates()
        if not rates then return end

        local values = {rates.totalContacted, rates.totalInvited, rates.totalJoined}
        local maxVal = math.max(1, values[1])

        for i = 1, 3 do
            local fb = card._funnelBars[i]
            fb.bar:SetProgress(values[i] / maxVal)
            fb.val:SetText(tostring(values[i]))
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Template Performance (A/B Testing)
---------------------------------------------------------------------------
registerWidget("template_perf", "Performance templates", "|cffFF69B4★|r",
    function(card)
        local c = card._content
        card._tplRows = {}

        for i = 1, 4 do
            local y = -(i - 1) * 22
            local name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            name:SetPoint("TOPLEFT", 0, y)
            name:SetTextColor(C.text[1], C.text[2], C.text[3])

            local bar = CreateProgressBar(c, 140, 6, C.accent)
            bar:SetPoint("TOPLEFT", 100, y - 3)

            local pct = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pct:SetPoint("LEFT", bar, "RIGHT", 6, 0)
            pct:SetTextColor(C.green[1], C.green[2], C.green[3])

            card._tplRows[i] = {name = name, bar = bar, pct = pct}
            name:Hide()
            bar:Hide()
            pct:Hide()
        end

        card._emptyText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._emptyText:SetPoint("CENTER")
        card._emptyText:SetText("Pas encore de donnees")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Statistics then return end
        local perf = ns.Statistics:GetTemplatePerformance()

        if #perf == 0 then
            card._emptyText:Show()
            for _, row in ipairs(card._tplRows) do
                row.name:Hide()
                row.bar:Hide()
                row.pct:Hide()
            end
            return
        end

        card._emptyText:Hide()
        local maxRate = 0
        for _, p in ipairs(perf) do
            if p.successRate > maxRate then maxRate = p.successRate end
        end

        for i = 1, math.min(4, #perf) do
            local row = card._tplRows[i]
            local data = perf[i]
            row.name:SetText(data.template)
            row.name:Show()
            row.bar:SetProgress(maxRate > 0 and (data.successRate / maxRate) or 0)
            row.bar:Show()
            row.pct:SetText(("%.0f%% (%d)"):format(data.successRate, data.used))
            row.pct:Show()
        end

        for i = #perf + 1, 4 do
            card._tplRows[i].name:Hide()
            card._tplRows[i].bar:Hide()
            card._tplRows[i].pct:Hide()
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Best Hours Heatmap
---------------------------------------------------------------------------
registerWidget("best_hours", "Meilleures heures", "|cffFFD700☀|r",
    function(card)
        local c = card._content
        card._hourBlocks = {}

        for h = 0, 23 do
            local col = h % 12
            local row = math.floor(h / 12)
            local block = CreateFrame("Frame", nil, c, "BackdropTemplate")
            block:SetSize(24, 28)
            block:SetPoint("TOPLEFT", col * 27, -row * 34)
            block:SetBackdrop({bgFile = W.SOLID})
            block:SetBackdropColor(0.1, 0.1, 0.15, 0.5)

            local txt = block:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("CENTER", 0, 4)
            txt:SetText(tostring(h))
            txt:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            local val = block:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            val:SetPoint("CENTER", 0, -6)
            val:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
            val:SetText("-")

            card._hourBlocks[h] = {frame = block, txt = txt, val = val}
        end
    end,
    function(card)
        if not ns.Statistics then return end
        local hours = ns.Statistics:GetBestHours()
        if not hours then return end

        -- Find max
        local maxActivity = 0
        for _, h in ipairs(hours) do
            if h.activity > maxActivity then maxActivity = h.activity end
        end

        for _, h in ipairs(hours) do
            local block = card._hourBlocks[h.hour]
            if block then
                block.val:SetText(tostring(h.activity))
                local intensity = maxActivity > 0 and (h.activity / maxActivity) or 0
                if intensity > 0.7 then
                    block.frame:SetBackdropColor(C.green[1], C.green[2], C.green[3], 0.4)
                    block.txt:SetTextColor(C.text[1], C.text[2], C.text[3])
                elseif intensity > 0.3 then
                    block.frame:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.2)
                    block.txt:SetTextColor(C.text[1], C.text[2], C.text[3])
                else
                    block.frame:SetBackdropColor(0.1, 0.1, 0.15, 0.5)
                    block.txt:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
                end
            end
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Active Campaigns
---------------------------------------------------------------------------
registerWidget("active_campaigns", "Campagnes actives", "|cffFF8C00⚔|r",
    function(card)
        local c = card._content
        card._campRows = {}

        for i = 1, 3 do
            local y = -(i - 1) * 28
            local name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            name:SetPoint("TOPLEFT", 0, y)
            name:SetTextColor(C.text[1], C.text[2], C.text[3])

            local bar = CreateProgressBar(c, 180, 6, C.gold)
            bar:SetPoint("TOPLEFT", 120, y - 3)

            local info = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            info:SetPoint("TOPLEFT", 120, y - 14)
            info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            card._campRows[i] = {name = name, bar = bar, info = info}
            name:Hide()
            bar:Hide()
            info:Hide()
        end

        card._emptyText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._emptyText:SetPoint("CENTER")
        card._emptyText:SetText("Aucune campagne active")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Campaigns then return end
        local active = ns.Campaigns:GetActiveCampaigns()

        if #active == 0 then
            card._emptyText:Show()
            for _, row in ipairs(card._campRows) do
                row.name:Hide()
                row.bar:Hide()
                row.info:Hide()
            end
            return
        end

        card._emptyText:Hide()
        for i = 1, math.min(3, #active) do
            local row = card._campRows[i]
            local camp = active[i]
            local progress = ns.Campaigns:GetProgress(camp.id)

            row.name:SetText(camp.name)
            row.name:Show()

            local goalPct = progress.joined.pct / 100
            row.bar:SetProgress(goalPct)
            row.bar:Show()

            row.info:SetText(("%d/%d recrues"):format(
                camp.stats.joined, camp.goals.targetJoined))
            row.info:Show()
        end

        for i = #active + 1, 3 do
            card._campRows[i].name:Hide()
            card._campRows[i].bar:Hide()
            card._campRows[i].info:Hide()
        end
    end
)

---------------------------------------------------------------------------
-- Widget: A/B Test Status
---------------------------------------------------------------------------
registerWidget("ab_test_status", "A/B Test actif", "|cff9370DB⚗|r",
    function(card)
        local c = card._content
        card._abTestName = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card._abTestName:SetPoint("TOPLEFT", 0, 0)
        card._abTestName:SetTextColor(C.text[1], C.text[2], C.text[3])

        card._abVariants = {}
        for i = 1, 4 do
            local y = -(i - 1) * 20 - 22
            local name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            name:SetPoint("TOPLEFT", 0, y)
            name:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            local bar = CreateProgressBar(c, 120, 5, C.purple)
            bar:SetPoint("TOPLEFT", 80, y - 2)

            local stat = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            stat:SetPoint("LEFT", bar, "RIGHT", 6, 0)
            stat:SetTextColor(C.text[1], C.text[2], C.text[3])

            card._abVariants[i] = {name = name, bar = bar, stat = stat}
            name:Hide()
            bar:Hide()
            stat:Hide()
        end

        card._emptyText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._emptyText:SetPoint("CENTER")
        card._emptyText:SetText("Aucun test A/B actif")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.ABTesting then return end
        local test = ns.ABTesting:GetActiveTest()

        if not test then
            card._abTestName:SetText("")
            card._emptyText:Show()
            for _, row in ipairs(card._abVariants) do
                row.name:Hide()
                row.bar:Hide()
                row.stat:Hide()
            end
            return
        end

        card._emptyText:Hide()
        card._abTestName:SetText(test.name)

        local results = ns.ABTesting:GetTestResults(test.id)
        local maxSent = 1
        for _, r in ipairs(results) do
            if r.sent > maxSent then maxSent = r.sent end
        end

        for i = 1, math.min(4, #results) do
            local row = card._abVariants[i]
            local r = results[i]
            row.name:SetText(r.templateId)
            row.name:Show()
            row.bar:SetProgress(r.sent / maxSent)
            row.bar:Show()
            row.stat:SetText(("%d env. %.0f%% rep."):format(r.sent, r.replyRate * 100))
            row.stat:Show()

            if r.isWinner then
                row.name:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            else
                row.name:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            end
        end

        for i = #results + 1, 4 do
            card._abVariants[i].name:Hide()
            card._abVariants[i].bar:Hide()
            card._abVariants[i].stat:Hide()
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Reputation Leaderboard
---------------------------------------------------------------------------
registerWidget("reputation_board", "Top contacts", "|cff00d1ff♛|r",
    function(card)
        local c = card._content
        card._repRows = {}

        for i = 1, 5 do
            local y = -(i - 1) * 16
            local rank = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rank:SetPoint("TOPLEFT", 0, y)
            rank:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            rank:SetText("#" .. i)

            local name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            name:SetPoint("TOPLEFT", 24, y)
            name:SetTextColor(C.text[1], C.text[2], C.text[3])

            local score = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            score:SetPoint("TOPLEFT", 200, y)
            score:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

            card._repRows[i] = {rank = rank, name = name, score = score}
            rank:Hide()
            name:Hide()
            score:Hide()
        end

        card._emptyText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._emptyText:SetPoint("CENTER")
        card._emptyText:SetText("Pas de contacts scores")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Reputation then return end
        local priorityQueue = ns.Reputation:GetPriorityQueue()

        if #priorityQueue == 0 then
            card._emptyText:Show()
            for _, row in ipairs(card._repRows) do
                row.rank:Hide()
                row.name:Hide()
                row.score:Hide()
            end
            return
        end

        card._emptyText:Hide()
        for i = 1, math.min(5, #priorityQueue) do
            local row = card._repRows[i]
            local entry = priorityQueue[i]
            row.rank:Show()
            row.name:SetText(entry.key)
            row.name:Show()

            local _, label, color = ns.Reputation:GetScoreClass(entry.score)
            row.score:SetText(tostring(entry.score))
            row.score:SetTextColor(color[1], color[2], color[3])
            row.score:Show()
        end

        for i = #priorityQueue + 1, 5 do
            card._repRows[i].rank:Hide()
            card._repRows[i].name:Hide()
            card._repRows[i].score:Hide()
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Weekly Trends
---------------------------------------------------------------------------
registerWidget("weekly_trends", "Tendances semaine", "|cff66ff99📈|r",
    function(card)
        local c = card._content
        card._trendItems = {}
        local labels = {"Contactes", "Invites", "Recrues"}
        local colors = {C.accent, C.orange, C.gold}

        for i = 1, 3 do
            local y = -(i - 1) * 26
            local lbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", 0, y)
            lbl:SetText(labels[i])
            lbl:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            local val = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            val:SetPoint("TOPLEFT", 80, y)
            val:SetTextColor(colors[i][1], colors[i][2], colors[i][3])

            local change = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            change:SetPoint("TOPLEFT", 140, y)
            change:SetTextColor(C.green[1], C.green[2], C.green[3])

            card._trendItems[i] = {lbl = lbl, val = val, change = change}
        end
    end,
    function(card)
        if not ns.Statistics then return end
        local trends = ns.Statistics:GetTrends()
        if not trends or not trends.thisWeek then return end

        local tw = trends.thisWeek
        local changes = {trends.contactedChange, trends.invitedChange, trends.joinedChange}
        local values = {tw.contacted, tw.invited, tw.joined}

        for i = 1, 3 do
            card._trendItems[i].val:SetText(tostring(values[i]))
            local ch = changes[i]
            if ch > 0 then
                card._trendItems[i].change:SetText(("▲ +%.0f%%"):format(ch))
                card._trendItems[i].change:SetTextColor(C.green[1], C.green[2], C.green[3])
            elseif ch < 0 then
                card._trendItems[i].change:SetText(("▼ %.0f%%"):format(ch))
                card._trendItems[i].change:SetTextColor(C.red[1], C.red[2], C.red[3])
            else
                card._trendItems[i].change:SetText("= 0%")
                card._trendItems[i].change:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            end
        end
    end
)

---------------------------------------------------------------------------
-- Default Layout
---------------------------------------------------------------------------
local DEFAULT_LAYOUT = {
    "session_overview",
    "conversion_funnel",
    "weekly_trends",
    "template_perf",
    "best_hours",
    "active_campaigns",
    "ab_test_status",
    "reputation_board",
}

---------------------------------------------------------------------------
-- Build Dashboard
---------------------------------------------------------------------------
function DW:Build(parent)
    self._parent = parent
    self._cards = {}

    local layout = DEFAULT_LAYOUT
    if ns.db and ns.db.profile and ns.db.profile.dashboardLayout then
        layout = ns.db.profile.dashboardLayout
    end

    local y = 0
    local parentWidth = parent:GetWidth()
    if parentWidth <= 0 then parentWidth = 660 end

    for idx, widgetId in ipairs(layout) do
        local wtype = widgetTypes[widgetId]
        if wtype then
            local card = CreateCard(parent, wtype.label, wtype.icon, CARD_HEIGHT)
            card:SetPoint("TOPLEFT", 0, y)
            card:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

            -- Build widget content
            wtype.build(card)

            self._cards[widgetId] = card
            y = y - CARD_HEIGHT - WIDGET_PADDING
        end
    end

    self._totalHeight = -y
    return self._totalHeight
end

---------------------------------------------------------------------------
-- Refresh All Widgets
---------------------------------------------------------------------------
function DW:Refresh()
    if not self._cards then return end

    for widgetId, card in pairs(self._cards) do
        local wtype = widgetTypes[widgetId]
        if wtype and wtype.refresh then
            local ok, err = pcall(wtype.refresh, card)
            if not ok and err then
                -- Silently handle widget refresh errors
            end
        end
    end
end

---------------------------------------------------------------------------
-- Get Total Height (for scroll)
---------------------------------------------------------------------------
function DW:GetTotalHeight()
    return self._totalHeight or 0
end

---------------------------------------------------------------------------
-- Get Available Widget Types
---------------------------------------------------------------------------
function DW:GetWidgetTypes()
    local types = {}
    for id, wtype in pairs(widgetTypes) do
        table.insert(types, {
            id = wtype.id,
            label = wtype.label,
            icon = wtype.icon,
        })
    end
    table.sort(types, function(a, b) return a.label < b.label end)
    return types
end
