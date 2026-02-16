local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Advanced Statistics & Analytics
-- Track conversion rates, optimal times, template performance
-- ═══════════════════════════════════════════════════════════════════

ns.Statistics = ns.Statistics or {}
local Stats = ns.Statistics

-- Initialize stats structure in DB if not present
function Stats:Init()
    if not ns.db.global.statistics then
        ns.db.global.statistics = {
            hourlyActivity = {},     -- Track activity by hour of day (0-23)
            templateStats = {},      -- Track success rate per template
            dailyHistory = {},       -- Last 30 days of activity
            conversionFunnel = {     -- Conversion tracking
                contacted = 0,
                invited = 0,
                joined = 0,
            },
            classStats = {},         -- Success rate by class
            levelRangeStats = {},    -- Success rate by level range
            sourceStats = {},        -- Where contacts come from (scanner, inbox, etc.)
        }
    end
end

-- Record an event for statistics
function Stats:RecordEvent(eventType, data)
    if not ns.db.global.statistics then self:Init() end
    local stats = ns.db.global.statistics

    local now = ns.Util_Now()
    local hour = tonumber(date("%H", now))
    local day = date("%Y-%m-%d", now)

    -- Hourly activity tracking
    if not stats.hourlyActivity[hour] then
        stats.hourlyActivity[hour] = 0
    end
    stats.hourlyActivity[hour] = stats.hourlyActivity[hour] + 1

    -- Daily history tracking
    if not stats.dailyHistory[day] then
        stats.dailyHistory[day] = {
            scans = 0,
            contacted = 0,
            invited = 0,
            joined = 0,
            found = 0,
        }
    end

    -- Track specific events
    if eventType == "scan" then
        stats.dailyHistory[day].scans = stats.dailyHistory[day].scans + 1
    elseif eventType == "contacted" then
        stats.dailyHistory[day].contacted = stats.dailyHistory[day].contacted + 1
        stats.conversionFunnel.contacted = stats.conversionFunnel.contacted + 1

        -- Template stats
        if data and data.template then
            if not stats.templateStats[data.template] then
                stats.templateStats[data.template] = {used = 0, success = 0}
            end
            stats.templateStats[data.template].used = stats.templateStats[data.template].used + 1
        end
    elseif eventType == "invited" then
        stats.dailyHistory[day].invited = stats.dailyHistory[day].invited + 1
        stats.conversionFunnel.invited = stats.conversionFunnel.invited + 1
    elseif eventType == "joined" then
        stats.dailyHistory[day].joined = stats.dailyHistory[day].joined + 1
        stats.conversionFunnel.joined = stats.conversionFunnel.joined + 1

        -- Mark template as successful if contact has template data
        if data and data.contact and data.contact.lastTemplate then
            local tpl = data.contact.lastTemplate
            if stats.templateStats[tpl] then
                stats.templateStats[tpl].success = stats.templateStats[tpl].success + 1
            end
        end

        -- Class stats
        if data and data.contact and data.contact.classFile then
            local class = data.contact.classFile
            if not stats.classStats[class] then
                stats.classStats[class] = {recruited = 0}
            end
            stats.classStats[class].recruited = stats.classStats[class].recruited + 1
        end
    elseif eventType == "found" then
        stats.dailyHistory[day].found = (stats.dailyHistory[day].found or 0) + (data and data.count or 1)
    end

    -- Cleanup old daily history (keep last 90 days)
    local cutoffDay = date("%Y-%m-%d", now - (90 * 24 * 3600))
    local toRemove = {}
    for d in pairs(stats.dailyHistory) do
        if d < cutoffDay then
            toRemove[#toRemove + 1] = d
        end
    end
    for _, d in ipairs(toRemove) do
        stats.dailyHistory[d] = nil
    end
end

-- Get conversion rates
function Stats:GetConversionRates()
    if not ns.db.global.statistics then self:Init() end
    local funnel = ns.db.global.statistics.conversionFunnel

    local contactToInvite = funnel.contacted > 0 and (funnel.invited / funnel.contacted * 100) or 0
    local inviteToJoin = funnel.invited > 0 and (funnel.joined / funnel.invited * 100) or 0
    local contactToJoin = funnel.contacted > 0 and (funnel.joined / funnel.contacted * 100) or 0

    return {
        contactToInvite = contactToInvite,
        inviteToJoin = inviteToJoin,
        contactToJoin = contactToJoin,
        totalContacted = funnel.contacted,
        totalInvited = funnel.invited,
        totalJoined = funnel.joined,
    }
end

-- Get best hours for recruiting (based on success rate)
function Stats:GetBestHours()
    -- Tier gate: advanced stats require Recruteur+
    if ns.Tier and not ns.Tier:CanUse("stats_advanced") then
        ns.Tier:ShowUpgrade("stats_advanced")
        return {}
    end
    if not ns.db.global.statistics then self:Init() end
    local hourly = ns.db.global.statistics.hourlyActivity

    local hours = {}
    for h = 0, 23 do
        table.insert(hours, {
            hour = h,
            activity = hourly[h] or 0,
        })
    end

    -- Sort by activity
    table.sort(hours, function(a, b) return a.activity > b.activity end)

    return hours
end

-- Get template performance (success rate)
function Stats:GetTemplatePerformance()
    -- Tier gate: advanced stats require Recruteur+
    if ns.Tier and not ns.Tier:CanUse("stats_advanced") then
        ns.Tier:ShowUpgrade("stats_advanced")
        return {}
    end
    if not ns.db.global.statistics then self:Init() end
    local tplStats = ns.db.global.statistics.templateStats

    local performance = {}
    for tplId, data in pairs(tplStats) do
        local successRate = data.used > 0 and (data.success / data.used * 100) or 0
        table.insert(performance, {
            template = tplId,
            used = data.used,
            success = data.success,
            successRate = successRate,
        })
    end

    -- Sort by success rate
    table.sort(performance, function(a, b) return a.successRate > b.successRate end)

    return performance
end

-- Get daily activity for last N days
function Stats:GetDailyActivity(days)
    if not ns.db.global.statistics then self:Init() end
    local daily = ns.db.global.statistics.dailyHistory

    days = days or 30
    -- Tier gate: clamp history days
    if ns.Tier then
      local maxDays = ns.Tier:GetLimit("stats_history_days")
      if days > maxDays then days = maxDays end
    end
    local now = ns.Util_Now()
    local activity = {}

    for i = days - 1, 0, -1 do
        local day = date("%Y-%m-%d", now - (i * 24 * 3600))
        local data = daily[day] or {scans = 0, contacted = 0, invited = 0, joined = 0, found = 0}
        table.insert(activity, {
            day = day,
            scans = data.scans,
            contacted = data.contacted,
            invited = data.invited,
            joined = data.joined,
            found = data.found,
        })
    end

    return activity
end

-- Get class distribution (how many of each class recruited)
function Stats:GetClassDistribution()
    if not ns.db.global.statistics then self:Init() end
    local classStats = ns.db.global.statistics.classStats

    local distribution = {}
    local total = 0

    for class, data in pairs(classStats) do
        total = total + data.recruited
        table.insert(distribution, {
            class = class,
            recruited = data.recruited,
        })
    end

    -- Calculate percentages
    for _, data in ipairs(distribution) do
        data.percentage = total > 0 and (data.recruited / total * 100) or 0
    end

    -- Sort by recruited count
    table.sort(distribution, function(a, b) return a.recruited > b.recruited end)

    return distribution, total
end

-- Get recruiting trends (comparing this week vs last week)
function Stats:GetTrends()
    -- Tier gate: trends require Recruteur+
    if ns.Tier and not ns.Tier:CanUse("stats_advanced") then
        ns.Tier:ShowUpgrade("stats_advanced")
        return { contactedChange = 0, invitedChange = 0, joinedChange = 0 }
    end
    local daily = self:GetDailyActivity(14)
    if #daily < 14 then
        return {
            contactedChange = 0,
            invitedChange = 0,
            joinedChange = 0,
        }
    end

    -- Sum last 7 days and previous 7 days
    local thisWeek = {contacted = 0, invited = 0, joined = 0}
    local lastWeek = {contacted = 0, invited = 0, joined = 0}

    for i = 1, 7 do
        lastWeek.contacted = lastWeek.contacted + daily[i].contacted
        lastWeek.invited = lastWeek.invited + daily[i].invited
        lastWeek.joined = lastWeek.joined + daily[i].joined
    end

    for i = 8, 14 do
        thisWeek.contacted = thisWeek.contacted + daily[i].contacted
        thisWeek.invited = thisWeek.invited + daily[i].invited
        thisWeek.joined = thisWeek.joined + daily[i].joined
    end

    -- Calculate percentage change
    local function calcChange(current, previous)
        if previous == 0 then return current > 0 and 100 or 0 end
        return ((current - previous) / previous) * 100
    end

    return {
        contactedChange = calcChange(thisWeek.contacted, lastWeek.contacted),
        invitedChange = calcChange(thisWeek.invited, lastWeek.invited),
        joinedChange = calcChange(thisWeek.joined, lastWeek.joined),
        thisWeek = thisWeek,
        lastWeek = lastWeek,
    }
end

-- Get overall summary statistics
function Stats:GetSummary()
    local conversion = self:GetConversionRates()
    local trends = self:GetTrends()
    local bestHours = self:GetBestHours()
    local templates = self:GetTemplatePerformance()

    -- Get top template
    local topTemplate = templates[1]

    -- Get best 3 hours
    local bestThreeHours = {}
    for i = 1, math.min(3, #bestHours) do
        table.insert(bestThreeHours, bestHours[i].hour)
    end

    return {
        conversion = conversion,
        trends = trends,
        topTemplate = topTemplate,
        bestHours = bestThreeHours,
    }
end

-- Reset all statistics (with confirmation)
function Stats:Reset()
    if ns.db.global.statistics then
        ns.db.global.statistics = nil
    end
    self:Init()
end
