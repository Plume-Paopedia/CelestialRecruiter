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
    if not ns.db then return end

    local lb = ns.db.char.leaderboard
    if not lb then return end

    -- Ensure nested tables exist
    ensureDefaults(lb, LEADERBOARD_DEFAULTS)

    -- Migration: copy old global leaderboard data to first character
    if not ns.db.char._leaderboardMigrated then
        ns.db.char._leaderboardMigrated = true
        local oldLb = ns.db.global.leaderboard
        if oldLb and not ns.db.global._leaderboardMigrated then
            -- First character to load inherits accumulated stats
            if oldLb.totalAllTime then
                for k, v in pairs(oldLb.totalAllTime) do
                    if type(v) == "number" and v > (lb.totalAllTime[k] or 0) then
                        lb.totalAllTime[k] = v
                    end
                end
            end
            if oldLb.personalBests then
                for k, v in pairs(oldLb.personalBests) do
                    lb.personalBests[k] = v
                end
            end
            if oldLb.daily then
                for k, v in pairs(oldLb.daily) do
                    lb.daily[k] = deepCopy(v)
                end
            end
            lb.currentTier = oldLb.currentTier or lb.currentTier
            ns.db.global._leaderboardMigrated = true
        end
    end

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
    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local lb = ns.db.char.leaderboard
    local totalRecruits = lb.totalAllTime.joined or 0

    local tier = "none"
    for _, t in ipairs(TIERS) do
        if totalRecruits >= t.minRecruits then
            tier = t.id
        end
    end

    -- Tier gate: Free users capped at Silver, full leaderboard requires Recruteur+
    if ns.Tier and not ns.Tier:CanUse("leaderboard_full") then
        if tier == "gold" or tier == "diamond" then
            ns.Tier:ShowUpgrade("leaderboard_full")
            tier = "silver"
        end
    end

    lb.currentTier = tier
end

---------------------------------------------------------------------------
-- _UpdateWeeklyBest : verifie si la semaine en cours est un record
---------------------------------------------------------------------------

function L:_UpdateWeeklyBest()
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return nil end
    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local lb = ns.db.char.leaderboard
    local cutoff = date("%Y-%m-%d", time() - (365 * 24 * 3600))

    local toRemove = {}
    for day in pairs(lb.daily) do
        if day < cutoff then
            toRemove[#toRemove + 1] = day
        end
    end
    for _, day in ipairs(toRemove) do
        lb.daily[day] = nil
    end
end

---------------------------------------------------------------------------
-- RecordDaily : appele quand un evenement se produit
-- eventType: "contact", "invite", "join", "whisper"
---------------------------------------------------------------------------

function L:RecordDaily(eventType)
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local lb = ns.db.char.leaderboard

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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then return end
    local pb = ns.db.char.leaderboard.personalBests
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local key = todayKey()
    local today = ns.db.char.leaderboard.daily[key]

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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return { contacted = 0, invited = 0, joined = 0, whispers = 0 }
    end

    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return deepCopy(LEADERBOARD_DEFAULTS.personalBests)
    end

    local pb = ns.db.char.leaderboard.personalBests
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return "none"
    end
    return ns.db.char.leaderboard.currentTier or "none"
end

---------------------------------------------------------------------------
-- GetHistory : retourne les N derniers jours de stats
---------------------------------------------------------------------------

function L:GetHistory(days)
    days = days or 30
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return {}
    end

    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return {}
    end

    local lb = ns.db.char.leaderboard
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
    if not ns.db or not ns.db.char or not ns.db.char.leaderboard then
        return {
            tier = "none",
            tierName = "Debutant",
            tierColor = {0.55, 0.58, 0.66},
            totalRecruits = 0,
            nextTierAt = TIERS[1].minRecruits,
            progress = 0,
        }
    end

    local lb = ns.db.char.leaderboard
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
    if ns.db and ns.db.char then
        ns.db.char.leaderboard = nil
    end
    self:Init()
end

---------------------------------------------------------------------------
-- Guild-Wide Leaderboard via Addon Communication
---------------------------------------------------------------------------
local ADDON_PREFIX = "CelRec"
local GUILD_DATA_VERSION = 1
local BROADCAST_INTERVAL = 300  -- broadcast every 5 minutes

function L:InitGuildSync()
    if not C_ChatInfo or not C_ChatInfo.RegisterAddonMessagePrefix then return end
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

    if not ns.db.global.guildRanking then
        ns.db.global.guildRanking = {}
    end

    ns.CR:RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, message, channel, sender)
        if prefix ~= ADDON_PREFIX or channel ~= "GUILD" then return end
        self:_ReceiveGuildData(sender, message)
    end)

    -- Initial broadcast after 10s, then every 5 minutes
    C_Timer.After(10, function() self:BroadcastStats() end)
    C_Timer.NewTicker(BROADCAST_INTERVAL, function() self:BroadcastStats() end)

    self:_CleanupGuildRanking()
