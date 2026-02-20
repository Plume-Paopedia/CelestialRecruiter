local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Recruitment Campaigns System
-- Create, manage, and track recruitment campaigns with goals
-- ═══════════════════════════════════════════════════════════════════

ns.Campaigns = ns.Campaigns or {}
local Camp = ns.Campaigns

---------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------
function Camp:Init()
    if not ns.db or not ns.db.global then return end
    if not ns.db.global.campaigns then
        ns.db.global.campaigns = {}
    end
end

---------------------------------------------------------------------------
-- Campaign Structure
-- campaign = {
--   id, name, description, status (draft/active/paused/completed/archived),
--   template, targetFilters = {levelMin, levelMax, classes, zones, excludeCrossRealm},
--   goals = {targetContacted, targetInvited, targetJoined},
--   stats = {contacted, invited, joined, replies, startedAt, completedAt},
--   contacts = {[key]=true}, -- contacts processed by this campaign
--   schedule = {days={}, startHour, endHour},
--   createdAt, updatedAt
-- }
---------------------------------------------------------------------------

function Camp:Create(name, description)
    self:Init()

    local id = "camp_" .. time() .. "_" .. math.random(1000, 9999)

    local campaign = {
        id = id,
        name = name or "Nouvelle campagne",
        description = description or "",
        status = "draft",
        template = "default",
        targetFilters = {
            levelMin = 10,
            levelMax = 80,
            classes = {},       -- empty = all
            zones = {},         -- empty = all
            excludeCrossRealm = false,
        },
        goals = {
            targetContacted = 50,
            targetInvited = 20,
            targetJoined = 5,
        },
        stats = {
            contacted = 0,
            invited = 0,
            joined = 0,
            replies = 0,
            startedAt = 0,
            completedAt = 0,
        },
        contacts = {},
        schedule = {
            enabled = false,
            days = {true, true, true, true, true, true, true}, -- Mon-Sun
            startHour = 18,
            endHour = 23,
        },
        createdAt = time(),
        updatedAt = time(),
    }

    ns.db.global.campaigns[id] = campaign
    ns.DB_Log("CAMP", "Campagne creee: " .. name)
    return campaign
end

