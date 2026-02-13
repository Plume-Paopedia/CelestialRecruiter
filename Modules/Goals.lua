local _, ns = ...

-- =====================================================================
-- CelestialRecruiter  --  Goals, Achievements & Streaks System
-- Gamification: milestones, streaks, and unlockable achievements
-- =====================================================================

ns.Goals = ns.Goals or {}
local G = ns.Goals

---------------------------------------------------------------------------
-- All 13 WoW retail classes
---------------------------------------------------------------------------
local ALL_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

---------------------------------------------------------------------------
-- Achievement Definitions
---------------------------------------------------------------------------
local ACHIEVEMENTS = {
    -- ===== RECRUTEMENT =====
    {
        id = "first_contact",
        name = "Premiere prise de contact",
        description = "Envoyer un message a votre premier contact.",
        icon = "|TInterface\\Icons\\Achievement_Character_Human_Male:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 1
        end,
    },
    {
        id = "ten_contacts",
        name = "Recruteur debutant",
        description = "Contacter 10 personnes.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_EverybodysFriend:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 10
        end,
    },
    {
        id = "fifty_contacts",
        name = "Recruteur confirme",
        description = "Contacter 50 personnes.",
        icon = "|TInterface\\Icons\\Achievement_Reputation_08:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 50
        end,
    },
    {
        id = "hundred_contacts",
        name = "Recruteur expert",
        description = "Contacter 100 personnes.",
        icon = "|TInterface\\Icons\\Achievement_Reputation_07:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 100
        end,
    },
    {
        id = "five_hundred",
        name = "Maitre recruteur",
        description = "Contacter 500 personnes.",
        icon = "|TInterface\\Icons\\Achievement_Reputation_06:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 500
        end,
    },
    {
        id = "thousand_contacts",
        name = "Legende vivante",
        description = "Contacter 1000 personnes.",
        icon = "|TInterface\\Icons\\Achievement_Reputation_05:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalContacted or 0) >= 1000
        end,
    },
    {
        id = "first_recruit",
        name = "Premiere recrue",
        description = "Un joueur contacte rejoint la guilde.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_WorkingOvertime:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalJoined or 0) >= 1
        end,
    },
    {
        id = "ten_recruits",
        name = "Chasseur de talents",
        description = "10 joueurs contactes ont rejoint la guilde.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_MountUp:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalJoined or 0) >= 10
        end,
    },
    {
        id = "fifty_recruits",
        name = "Legende du recrutement",
        description = "50 joueurs contactes ont rejoint la guilde.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_MassResurrection:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalJoined or 0) >= 50
        end,
    },
    {
        id = "guild_builder",
        name = "Batisseur de guilde",
        description = "100 joueurs contactes ont rejoint la guilde.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_Reinforce:16|t",
        category = "recrutement",
        condition = function(data)
            return (data.milestones.totalJoined or 0) >= 100
        end,
    },

    -- ===== SOCIAL =====
    {
        id = "social_butterfly",
        name = "Papillon social",
        description = "Recevoir des reponses de 10 contacts differents.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_HappyHour:16|t",
        category = "social",
        condition = function(data)
            return (data.totalReplies or 0) >= 10
        end,
    },
    {
        id = "conversation_starter",
        name = "Brise-glace",
        description = "Recevoir des reponses de 25 contacts differents.",
        icon = "|TInterface\\Icons\\Spell_Holy_PrayerOfHealing:16|t",
        category = "social",
        condition = function(data)
            return (data.totalReplies or 0) >= 25
        end,
    },
    {
        id = "all_classes",
        name = "Arc-en-ciel",
        description = "Recruter au moins un joueur de chaque classe.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_BountifulBags:16|t",
        category = "social",
        condition = function(data)
            if not data.classesRecruited then return false end
            for _, class in ipairs(ALL_CLASSES) do
                if not data.classesRecruited[class] then
                    return false
                end
            end
            return true
        end,
    },
    {
        id = "conversion_king",
        name = "Roi de la conversion",
        description = "Taux de conversion superieur a 30% avec 20+ contacts.",
        icon = "|TInterface\\Icons\\Achievement_Arena_2v2_7:16|t",
        category = "social",
        condition = function(data)
            local contacted = data.milestones.totalContacted or 0
            local joined = data.milestones.totalJoined or 0
            if contacted < 20 then return false end
            return (joined / contacted * 100) > 30
        end,
    },

    -- ===== DEDICATION =====
    {
        id = "streak_3",
        name = "Regulier",
        description = "Se connecter et recruter 3 jours d'affilee.",
        icon = "|TInterface\\Icons\\Spell_Holy_BlessingOfStrength:16|t",
        category = "dedication",
        condition = function(data)
            local streak = data.streaks and data.streaks.dailyRecruit
            return streak and (streak.best or 0) >= 3
        end,
    },
    {
        id = "streak_7",
        name = "Dedie",
        description = "Recruter 7 jours d'affilee.",
        icon = "|TInterface\\Icons\\Spell_Holy_DivineIllumination:16|t",
        category = "dedication",
        condition = function(data)
            local streak = data.streaks and data.streaks.dailyRecruit
            return streak and (streak.best or 0) >= 7
        end,
    },
    {
        id = "streak_14",
        name = "Infatigable",
        description = "Recruter 14 jours d'affilee.",
        icon = "|TInterface\\Icons\\Spell_Holy_Perseverance:16|t",
        category = "dedication",
        condition = function(data)
            local streak = data.streaks and data.streaks.dailyRecruit
            return streak and (streak.best or 0) >= 14
        end,
    },
    {
        id = "streak_30",
        name = "Inarretable",
        description = "Recruter 30 jours d'affilee.",
        icon = "|TInterface\\Icons\\Spell_Holy_AuraOfLight:16|t",
        category = "dedication",
        condition = function(data)
            local streak = data.streaks and data.streaks.dailyRecruit
            return streak and (streak.best or 0) >= 30
        end,
    },
    {
        id = "login_streak_7",
        name = "Fidele",
        description = "Se connecter 7 jours d'affilee.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_WorkingOvertime_Rank2:16|t",
        category = "dedication",
        condition = function(data)
            local streak = data.streaks and data.streaks.dailyLogin
            return streak and (streak.best or 0) >= 7
        end,
    },
    {
        id = "scanner_50",
        name = "Explorateur assidu",
        description = "Effectuer 50 scans.",
        icon = "|TInterface\\Icons\\INV_Misc_Spyglass_03:16|t",
        category = "dedication",
        condition = function(data)
            return (data.milestones.totalScans or 0) >= 50
        end,
    },

    -- ===== MASTERY =====
    {
        id = "night_owl",
        name = "Hibou nocturne",
        description = "Recruter entre 23h et 5h du matin.",
        icon = "|TInterface\\Icons\\Spell_Shadow_EyeOfKilrogg:16|t",
        category = "mastery",
        condition = function(data)
            return data.nightOwlTriggered == true
        end,
    },
    {
        id = "early_bird",
        name = "Leve-tot",
        description = "Recruter entre 5h et 8h du matin.",
        icon = "|TInterface\\Icons\\Ability_Hunter_EagleEye:16|t",
        category = "mastery",
        condition = function(data)
            return data.earlyBirdTriggered == true
        end,
    },
    {
        id = "speed_demon",
        name = "Ultra-rapide",
        description = "Contacter 10 personnes en moins d'une heure.",
        icon = "|TInterface\\Icons\\Ability_Rogue_Sprint:16|t",
        category = "mastery",
        condition = function(data)
            return data.speedDemonTriggered == true
        end,
    },
    {
        id = "template_master",
        name = "Maitre des modeles",
        description = "Utiliser les 3 modeles integres au moins une fois.",
        icon = "|TInterface\\Icons\\INV_Inscription_Scroll:16|t",
        category = "mastery",
        condition = function(data)
            if not data.templatesUsed then return false end
            return data.templatesUsed["default"] and data.templatesUsed["raid"] and data.templatesUsed["short"]
        end,
    },
    {
        id = "perfectionist",
        name = "Perfectionniste",
        description = "100% de conversion sur 5+ contacts dans une journee.",
        icon = "|TInterface\\Icons\\Achievement_Arena_5v5_7:16|t",
        category = "mastery",
        condition = function(data)
            return data.perfectionistTriggered == true
        end,
    },
}

