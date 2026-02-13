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
registerWidget("session_overview", "Session en cours", "|cff00aaffO|r",
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
registerWidget("conversion_funnel", "Entonnoir de conversion", "|cff33e07av|r",
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
        if not ns.Statistics or not ns.Statistics.GetConversionRates then return end
        local ok, rates = pcall(ns.Statistics.GetConversionRates, ns.Statistics)
        if not ok or not rates then return end

        local values = {rates.totalContacted or 0, rates.totalInvited or 0, rates.totalJoined or 0}
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
registerWidget("template_perf", "Performance des modeles", "|cffFF69B4*|r",
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
        card._emptyText:SetText("Pas encore de donnees.")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Statistics or not ns.Statistics.GetTemplatePerformance then return end
        local ok, perf = pcall(ns.Statistics.GetTemplatePerformance, ns.Statistics)
        if not ok or not perf then perf = {} end

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
registerWidget("best_hours", "Meilleures heures", "|cffFFD700*|r",
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
        if not ns.Statistics or not ns.Statistics.GetBestHours then return end
        local ok, hours = pcall(ns.Statistics.GetBestHours, ns.Statistics)
        if not ok or not hours then return end

        -- Find max
        local maxActivity = 0
        for _, h in ipairs(hours) do
            if (h.activity or 0) > maxActivity then maxActivity = h.activity end
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
registerWidget("active_campaigns", "Campagnes actives", "|cffFF8C00>|r",
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
        card._emptyText:SetText("Aucune campagne active.")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Campaigns or not ns.Campaigns.GetActiveCampaigns then return end
        local ok, active = pcall(ns.Campaigns.GetActiveCampaigns, ns.Campaigns)
        if not ok then active = {} end

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
            local ok, progress = pcall(ns.Campaigns.GetProgress, ns.Campaigns, camp.id)
            if not ok then progress = {} end

            row.name:SetText(camp.name or "?")
            row.name:Show()

            local joinedProgress = progress and progress.joined
            local goalPct = (joinedProgress and joinedProgress.pct) and (joinedProgress.pct / 100) or 0
            row.bar:SetProgress(goalPct)
            row.bar:Show()

            local stats = camp.stats or {}
            local goals = camp.goals or {}
            row.info:SetText(("%d/%d recrues"):format(
                stats.joined or 0, goals.targetJoined or 0))
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
registerWidget("ab_test_status", "Test A/B actif", "|cff9370DB?|r",
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
        card._emptyText:SetText("Aucun test A/B actif.")
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

        local rok, results = pcall(ns.ABTesting.GetTestResults, ns.ABTesting, test.id)
        if not rok then results = {} end
        local maxSent = 1
        for _, r in ipairs(results) do
            if (r.sent or 0) > maxSent then maxSent = r.sent end
        end

        for i = 1, math.min(4, #results) do
            local row = card._abVariants[i]
            local r = results[i]
            row.name:SetText(r.templateId or "?")
            row.name:Show()
            row.bar:SetProgress((r.sent or 0) / maxSent)
            row.bar:Show()
            row.stat:SetText(("%d envoyes, %.0f%% reponses"):format(r.sent or 0, (r.replyRate or 0) * 100))
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
registerWidget("reputation_board", "Classement contacts", "|cff00d1ff#|r",
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
        card._emptyText:SetText("Aucun contact avec score.")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.Reputation or not ns.Reputation.GetPriorityQueue then return end
        local ok, priorityQueue = pcall(ns.Reputation.GetPriorityQueue, ns.Reputation)
        if not ok then priorityQueue = {} end

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
registerWidget("weekly_trends", "Tendances semaine", "|cff66ff99+|r",
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
        local ok, trends = pcall(ns.Statistics.GetTrends, ns.Statistics)
        if not ok or not trends or not trends.thisWeek then return end

        local tw = trends.thisWeek
        local changes = {trends.contactedChange or 0, trends.invitedChange or 0, trends.joinedChange or 0}
        local values = {tw.contacted or 0, tw.invited or 0, tw.joined or 0}

        for i = 1, 3 do
            card._trendItems[i].val:SetText(tostring(values[i]))
            local ch = changes[i] or 0
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
-- Widget: Goals & Achievements Progress
---------------------------------------------------------------------------
registerWidget("goals_progress", "Succes et Objectifs", "|cffFFD700T|r",
    function(card)
        local c = card._content

        -- Achievement progress: X/25 line
        card._goalsCount = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        card._goalsCount:SetPoint("TOPLEFT", 0, 0)
        card._goalsCount:SetText("0/25")
        card._goalsCount:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

        card._goalsLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._goalsLabel:SetPoint("LEFT", card._goalsCount, "RIGHT", 6, 0)
        card._goalsLabel:SetText("succes debloques")
        card._goalsLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        -- Achievement progress bar
        card._goalsBar = CreateProgressBar(c, 340, 6, C.gold)
        card._goalsBar:SetPoint("TOPLEFT", 0, -22)

        -- Streaks: daily login + daily recruit
        card._streakLoginLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._streakLoginLabel:SetPoint("TOPLEFT", 0, -36)
        card._streakLoginLabel:SetText("Connexion:")
        card._streakLoginLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._streakLoginVal = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._streakLoginVal:SetPoint("LEFT", card._streakLoginLabel, "RIGHT", 4, 0)
        card._streakLoginVal:SetText("0j")
        card._streakLoginVal:SetTextColor(C.green[1], C.green[2], C.green[3])

        card._streakRecruitLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._streakRecruitLabel:SetPoint("TOPLEFT", 140, -36)
        card._streakRecruitLabel:SetText("Recrutement:")
        card._streakRecruitLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._streakRecruitVal = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._streakRecruitVal:SetPoint("LEFT", card._streakRecruitLabel, "RIGHT", 4, 0)
        card._streakRecruitVal:SetText("0j")
        card._streakRecruitVal:SetTextColor(C.green[1], C.green[2], C.green[3])

        -- Next milestone
        card._milestoneLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._milestoneLabel:SetPoint("TOPLEFT", 0, -54)
        card._milestoneLabel:SetText("Prochain:")
        card._milestoneLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._milestoneName = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._milestoneName:SetPoint("LEFT", card._milestoneLabel, "RIGHT", 4, 0)
        card._milestoneName:SetText("-")
        card._milestoneName:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

        card._milestoneBar = CreateProgressBar(c, 200, 5, C.accent)
        card._milestoneBar:SetPoint("TOPLEFT", 0, -68)

        card._milestoneInfo = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._milestoneInfo:SetPoint("LEFT", card._milestoneBar, "RIGHT", 6, 0)
        card._milestoneInfo:SetText("")
        card._milestoneInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        -- Recent unlocks (up to 3)
        card._recentUnlocks = {}
        for i = 1, 3 do
            local y = -82 - (i - 1) * 14
            local txt = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("TOPLEFT", 0, y)
            txt:SetText("")
            txt:SetTextColor(C.text[1], C.text[2], C.text[3])
            card._recentUnlocks[i] = txt
        end
    end,
    function(card)
        -- Goals progress
        if not ns.Goals or not ns.Goals.GetProgress then return end
        local ok, progress = pcall(ns.Goals.GetProgress, ns.Goals)
        if not ok or not progress then return end

        card._goalsCount:SetText(progress.unlocked .. "/" .. progress.total)
        local pct = progress.total > 0 and (progress.unlocked / progress.total) or 0
        card._goalsBar:SetProgress(pct)

        -- Streaks
        if ns.Goals.GetStreaks then
            local sok, streaks = pcall(ns.Goals.GetStreaks, ns.Goals)
            if sok and streaks then
                card._streakLoginVal:SetText(tostring(streaks.dailyLogin.current) .. "j")
                card._streakRecruitVal:SetText(tostring(streaks.dailyRecruit.current) .. "j")
            end
        end

        -- Next milestone
        if ns.Goals.GetNextMilestone then
            local mok, milestone = pcall(ns.Goals.GetNextMilestone, ns.Goals)
            if mok and milestone then
                card._milestoneName:SetText(milestone.name)
                card._milestoneBar:SetProgress(milestone.target > 0 and (milestone.current / milestone.target) or 0)
                card._milestoneInfo:SetText(tostring(milestone.remaining) .. " restants")
            else
                card._milestoneName:SetText("Tous debloques !")
                card._milestoneName:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
                card._milestoneBar:SetProgress(1)
                card._milestoneInfo:SetText("")
            end
        end

        -- Recent unlocks
        local unlocks = progress.recentUnlocks or {}
        for i = 1, 3 do
            local txt = card._recentUnlocks[i]
            if i <= #unlocks then
                local u = unlocks[i]
                txt:SetText("|cffFFD700*|r " .. (u.name or "?"))
                txt:Show()
            else
                txt:SetText("")
                txt:Hide()
            end
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Smart Suggestions
---------------------------------------------------------------------------
registerWidget("smart_suggestions", "Suggestions", "|cff00d1ff?|r",
    function(card)
        local c = card._content

        -- Suggestion count badge
        card._sugCount = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._sugCount:SetPoint("TOPRIGHT", 0, 0)
        card._sugCount:SetText("")
        card._sugCount:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

        -- Suggestion rows (top 3)
        card._sugRows = {}
        for i = 1, 3 do
            local y = -(i - 1) * 30
            local title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            title:SetPoint("TOPLEFT", 0, y)
            title:SetTextColor(C.text[1], C.text[2], C.text[3])

            local desc = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", 0, y - 14)
            desc:SetPoint("RIGHT", c, "RIGHT", 0, 0)
            desc:SetJustifyH("LEFT")
            desc:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

            card._sugRows[i] = {title = title, desc = desc}
            title:Hide()
            desc:Hide()
        end

        card._emptyText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._emptyText:SetPoint("CENTER")
        card._emptyText:SetText("Aucune suggestion disponible")
        card._emptyText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end,
    function(card)
        if not ns.SmartSuggestions or not ns.SmartSuggestions.GetAllSuggestions then return end
        local ok, suggestions = pcall(ns.SmartSuggestions.GetAllSuggestions, ns.SmartSuggestions)
        if not ok then suggestions = {} end

        -- Badge
        card._sugCount:SetText(#suggestions > 0 and (tostring(#suggestions) .. " suggestions") or "")

        if #suggestions == 0 then
            card._emptyText:Show()
            for _, row in ipairs(card._sugRows) do
                row.title:Hide()
                row.desc:Hide()
            end
            return
        end

        card._emptyText:Hide()

        -- Priority color mapping
        local prioColors = {
            [5] = C.red,
            [4] = C.orange,
            [3] = C.gold,
            [2] = C.accent,
            [1] = C.dim,
        }

        for i = 1, math.min(3, #suggestions) do
            local row = card._sugRows[i]
            local sug = suggestions[i]
            local pColor = prioColors[sug.priority] or C.dim

            row.title:SetText("|cff" .. string.format("%02x%02x%02x",
                math.floor(pColor[1] * 255),
                math.floor(pColor[2] * 255),
                math.floor(pColor[3] * 255)) .. "●|r " .. (sug.title or ""))
            row.title:Show()

            -- Truncate description to fit in the card
            local descText = sug.description or ""
            if #descText > 80 then
                descText = descText:sub(1, 77) .. "..."
            end
            row.desc:SetText(descText)
            row.desc:Show()
        end

        for i = #suggestions + 1, 3 do
            card._sugRows[i].title:Hide()
            card._sugRows[i].desc:Hide()
        end
    end
)

---------------------------------------------------------------------------
-- Widget: Classement Personnel (Leaderboard)
---------------------------------------------------------------------------
registerWidget("personal_leaderboard", "Classement personnel", "|cffFFD700\226\152\133|r",
    function(card)
        local c = card._content

        -- Ligne 1 : Badge du palier + nom du palier
        card._lbTierBadge = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card._lbTierBadge:SetPoint("TOPLEFT", 0, 0)

        card._lbTierLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbTierLabel:SetPoint("LEFT", card._lbTierBadge, "RIGHT", 6, 0)
        card._lbTierLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        -- Ligne 2 : Stats du jour vs record
        card._lbTodayLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbTodayLabel:SetPoint("TOPLEFT", 0, -22)
        card._lbTodayLabel:SetText("Aujourd'hui")
        card._lbTodayLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._lbTodayStats = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbTodayStats:SetPoint("TOPLEFT", 80, -22)
        card._lbTodayStats:SetTextColor(C.text[1], C.text[2], C.text[3])

        card._lbBestLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbBestLabel:SetPoint("TOPLEFT", 200, -22)
        card._lbBestLabel:SetText("Record")
        card._lbBestLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._lbBestStats = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbBestStats:SetPoint("TOPLEFT", 250, -22)
        card._lbBestStats:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

        -- Ligne 3 : Semaine en cours
        card._lbWeekLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbWeekLabel:SetPoint("TOPLEFT", 0, -40)
        card._lbWeekLabel:SetText("Semaine")
        card._lbWeekLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._lbWeekStats = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbWeekStats:SetPoint("TOPLEFT", 80, -40)
        card._lbWeekStats:SetTextColor(C.text[1], C.text[2], C.text[3])

        -- Ligne 4 : Barre de progression vers le prochain palier
        card._lbNextLabel = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbNextLabel:SetPoint("TOPLEFT", 0, -60)
        card._lbNextLabel:SetText("Prochain palier")
        card._lbNextLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

        card._lbNextBar = CreateProgressBar(c, 200, 8, C.gold)
        card._lbNextBar:SetPoint("TOPLEFT", 100, -62)

        card._lbNextPct = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbNextPct:SetPoint("LEFT", card._lbNextBar, "RIGHT", 6, 0)
        card._lbNextPct:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

        -- Texte vide si le module n'est pas disponible
        card._lbEmpty = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card._lbEmpty:SetPoint("CENTER")
        card._lbEmpty:SetText("Classement non disponible")
        card._lbEmpty:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        card._lbEmpty:Hide()
    end,
    function(card)
        if not ns.Leaderboard or not ns.Leaderboard.GetRankInfo then
            card._lbEmpty:Show()
            card._lbTierBadge:SetText("")
            card._lbTierLabel:SetText("")
            card._lbTodayStats:SetText("")
            card._lbBestStats:SetText("")
            card._lbWeekStats:SetText("")
            card._lbNextBar:SetProgress(0)
            card._lbNextPct:SetText("")
            return
        end

        card._lbEmpty:Hide()

        -- Palier actuel
        local ok, rankInfo = pcall(ns.Leaderboard.GetRankInfo, ns.Leaderboard)
        if not ok or not rankInfo then return end

        local tierColor = rankInfo.tierColor or {0.55, 0.58, 0.66}
        local tierHex = ("|cff%02x%02x%02x"):format(
            math.floor(tierColor[1] * 255),
            math.floor(tierColor[2] * 255),
            math.floor(tierColor[3] * 255)
        )
        card._lbTierBadge:SetText(tierHex .. rankInfo.tierName .. "|r")
        card._lbTierBadge:SetTextColor(tierColor[1], tierColor[2], tierColor[3])
        card._lbTierLabel:SetText(("%d recrues au total"):format(rankInfo.totalRecruits or 0))

        -- Stats du jour
        local ok2, today = pcall(ns.Leaderboard.GetToday, ns.Leaderboard)
        if ok2 and today then
            card._lbTodayStats:SetText(("%d msg, %d inv, %d rec"):format(
                today.whispers or 0, today.invited or 0, today.joined or 0))
        end

        -- Record personnel
        local ok3, bests = pcall(ns.Leaderboard.GetPersonalBests, ns.Leaderboard)
        if ok3 and bests then
            card._lbBestStats:SetText(("%d rec/jour"):format(bests.bestDayRecruits or 0))
        end

        -- Semaine en cours
        local ok4, week = pcall(ns.Leaderboard.GetThisWeek, ns.Leaderboard)
        if ok4 and week then
            card._lbWeekStats:SetText(("%d contacts, %d invites, %d recrues"):format(
                week.contacted or 0, week.invited or 0, week.joined or 0))
        end

        -- Barre progression vers prochain palier
        card._lbNextBar:SetProgress(rankInfo.progress or 0)
        local pctDisplay = math.floor((rankInfo.progress or 0) * 100)
        if rankInfo.progress >= 1 then
            card._lbNextPct:SetText("Max !")
            card._lbNextPct:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            card._lbNextLabel:SetText("Palier maximum")
        else
            card._lbNextPct:SetText(("%d%% (%d/%d)"):format(
                pctDisplay, rankInfo.totalRecruits, rankInfo.nextTierAt or 0))
            card._lbNextPct:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
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
    "personal_leaderboard",
    "goals_progress",
    "smart_suggestions",
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