function Camp:Delete(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if camp then
        if camp.status == "active" then
            self:Pause(campId)
        end
        ns.db.global.campaigns[campId] = nil
        ns.DB_Log("CAMP", "Campagne supprimee: " .. (camp.name or campId))
    end
end

function Camp:Update(campId, patch)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    for k, v in pairs(patch) do
        if k ~= "id" and k ~= "createdAt" then
            camp[k] = v
        end
    end
    camp.updatedAt = time()
end

---------------------------------------------------------------------------
-- Campaign Control
---------------------------------------------------------------------------
function Camp:Start(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return false end

    camp.status = "active"
    camp.stats.startedAt = time()
    camp.updatedAt = time()

    ns.DB_Log("CAMP", "Campagne demarree: " .. camp.name)
    if ns.Notifications_Success then
        ns.Notifications_Success("Campagne", "Demarree: " .. camp.name)
    end
    return true
end

function Camp:Pause(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp or camp.status ~= "active" then return false end

    camp.status = "paused"
    camp.updatedAt = time()

    ns.DB_Log("CAMP", "Campagne en pause: " .. camp.name)
    return true
end

function Camp:Resume(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp or camp.status ~= "paused" then return false end

    camp.status = "active"
    camp.updatedAt = time()
    return true
end

function Camp:Complete(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    camp.status = "completed"
    camp.stats.completedAt = time()
    camp.updatedAt = time()

    ns.DB_Log("CAMP", ("Campagne termin\195\169e: %s - Contact\195\169s: %d, Invit\195\169s: %d, Recrues: %d"):format(
        camp.name, camp.stats.contacted, camp.stats.invited, camp.stats.joined))

    if ns.Notifications_Success then
        ns.Notifications_Success("Campagne terminee",
            ("%s - %d recrues"):format(camp.name, camp.stats.joined))
    end
end

function Camp:Archive(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    if camp.status == "active" then
        self:Pause(campId)
    end
    camp.status = "archived"
    camp.updatedAt = time()
end

---------------------------------------------------------------------------
-- Filtering
---------------------------------------------------------------------------
function Camp:MatchesFilters(campId, key, contact, scanData)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return false end

    -- Already processed by this campaign
    if camp.contacts[key] then return false end

    local filters = camp.targetFilters

    -- Level check
    local level = (contact and contact.level) or (scanData and scanData.level) or 0
    if level > 0 then
        if level < filters.levelMin or level > filters.levelMax then
            return false
        end
    end

    -- Class check
    local hasClassFilter = false
    for _ in pairs(filters.classes) do hasClassFilter = true; break end
    if hasClassFilter then
        local classFile = (contact and contact.classFile) or (scanData and scanData.classFile) or ""
        if not filters.classes[classFile] then
            return false
        end
    end

    -- Cross-realm check
    if filters.excludeCrossRealm then
        local isCrossRealm = (contact and contact.crossRealm) or (scanData and scanData.crossRealm)
        if isCrossRealm then return false end
    end

    -- Zone check
    local hasZoneFilter = false
    for _ in pairs(filters.zones) do hasZoneFilter = true; break end
    if hasZoneFilter then
        local zone = (scanData and scanData.zone) or ""
        if zone ~= "" and not filters.zones[zone] then
            return false
        end
    end

    return true
end

function Camp:CheckSchedule(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp or not camp.schedule.enabled then return true end

    local hour = tonumber(date("%H"))
    local wday = tonumber(date("%w")) -- 0=Sun, 1=Mon, ..., 6=Sat
    -- Convert to 1=Mon...7=Sun
    local dayIndex = wday == 0 and 7 or wday

    -- Check day
    if not camp.schedule.days[dayIndex] then return false end

    -- Check hour
    local startH = camp.schedule.startHour
    local endH = camp.schedule.endHour
    if startH <= endH then
        return hour >= startH and hour <= endH
    else
        return hour >= startH or hour <= endH
    end
end

---------------------------------------------------------------------------
-- Record Events
---------------------------------------------------------------------------
function Camp:RecordContacted(campId, key)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    camp.contacts[key] = true
    camp.stats.contacted = camp.stats.contacted + 1
    camp.updatedAt = time()

    self:CheckGoals(campId)
end

function Camp:RecordInvited(campId, key)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    camp.stats.invited = camp.stats.invited + 1
    camp.updatedAt = time()

    self:CheckGoals(campId)
end

function Camp:RecordJoined(campId, key)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    camp.stats.joined = camp.stats.joined + 1
    camp.updatedAt = time()

    self:CheckGoals(campId)
end

function Camp:RecordReply(campId, key)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return end

    camp.stats.replies = camp.stats.replies + 1
    camp.updatedAt = time()
end

---------------------------------------------------------------------------
-- Goal Tracking
---------------------------------------------------------------------------
function Camp:CheckGoals(campId)
    local camp = ns.db.global.campaigns[campId]
    if not camp or camp.status ~= "active" then return end

    local goals = camp.goals
    local stats = camp.stats

    -- Check if all goals are met
    local allMet = true
    if goals.targetContacted > 0 and stats.contacted < goals.targetContacted then
        allMet = false
    end
    if goals.targetInvited > 0 and stats.invited < goals.targetInvited then
        allMet = false
    end
    if goals.targetJoined > 0 and stats.joined < goals.targetJoined then
        allMet = false
    end

    if allMet then
        self:Complete(campId)
    end
end

function Camp:GetProgress(campId)
    self:Init()
    local camp = ns.db.global.campaigns[campId]
    if not camp then return {} end

    local goals = camp.goals
    local stats = camp.stats

    return {
        contacted = {
            current = stats.contacted,
            target = goals.targetContacted,
            pct = goals.targetContacted > 0 and (stats.contacted / goals.targetContacted * 100) or 0,
        },
        invited = {
            current = stats.invited,
            target = goals.targetInvited,
            pct = goals.targetInvited > 0 and (stats.invited / goals.targetInvited * 100) or 0,
        },
        joined = {
            current = stats.joined,
            target = goals.targetJoined,
            pct = goals.targetJoined > 0 and (stats.joined / goals.targetJoined * 100) or 0,
        },
        replies = stats.replies,
        duration = stats.startedAt > 0 and (time() - stats.startedAt) or 0,
        contactCount = stats.contacted + stats.invited + stats.joined,
    }
end

---------------------------------------------------------------------------
-- Active Campaign for Auto-Recruiter Integration
---------------------------------------------------------------------------
function Camp:GetActiveCampaigns()
    self:Init()
    local active = {}
    for id, camp in pairs(ns.db.global.campaigns) do
        if camp.status == "active" then
            table.insert(active, camp)
        end
    end
    return active
end

function Camp:GetCampaignForContact(key, contact, scanData)
    -- Find the first active campaign that matches this contact
    local active = self:GetActiveCampaigns()
    for _, camp in ipairs(active) do
        if self:CheckSchedule(camp.id) and self:MatchesFilters(camp.id, key, contact, scanData) then
            return camp
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- List & Query
---------------------------------------------------------------------------
function Camp:GetAll()
    self:Init()
    local campaigns = {}
    for id, camp in pairs(ns.db.global.campaigns) do
        table.insert(campaigns, camp)
    end
    -- Sort by creation date, newest first
    table.sort(campaigns, function(a, b) return a.createdAt > b.createdAt end)
    return campaigns
end

function Camp:Get(campId)
    self:Init()
    return ns.db.global.campaigns[campId]
end

function Camp:GetByStatus(status)
    self:Init()
    local result = {}
    for id, camp in pairs(ns.db.global.campaigns) do
        if camp.status == status then
            table.insert(result, camp)
        end
    end
    table.sort(result, function(a, b) return a.createdAt > b.createdAt end)
    return result
end

---------------------------------------------------------------------------
-- Summary Stats (across all campaigns)
---------------------------------------------------------------------------
function Camp:GetGlobalStats()
    self:Init()
    local total = {
        campaigns = 0,
        active = 0,
        completed = 0,
        contacted = 0,
        invited = 0,
        joined = 0,
        replies = 0,
    }

    for _, camp in pairs(ns.db.global.campaigns) do
        total.campaigns = total.campaigns + 1
        if camp.status == "active" then total.active = total.active + 1 end
        if camp.status == "completed" then total.completed = total.completed + 1 end
        total.contacted = total.contacted + camp.stats.contacted
        total.invited = total.invited + camp.stats.invited
        total.joined = total.joined + camp.stats.joined
        total.replies = total.replies + camp.stats.replies
    end

    return total
end

---------------------------------------------------------------------------
-- Duplicate Campaign (for reuse)
---------------------------------------------------------------------------
function Camp:Duplicate(campId)
    self:Init()
    local original = ns.db.global.campaigns[campId]
    if not original then return nil end

    local copy = self:Create(original.name .. " (copie)", original.description)
    copy.template = original.template
    copy.targetFilters = {
        levelMin = original.targetFilters.levelMin,
        levelMax = original.targetFilters.levelMax,
        classes = {},
        zones = {},
        excludeCrossRealm = original.targetFilters.excludeCrossRealm,
    }
    for k, v in pairs(original.targetFilters.classes) do
        copy.targetFilters.classes[k] = v
    end
    for k, v in pairs(original.targetFilters.zones) do
        copy.targetFilters.zones[k] = v
    end
    copy.goals = {
        targetContacted = original.goals.targetContacted,
        targetInvited = original.goals.targetInvited,
        targetJoined = original.goals.targetJoined,
    }
    copy.schedule = {
        enabled = original.schedule.enabled,
        days = {},
        startHour = original.schedule.startHour,
        endHour = original.schedule.endHour,
    }
    for i, v in ipairs(original.schedule.days) do
        copy.schedule.days[i] = v
    end

    return copy
end
