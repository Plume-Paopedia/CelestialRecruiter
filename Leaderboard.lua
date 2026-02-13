local _, ns = ...

-- =====================================================================
-- CelestialRecruiter  --  Classement Personnel (Leaderboard)
-- Suivi des performances de recrutement : quotidien, hebdo, mensuel,
-- records personnels, paliers et heatmap d'activite
-- =====================================================================

ns.Leaderboard = ns.Leaderboard or {}
local L = ns.Leaderboard

---------------------------------------------------------------------------
-- Paliers (Tiers)
---------------------------------------------------------------------------
local TIERS = {
    { id = "bronze",  name = "Bronze",  color = {0.80, 0.50, 0.20}, minRecruits = 5   },
    { id = "silver",  name = "Argent",  color = {0.75, 0.75, 0.80}, minRecruits = 25  },
    { id = "gold",    name = "Or",      color = {1.00, 0.84, 0.00}, minRecruits = 100 },
    { id = "diamond", name = "Diamant", color = {0.70, 0.85, 1.00}, minRecruits = 500 },
}

---------------------------------------------------------------------------
-- Valeurs par defaut
---------------------------------------------------------------------------
local LEADERBOARD_DEFAULTS = {
    daily = {},
    personalBests = {
        bestDayRecruits = 0,
        bestDayDate = "",
        bestDayContacts = 0,
        bestDayContactsDate = "",
        bestWeekRecruits = 0,
        bestWeekDate = "",
        longestStreak = 0,
        fastestJoinMinutes = 0,
    },
    currentTier = "none",
    totalAllTime = {
        contacted = 0,
        invited = 0,
        joined = 0,
        whispers = 0,
    },
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

local function todayKey()
    return date("%Y-%m-%d", time())
end

local function weekKey(ts)
    ts = ts or time()
    return date("%Y-W%W", ts)
end

local function monthKey(ts)
    ts = ts or time()
    return date("%Y-%m", ts)
end

-- Retourne le jour de la semaine (1=Lundi .. 7=Dimanche)
local function weekdayIndex(ts)
    ts = ts or time()
    local wday = tonumber(date("%w", ts)) or 0  -- 0=Dimanche, 1=Lundi ... 6=Samedi
    if wday == 0 then wday = 7 end  -- Dimanche = 7
    return wday
end

local WEEKDAY_NAMES = {
    [1] = "Lundi",
    [2] = "Mardi",
    [3] = "Mercredi",
    [4] = "Jeudi",
    [5] = "Vendredi",
    [6] = "Samedi",
    [7] = "Dimanche",
}

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function L:Init()
    if not ns.db or not ns.db.global then return end

    if not ns.db.global.leaderboard then
        ns.db.global.leaderboard = deepCopy(LEADERBOARD_DEFAULTS)
    else
        ensureDefaults(ns.db.global.leaderboard, LEADERBOARD_DEFAULTS)
    end

    -- Synchroniser les totaux depuis les contacts existants
    self:_SyncTotalsFromContacts()

    -- Mettre a jour le palier
    self:_UpdateTier()

    -- Mettre a jour les records personnels hebdo
    self:_UpdateWeeklyBest()
end

---------------------------------------------------------------------------
-- _SyncTotalsFromContacts : recalcule les totaux depuis les donnees reelles
---------------------------------------------------------------------------

function L:_SyncTotalsFromContacts()
    if not ns.db or not ns.db.global then return end
    local lb = ns.db.global.leaderboard
    if not lb then return end

    local contacts = ns.db.global.contacts or {}
    local totalContacted = 0
    local totalInvited = 0
    local totalJoined = 0

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
            end
        end
    end

    -- Ne jamais diminuer les totaux (les contacts supprimes ne doivent pas
    -- reduire le compteur historique)
    local totals = lb.totalAllTime
    if totalContacted > totals.contacted then
        totals.contacted = totalContacted
    end
    if totalInvited > totals.invited then
        totals.invited = totalInvited
    end
    if totalJoined > totals.joined then
        totals.joined = totalJoined
    end
end

---------------------------------------------------------------------------
-- _UpdateTier : determine le palier actuel
---------------------------------------------------------------------------

function L:_UpdateTier()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local lb = ns.db.global.leaderboard
    local totalRecruits = lb.totalAllTime.joined or 0

    local tier = "none"
    for _, t in ipairs(TIERS) do
        if totalRecruits >= t.minRecruits then
            tier = t.id
        end
    end
    lb.currentTier = tier
end

---------------------------------------------------------------------------
-- _UpdateWeeklyBest : verifie si la semaine en cours est un record
---------------------------------------------------------------------------

function L:_UpdateWeeklyBest()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local lb = ns.db.global.leaderboard
    local pb = lb.personalBests

    local weekStats = self:GetThisWeek()
    local weekRecruits = weekStats.joined or 0

    if weekRecruits > (pb.bestWeekRecruits or 0) then
        pb.bestWeekRecruits = weekRecruits
        pb.bestWeekDate = weekKey()
    end
end

---------------------------------------------------------------------------
-- _EnsureToday : cree l'entree du jour si elle n'existe pas
---------------------------------------------------------------------------

function L:_EnsureToday()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return nil end
    local lb = ns.db.global.leaderboard
    local key = todayKey()

    if not lb.daily[key] then
        lb.daily[key] = {
            contacted = 0,
            invited = 0,
            joined = 0,
            whispers = 0,
        }
    end

    return lb.daily[key]
end

---------------------------------------------------------------------------
-- _UpdatePersonalBests : verifie les records apres chaque evenement
---------------------------------------------------------------------------

function L:_UpdatePersonalBests()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local lb = ns.db.global.leaderboard
    local pb = lb.personalBests
    local key = todayKey()
    local today = lb.daily[key]
    if not today then return end

    -- Meilleur jour en recrues
    if (today.joined or 0) > (pb.bestDayRecruits or 0) then
        pb.bestDayRecruits = today.joined
        pb.bestDayDate = key
    end

    -- Meilleur jour en contacts
    if (today.contacted or 0) > (pb.bestDayContacts or 0) then
        pb.bestDayContacts = today.contacted
        pb.bestDayContactsDate = key
    end

    -- Meilleure semaine
    self:_UpdateWeeklyBest()

    -- Serie la plus longue (depuis Goals si disponible)
    if ns.Goals and ns.Goals.GetStreaks then
        local ok, streaks = pcall(ns.Goals.GetStreaks, ns.Goals)
        if ok and streaks and streaks.dailyRecruit then
            local best = streaks.dailyRecruit.best or 0
            if best > (pb.longestStreak or 0) then
                pb.longestStreak = best
            end
        end
    end
end

---------------------------------------------------------------------------
-- _CleanupOldDays : supprime les entrees de plus de 365 jours
---------------------------------------------------------------------------

function L:_CleanupOldDays()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local lb = ns.db.global.leaderboard
    local cutoff = date("%Y-%m-%d", time() - (365 * 24 * 3600))

    for day in pairs(lb.daily) do
        if day < cutoff then
            lb.daily[day] = nil
        end
    end
end

---------------------------------------------------------------------------
-- RecordDaily : appele quand un evenement se produit
-- eventType: "contact", "invite", "join", "whisper"
---------------------------------------------------------------------------

function L:RecordDaily(eventType)
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local lb = ns.db.global.leaderboard

    local today = self:_EnsureToday()
    if not today then return end

    -- Incrementer le compteur du jour
    if eventType == "contact" then
        today.contacted = (today.contacted or 0) + 1
        lb.totalAllTime.contacted = (lb.totalAllTime.contacted or 0) + 1
    elseif eventType == "invite" then
        today.invited = (today.invited or 0) + 1
        lb.totalAllTime.invited = (lb.totalAllTime.invited or 0) + 1
    elseif eventType == "join" then
        today.joined = (today.joined or 0) + 1
        lb.totalAllTime.joined = (lb.totalAllTime.joined or 0) + 1
    elseif eventType == "whisper" then
        today.whispers = (today.whispers or 0) + 1
        lb.totalAllTime.whispers = (lb.totalAllTime.whispers or 0) + 1
    end

    -- Mettre a jour records personnels
    self:_UpdatePersonalBests()

    -- Mettre a jour le palier
    self:_UpdateTier()

    -- Nettoyage periodique (1 chance sur 100)
    if math.random(100) == 1 then
        self:_CleanupOldDays()
    end
end

---------------------------------------------------------------------------
-- RecordFastestJoin : enregistre le temps le plus rapide contact -> join
-- minutes: nombre de minutes entre le premier contact et le join
---------------------------------------------------------------------------

function L:RecordFastestJoin(minutes)
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then return end
    local pb = ns.db.global.leaderboard.personalBests
    if not pb then return end

    minutes = tonumber(minutes) or 0
    if minutes <= 0 then return end

    if (pb.fastestJoinMinutes or 0) <= 0 or minutes < pb.fastestJoinMinutes then
        pb.fastestJoinMinutes = minutes
    end
end

---------------------------------------------------------------------------
-- GetToday : retourne les stats du jour
---------------------------------------------------------------------------

function L:GetToday()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local key = todayKey()
    local today = ns.db.global.leaderboard.daily[key]

    if not today then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    return {
        contacted = today.contacted or 0,
        invited = today.invited or 0,
        joined = today.joined or 0,
        whispers = today.whispers or 0,
    }
end

---------------------------------------------------------------------------
-- GetThisWeek : retourne les stats aggregees de la semaine en cours
---------------------------------------------------------------------------

function L:GetThisWeek()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local lb = ns.db.global.leaderboard
    local now = time()
    local result = { contacted = 0, invited = 0, joined = 0, whispers = 0 }

    -- Determiner le lundi de cette semaine
    local wday = weekdayIndex(now)  -- 1=Lundi..7=Dimanche
    local daysSinceMonday = wday - 1
    local mondayTs = now - (daysSinceMonday * 86400)

    -- Parcourir les 7 derniers jours (lundi a aujourd'hui)
    for i = 0, 6 do
        local dayTs = mondayTs + (i * 86400)
        local key = date("%Y-%m-%d", dayTs)
        local day = lb.daily[key]
        if day then
            result.contacted = result.contacted + (day.contacted or 0)
            result.invited = result.invited + (day.invited or 0)
            result.joined = result.joined + (day.joined or 0)
            result.whispers = result.whispers + (day.whispers or 0)
        end
    end

    return result
end

---------------------------------------------------------------------------
-- GetThisMonth : retourne les stats aggregees du mois en cours
---------------------------------------------------------------------------

function L:GetThisMonth()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local lb = ns.db.global.leaderboard
    local currentMonth = monthKey()
    local result = { contacted = 0, invited = 0, joined = 0, whispers = 0 }

    for day, data in pairs(lb.daily) do
        -- Verifier que le jour est dans le mois courant (YYYY-MM)
        if day:sub(1, 7) == currentMonth then
            result.contacted = result.contacted + (data.contacted or 0)
            result.invited = result.invited + (data.invited or 0)
            result.joined = result.joined + (data.joined or 0)
            result.whispers = result.whispers + (data.whispers or 0)
        end
    end

    return result
end

---------------------------------------------------------------------------
-- GetPersonalBests : retourne les records personnels
---------------------------------------------------------------------------

function L:GetPersonalBests()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return deepCopy(LEADERBOARD_DEFAULTS.personalBests)
    end

    local pb = ns.db.global.leaderboard.personalBests
    return {
        bestDayRecruits = pb.bestDayRecruits or 0,
        bestDayDate = pb.bestDayDate or "",
        bestDayContacts = pb.bestDayContacts or 0,
        bestDayContactsDate = pb.bestDayContactsDate or "",
        bestWeekRecruits = pb.bestWeekRecruits or 0,
        bestWeekDate = pb.bestWeekDate or "",
        longestStreak = pb.longestStreak or 0,
        fastestJoinMinutes = pb.fastestJoinMinutes or 0,
    }
end

---------------------------------------------------------------------------
-- GetTier : retourne le palier actuel
---------------------------------------------------------------------------

function L:GetTier()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return "none"
    end
    return ns.db.global.leaderboard.currentTier or "none"
end

---------------------------------------------------------------------------
-- GetHistory : retourne les N derniers jours de stats
---------------------------------------------------------------------------

function L:GetHistory(days)
    days = days or 30
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return {}
    end

    local lb = ns.db.global.leaderboard
    local now = time()
    local history = {}

    for i = days - 1, 0, -1 do
        local dayTs = now - (i * 86400)
        local key = date("%Y-%m-%d", dayTs)
        local day = lb.daily[key]
        table.insert(history, {
            date = key,
            contacted = day and (day.contacted or 0) or 0,
            invited = day and (day.invited or 0) or 0,
            joined = day and (day.joined or 0) or 0,
            whispers = day and (day.whispers or 0) or 0,
        })
    end

    return history
end

---------------------------------------------------------------------------
-- GetWeekdayStats : retourne la moyenne d'activite par jour de semaine
---------------------------------------------------------------------------

function L:GetWeekdayStats()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return {}
    end

    local lb = ns.db.global.leaderboard
    local weekdays = {}

    -- Initialiser les 7 jours
    for i = 1, 7 do
        weekdays[i] = {
            index = i,
            name = WEEKDAY_NAMES[i],
            totalContacted = 0,
            totalInvited = 0,
            totalJoined = 0,
            totalWhispers = 0,
            dayCount = 0,
        }
    end

    -- Parcourir toutes les entrees quotidiennes
    for dayStr, data in pairs(lb.daily) do
        -- Reconstituer le timestamp depuis la date YYYY-MM-DD
        local y, m, d = dayStr:match("^(%d+)-(%d+)-(%d+)$")
        if y and m and d then
            local ts = time({
                year = tonumber(y),
                month = tonumber(m),
                day = tonumber(d),
                hour = 12,
            })
            local wday = weekdayIndex(ts)
            local wd = weekdays[wday]
            if wd then
                wd.totalContacted = wd.totalContacted + (data.contacted or 0)
                wd.totalInvited = wd.totalInvited + (data.invited or 0)
                wd.totalJoined = wd.totalJoined + (data.joined or 0)
                wd.totalWhispers = wd.totalWhispers + (data.whispers or 0)
                wd.dayCount = wd.dayCount + 1
            end
        end
    end

    -- Calculer les moyennes
    for i = 1, 7 do
        local wd = weekdays[i]
        local count = math.max(1, wd.dayCount)
        wd.avgContacted = math.floor(wd.totalContacted / count + 0.5)
        wd.avgInvited = math.floor(wd.totalInvited / count + 0.5)
        wd.avgJoined = math.floor(wd.totalJoined / count + 0.5)
        wd.avgWhispers = math.floor(wd.totalWhispers / count + 0.5)
        wd.avgTotal = wd.avgContacted + wd.avgInvited + wd.avgJoined + wd.avgWhispers
    end

    return weekdays
end

---------------------------------------------------------------------------
-- GetRankInfo : retourne les informations completes de classement
---------------------------------------------------------------------------

function L:GetRankInfo()
    if not ns.db or not ns.db.global or not ns.db.global.leaderboard then
        return {
            tier = "none",
            tierName = "Debutant",
            tierColor = {0.55, 0.58, 0.66},
            totalRecruits = 0,
            nextTierAt = TIERS[1].minRecruits,
            progress = 0,
        }
    end

    local lb = ns.db.global.leaderboard
    local totalRecruits = lb.totalAllTime.joined or 0
    local currentTier = lb.currentTier or "none"

    -- Trouver les informations du palier actuel et suivant
    local tierName = "Debutant"
    local tierColor = {0.55, 0.58, 0.66}
    local nextTierAt = TIERS[1].minRecruits
    local prevTierAt = 0
    local progress = 0
    local foundCurrent = false

    for i, t in ipairs(TIERS) do
        if t.id == currentTier then
            tierName = t.name
            tierColor = t.color
            prevTierAt = t.minRecruits
            foundCurrent = true

            -- Palier suivant
            if i < #TIERS then
                nextTierAt = TIERS[i + 1].minRecruits
            else
                -- Deja au palier max
                nextTierAt = t.minRecruits
                progress = 1
            end
        end
    end

    -- Calculer la progression vers le prochain palier
    if not foundCurrent then
        -- Pas encore de palier : progression vers Bronze
        nextTierAt = TIERS[1].minRecruits
        prevTierAt = 0
        progress = nextTierAt > 0 and (totalRecruits / nextTierAt) or 0
    elseif progress < 1 then
        local range = nextTierAt - prevTierAt
        local current = totalRecruits - prevTierAt
        progress = range > 0 and (current / range) or 0
    end

    progress = math.max(0, math.min(1, progress))

    return {
        tier = currentTier,
        tierName = tierName,
        tierColor = tierColor,
        totalRecruits = totalRecruits,
        nextTierAt = nextTierAt,
        progress = progress,
    }
end

---------------------------------------------------------------------------
-- Reset : reinitialise toutes les donnees du classement
---------------------------------------------------------------------------

function L:Reset()
    if ns.db and ns.db.global then
        ns.db.global.leaderboard = nil
    end
    self:Init()
end