-- Build a fast lookup by ID
local ACHIEVEMENT_BY_ID = {}
for _, ach in ipairs(ACHIEVEMENTS) do
    ACHIEVEMENT_BY_ID[ach.id] = ach
end

-- Category ordering for display
local CATEGORY_ORDER = {
    recrutement = 1,
    social      = 2,
    dedication  = 3,
    mastery     = 4,
}

---------------------------------------------------------------------------
-- Defaults for the saved data structure
---------------------------------------------------------------------------
local GOALS_DEFAULTS = {
    achievements = {},
    streaks = {
        dailyLogin   = { current = 0, best = 0, lastDay = "" },
        dailyRecruit = { current = 0, best = 0, lastDay = "" },
        weeklyGoal   = { current = 0, best = 0, lastWeek = "" },
    },
    milestones = {
        totalContacted = 0,
        totalInvited   = 0,
        totalJoined    = 0,
        totalScans     = 0,
    },
    templatesUsed      = {},
    contactTimestamps  = {},   -- ring buffer of recent contact timestamps for speed_demon
    nightOwlTriggered  = false,
    earlyBirdTriggered = false,
    speedDemonTriggered = false,
    perfectionistTriggered = false,
    lastChecked = 0,
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function ensureDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = deepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            ensureDefaults(dst[k], v)
        end
    end
end

local function today()
    return date("%Y-%m-%d", time())
end

local function currentWeek()
    return date("%Y-W%W", time())
end

local function currentHour()
    return tonumber(date("%H", time())) or 0
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function G:Init()
    if not ns.db or not ns.db.global then return end

    if not ns.db.global.goals then
        ns.db.global.goals = deepCopy(GOALS_DEFAULTS)
    else
        ensureDefaults(ns.db.global.goals, GOALS_DEFAULTS)
    end

    -- Update the daily login streak on every session start
    self:UpdateStreak("dailyLogin")

    -- Do an initial scan of contacts to sync milestones
    self:UpdateMilestones()

    -- Check for any newly qualified achievements
    self:CheckAchievements()
end

---------------------------------------------------------------------------
-- UpdateMilestones: re-count from live contact data
---------------------------------------------------------------------------

function G:UpdateMilestones()
    if not ns.db or not ns.db.global then return end
    local goals = ns.db.global.goals
    if not goals then return end

    local contacts = ns.db.global.contacts or {}
    local totalContacted = 0
    local totalInvited   = 0
    local totalJoined    = 0
    local totalReplies   = 0
    local classesRecruited = {}
    local templatesUsed  = goals.templatesUsed or {}

    for _, c in pairs(contacts) do
        if c then
            local status = c.status or "new"
            if status == "contacted" or status == "invited" or status == "joined" then
                totalContacted = totalContacted + 1
            end
            if status == "invited" or status == "joined" then
                totalInvited = totalInvited + 1
            end
            if status == "joined" then
                totalJoined = totalJoined + 1
                if c.classFile and c.classFile ~= "" then
                    classesRecruited[c.classFile] = true
                end
            end
            -- A reply is indicated by lastWhisperIn > 0 and the contact was previously messaged
            if (c.lastWhisperIn or 0) > 0 and (c.lastWhisperOut or 0) > 0 then
                totalReplies = totalReplies + 1
            end
            -- Track template usage
            if c.lastTemplate and c.lastTemplate ~= "" then
                templatesUsed[c.lastTemplate] = true
            end
        end
    end

    goals.milestones.totalContacted = totalContacted
    goals.milestones.totalInvited   = totalInvited
    goals.milestones.totalJoined    = totalJoined
    goals.templatesUsed             = templatesUsed

    -- Store computed values for achievement checks
    goals._totalReplies      = totalReplies
    goals._classesRecruited  = classesRecruited
end

---------------------------------------------------------------------------
-- UpdateStreak
---------------------------------------------------------------------------

function G:UpdateStreak(streakType)
    if not ns.db or not ns.db.global or not ns.db.global.goals then return end
    local goals = ns.db.global.goals
    local streaks = goals.streaks
    if not streaks then return end

    if streakType == "dailyLogin" or streakType == "dailyRecruit" then
        local streak = streaks[streakType]
        if not streak then return end

        local todayStr = today()

        if streak.lastDay == todayStr then
            -- Already recorded today, nothing to do
            return
        end

        -- Check if yesterday was the last recorded day (consecutive)
        local yesterdayTs = time() - 86400
        local yesterdayStr = date("%Y-%m-%d", yesterdayTs)

        if streak.lastDay == yesterdayStr then
            streak.current = streak.current + 1
        else
            -- Streak broken (or first ever entry)
            streak.current = 1
        end

        streak.lastDay = todayStr

        if streak.current > streak.best then
            streak.best = streak.current
        end

    elseif streakType == "weeklyGoal" then
        local streak = streaks.weeklyGoal
        if not streak then return end

        local weekStr = currentWeek()

        if streak.lastWeek == weekStr then
            return
        end

        -- Check if last week was the previous ISO week
        local lastWeekTs = time() - (7 * 86400)
        local lastWeekStr = date("%Y-W%W", lastWeekTs)

        if streak.lastWeek == lastWeekStr then
            streak.current = streak.current + 1
        else
            streak.current = 1
        end

        streak.lastWeek = weekStr

        if streak.current > streak.best then
            streak.best = streak.current
        end
    end
end

---------------------------------------------------------------------------
-- RecordActivity: called from Queue/Core/Scanner when events happen
-- activityType: "contact", "invite", "join", "scan", "reply"
---------------------------------------------------------------------------

function G:RecordActivity(activityType)
    if not ns.db or not ns.db.global or not ns.db.global.goals then return end
    local goals = ns.db.global.goals

    -- Update milestone counters
    if activityType == "contact" then
        goals.milestones.totalContacted = (goals.milestones.totalContacted or 0) + 1

        -- Track time for speed_demon check
        local now = time()
        if not goals.contactTimestamps then goals.contactTimestamps = {} end
        table.insert(goals.contactTimestamps, now)

        -- Keep only timestamps from the last hour
        local oneHourAgo = now - 3600
        local pruned = {}
        for _, ts in ipairs(goals.contactTimestamps) do
            if ts >= oneHourAgo then
                table.insert(pruned, ts)
            end
        end
        goals.contactTimestamps = pruned

        -- Speed demon: 10 contacts within one hour
        if #goals.contactTimestamps >= 10 then
            goals.speedDemonTriggered = true
        end

        -- Night owl / early bird time check
        local hour = currentHour()
        if hour >= 23 or hour < 5 then
            goals.nightOwlTriggered = true
        end
        if hour >= 5 and hour < 8 then
            goals.earlyBirdTriggered = true
        end

        -- Update daily recruit streak
        self:UpdateStreak("dailyRecruit")

    elseif activityType == "invite" then
        goals.milestones.totalInvited = (goals.milestones.totalInvited or 0) + 1

    elseif activityType == "join" then
        goals.milestones.totalJoined = (goals.milestones.totalJoined or 0) + 1

        -- Check perfectionist: 100% conversion in a day with 5+ contacts
        self:_CheckPerfectionist()

    elseif activityType == "scan" then
        goals.milestones.totalScans = (goals.milestones.totalScans or 0) + 1

    elseif activityType == "reply" then
        -- Replies are counted by UpdateMilestones from contact data
        -- No incremental counter needed here
    end

    -- Re-sync milestones from live data to catch any derived stats
    self:UpdateMilestones()

    -- Check achievements after every activity
    self:CheckAchievements()
end

---------------------------------------------------------------------------
-- _CheckPerfectionist: see if today has 5+ contacts all joined
---------------------------------------------------------------------------

function G:_CheckPerfectionist()
    if not ns.db or not ns.db.global then return end
    local goals = ns.db.global.goals
    if not goals or goals.perfectionistTriggered then return end

    local contacts = ns.db.global.contacts or {}
    local todayStr = today()
    local contactedToday = 0
    local joinedToday = 0

    for _, c in pairs(contacts) do
        if c then
            -- Check if the contact was first contacted today
            local contactDay = ""
            if c.lastWhisperOut and c.lastWhisperOut > 0 then
                contactDay = date("%Y-%m-%d", c.lastWhisperOut)
            end
            if contactDay == todayStr then
                contactedToday = contactedToday + 1
                if c.status == "joined" then
                    joinedToday = joinedToday + 1
                end
            end
        end
    end

    if contactedToday >= 5 and joinedToday == contactedToday then
        goals.perfectionistTriggered = true
    end
end

---------------------------------------------------------------------------
-- CheckAchievements: loop all definitions, unlock new ones
---------------------------------------------------------------------------

function G:CheckAchievements()
    if not ns.db or not ns.db.global or not ns.db.global.goals then return end
    local goals = ns.db.global.goals

    -- Build the data snapshot for condition checks
    local data = {
        milestones          = goals.milestones or {},
        streaks             = goals.streaks or {},
        totalReplies        = goals._totalReplies or 0,
        classesRecruited    = goals._classesRecruited or {},
        templatesUsed       = goals.templatesUsed or {},
        nightOwlTriggered   = goals.nightOwlTriggered or false,
        earlyBirdTriggered  = goals.earlyBirdTriggered or false,
        speedDemonTriggered = goals.speedDemonTriggered or false,
        perfectionistTriggered = goals.perfectionistTriggered or false,
    }

    local achievements = goals.achievements
    if not achievements then
        achievements = {}
        goals.achievements = achievements
    end

    for _, def in ipairs(ACHIEVEMENTS) do
        -- Skip already unlocked achievements
        if not achievements[def.id] then
            -- Safely evaluate condition
            local ok, result = pcall(def.condition, data)
            if ok and result then
                achievements[def.id] = {
                    unlockedAt = time(),
                }
                -- Notify the player
                if ns.Notifications_Achievement then
                    ns.Notifications_Achievement(
                        "Succes debloque !",
                        def.name .. " - " .. def.description,
                        def.icon
                    )
                elseif ns.Notifications_Success then
                    ns.Notifications_Success(
                        "Succes debloque !",
                        def.icon .. " " .. def.name .. " - " .. def.description
                    )
                end
                -- Play achievement particle effect
                if ns.ParticleSystem and ns.ParticleSystem.PlayAchievementEffect and ns._mainFrame and ns._mainFrame:IsVisible() then
                    ns.ParticleSystem:PlayAchievementEffect(ns._mainFrame)
                end
                if ns.DB_Log then ns.DB_Log("GOAL", "Succes debloque: " .. def.name) end
            end
        end
    end

    goals.lastChecked = time()
end

---------------------------------------------------------------------------
-- GetProgress: overall progress summary
---------------------------------------------------------------------------

function G:GetProgress()
    if not ns.db or not ns.db.global or not ns.db.global.goals then
        return { unlocked = 0, total = #ACHIEVEMENTS, percentage = 0, recentUnlocks = {} }
    end

    local achievements = ns.db.global.goals.achievements or {}
    local unlocked = 0
    local recentUnlocks = {}

    for _, def in ipairs(ACHIEVEMENTS) do
        if achievements[def.id] then
            unlocked = unlocked + 1
            table.insert(recentUnlocks, {
                id          = def.id,
                name        = def.name,
                description = def.description,
                icon        = def.icon,
                category    = def.category,
                unlockedAt  = achievements[def.id].unlockedAt,
            })
        end
    end

    -- Sort recent unlocks by unlockedAt descending (newest first)
    table.sort(recentUnlocks, function(a, b)
        return (a.unlockedAt or 0) > (b.unlockedAt or 0)
    end)

    -- Keep only the 5 most recent
    local trimmed = {}
    for i = 1, math.min(5, #recentUnlocks) do
        trimmed[i] = recentUnlocks[i]
    end

    local total = #ACHIEVEMENTS
    local percentage = total > 0 and math.floor(unlocked / total * 100) or 0

    return {
        unlocked      = unlocked,
        total         = total,
        percentage    = percentage,
        recentUnlocks = trimmed,
    }
end

---------------------------------------------------------------------------
-- GetAllAchievements: full list with unlocked status, sorted
---------------------------------------------------------------------------

function G:GetAllAchievements()
    local achievements = (ns.db and ns.db.global and ns.db.global.goals and ns.db.global.goals.achievements) or {}

    local result = {}
    for _, def in ipairs(ACHIEVEMENTS) do
        local unlockData = achievements[def.id]
        table.insert(result, {
            id          = def.id,
            name        = def.name,
            description = def.description,
            icon        = def.icon,
            category    = def.category,
            unlocked    = unlockData ~= nil,
            unlockedAt  = unlockData and unlockData.unlockedAt or nil,
        })
    end

    -- Sort: by category order, then unlocked first within each category
    table.sort(result, function(a, b)
        local catA = CATEGORY_ORDER[a.category] or 99
        local catB = CATEGORY_ORDER[b.category] or 99
        if catA ~= catB then
            return catA < catB
        end
        -- Within same category: unlocked achievements first
        if a.unlocked ~= b.unlocked then
            return a.unlocked
        end
        -- Within same unlock status: keep definition order (by name as fallback)
        return a.name < b.name
    end)

    return result
end

---------------------------------------------------------------------------
-- GetStreaks: return current streak data
---------------------------------------------------------------------------

function G:GetStreaks()
    if not ns.db or not ns.db.global or not ns.db.global.goals then
        return {
            dailyLogin   = { current = 0, best = 0, lastDay = "" },
            dailyRecruit = { current = 0, best = 0, lastDay = "" },
            weeklyGoal   = { current = 0, best = 0, lastWeek = "" },
        }
    end

    local streaks = ns.db.global.goals.streaks or {}

    -- Return copies to avoid external mutation
    return {
        dailyLogin = {
            current = (streaks.dailyLogin and streaks.dailyLogin.current) or 0,
            best    = (streaks.dailyLogin and streaks.dailyLogin.best) or 0,
            lastDay = (streaks.dailyLogin and streaks.dailyLogin.lastDay) or "",
        },
        dailyRecruit = {
            current = (streaks.dailyRecruit and streaks.dailyRecruit.current) or 0,
            best    = (streaks.dailyRecruit and streaks.dailyRecruit.best) or 0,
            lastDay = (streaks.dailyRecruit and streaks.dailyRecruit.lastDay) or "",
        },
        weeklyGoal = {
            current = (streaks.weeklyGoal and streaks.weeklyGoal.current) or 0,
            best    = (streaks.weeklyGoal and streaks.weeklyGoal.best) or 0,
            lastWeek = (streaks.weeklyGoal and streaks.weeklyGoal.lastWeek) or "",
        },
    }
end

---------------------------------------------------------------------------
-- GetNextMilestone: find closest unachieved milestone with progress
---------------------------------------------------------------------------

function G:GetNextMilestone()
    if not ns.db or not ns.db.global or not ns.db.global.goals then
        return nil
    end

    local goals = ns.db.global.goals
    local achievements = goals.achievements or {}
    local milestones = goals.milestones or {}

    -- Define milestone tiers with their progress metric
    local MILESTONE_TIERS = {
        { id = "first_contact",     metric = "totalContacted", target = 1 },
        { id = "ten_contacts",      metric = "totalContacted", target = 10 },
        { id = "fifty_contacts",    metric = "totalContacted", target = 50 },
        { id = "hundred_contacts",  metric = "totalContacted", target = 100 },
        { id = "five_hundred",      metric = "totalContacted", target = 500 },
        { id = "thousand_contacts", metric = "totalContacted", target = 1000 },
        { id = "first_recruit",     metric = "totalJoined",    target = 1 },
        { id = "ten_recruits",      metric = "totalJoined",    target = 10 },
        { id = "fifty_recruits",    metric = "totalJoined",    target = 50 },
        { id = "scanner_50",        metric = "totalScans",     target = 50 },
        { id = "streak_3",          metric = "streakRecruit",  target = 3 },
        { id = "streak_7",          metric = "streakRecruit",  target = 7 },
        { id = "streak_14",         metric = "streakRecruit",  target = 14 },
        { id = "streak_30",         metric = "streakRecruit",  target = 30 },
    }

    local closest = nil
    local closestRemaining = math.huge

    for _, tier in ipairs(MILESTONE_TIERS) do
        if not achievements[tier.id] then
            local current = 0
            if tier.metric == "streakRecruit" then
                local streak = goals.streaks and goals.streaks.dailyRecruit
                current = streak and streak.best or 0
            else
                current = milestones[tier.metric] or 0
            end

            local remaining = tier.target - current
            if remaining < 0 then remaining = 0 end

            if remaining < closestRemaining then
                closestRemaining = remaining
                local def = ACHIEVEMENT_BY_ID[tier.id]
                closest = {
                    id          = tier.id,
                    name        = def and def.name or tier.id,
                    description = def and def.description or "",
                    icon        = def and def.icon or "",
                    category    = def and def.category or "",
                    current     = current,
                    target      = tier.target,
                    remaining   = remaining,
                    percentage  = tier.target > 0 and math.floor(current / tier.target * 100) or 0,
                }
            end
        end
    end

    return closest
end

---------------------------------------------------------------------------
-- GetUnlockedCount: simple count of unlocked achievements
---------------------------------------------------------------------------

function G:GetUnlockedCount()
    if not ns.db or not ns.db.global or not ns.db.global.goals then
        return 0
    end

    local achievements = ns.db.global.goals.achievements or {}
    local count = 0
    for _ in pairs(achievements) do
        count = count + 1
    end
    return count
end

---------------------------------------------------------------------------
-- GetTotalCount: total number of defined achievements
---------------------------------------------------------------------------

function G:GetTotalCount()
    return #ACHIEVEMENTS
end

---------------------------------------------------------------------------
-- Reset: clear all goals data (used by /cr reset or debug)
---------------------------------------------------------------------------

function G:Reset()
    if ns.db and ns.db.global then
        ns.db.global.goals = nil
    end
    self:Init()
end