end

function L:BroadcastStats()
    if not IsInGuild() then return end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end

    local lb = ns.db and ns.db.char and ns.db.char.leaderboard
    if not lb then return end

    local totals = lb.totalAllTime or {}
    local today = self:GetToday()
    local tier = lb.currentTier or "none"

    local data = string.format("%d|%s|%d|%d|%d|%d|%d",
        GUILD_DATA_VERSION, tier,
        totals.contacted or 0, totals.invited or 0, totals.joined or 0,
        today.contacted or 0, today.joined or 0)

    pcall(C_ChatInfo.SendAddonMessage, ADDON_PREFIX, data, "GUILD")
end

function L:_ReceiveGuildData(sender, message)
    if not sender or not message then return end
    local key = ns.Util_Key(sender)
    if not key then return end

    local parts = {}
    for part in message:gmatch("[^|]+") do
        parts[#parts + 1] = part
    end
    if #parts < 7 then return end
    if tonumber(parts[1]) ~= GUILD_DATA_VERSION then return end

    if not ns.db.global.guildRanking then
        ns.db.global.guildRanking = {}
    end

    ns.db.global.guildRanking[key] = {
        name = key,
        tier = parts[2],
        totalContacted = tonumber(parts[3]) or 0,
        totalInvited = tonumber(parts[4]) or 0,
        totalJoined = tonumber(parts[5]) or 0,
        todayContacted = tonumber(parts[6]) or 0,
        todayJoined = tonumber(parts[7]) or 0,
        lastUpdate = time(),
    }
end

function L:_CleanupGuildRanking()
    if not ns.db.global.guildRanking then return end
    local cutoff = time() - (7 * 86400)
    local toRemove = {}
    for key, data in pairs(ns.db.global.guildRanking) do
        if (data.lastUpdate or 0) < cutoff then
            toRemove[#toRemove + 1] = key
        end
    end
    for _, key in ipairs(toRemove) do
        ns.db.global.guildRanking[key] = nil
    end
end

function L:GetGuildRanking()
    if not ns.db.global.guildRanking then
        ns.db.global.guildRanking = {}
    end

    -- Include self in the ranking
    local myName = UnitName("player")
    local myRealm = GetRealmName()
    if myName and myRealm then
        local myKey = ns.Util_Key(myName .. "-" .. myRealm)
        local lb = ns.db.char.leaderboard
        if lb and myKey then
            local totals = lb.totalAllTime or {}
            local today = self:GetToday()
            ns.db.global.guildRanking[myKey] = {
                name = myKey,
                tier = lb.currentTier or "none",
                totalContacted = totals.contacted or 0,
                totalInvited = totals.invited or 0,
                totalJoined = totals.joined or 0,
                todayContacted = today.contacted or 0,
                todayJoined = today.joined or 0,
                lastUpdate = time(),
                isSelf = true,
            }
        end
    end

    local ranking = {}
    for _, data in pairs(ns.db.global.guildRanking) do
        ranking[#ranking + 1] = data
    end

    table.sort(ranking, function(a, b)
        if (a.totalJoined or 0) ~= (b.totalJoined or 0) then
            return (a.totalJoined or 0) > (b.totalJoined or 0)
        end
        return (a.totalContacted or 0) > (b.totalContacted or 0)
    end)

    return ranking
end

local TIER_LABELS = {
    none = {name = "Debutant",  color = {0.55, 0.58, 0.66}},
    bronze = {name = "Bronze",  color = {0.80, 0.50, 0.20}},
    silver = {name = "Argent",  color = {0.75, 0.75, 0.80}},
    gold = {name = "Or",        color = {1.00, 0.84, 0.00}},
    diamond = {name = "Diamant",color = {0.70, 0.85, 1.00}},
}

function L:GetTierLabel(tierId)
    return TIER_LABELS[tierId or "none"] or TIER_LABELS.none
end
