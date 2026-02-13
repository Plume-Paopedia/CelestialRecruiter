local _, ns = ...

-- =====================================================================
-- CelestialRecruiter  --  SmartSuggestions
-- Analyzes recruitment data and provides actionable suggestions
-- =====================================================================

ns.SmartSuggestions = ns.SmartSuggestions or {}
local SS = ns.SmartSuggestions

-- All 13 WoW retail classes
local ALL_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

-- Ideal class distribution (roughly equal, ~7.7% each)
local IDEAL_PCT = 100 / #ALL_CLASSES

-- Seconds in one day
local DAY_SEC = 86400

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getNow()
    if ns.Util_Now then return ns.Util_Now() end
    return time()
end

local function safeCall(fn, ...)
    if not fn then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function hasDB()
    return ns.db and ns.db.global
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
function SS:Init()
    -- Nothing to persist; all suggestions are computed on-the-fly.
end

---------------------------------------------------------------------------
-- 1.  Best Time to Recruit
---------------------------------------------------------------------------
function SS:GetBestTimeToRecruit()
    if not ns.Statistics then
        return { hour = 20, reason = "Pas assez de donnees. Essaie en soiree (20h)." }
    end

    local hours = safeCall(ns.Statistics.GetBestHours, ns.Statistics)
    if not hours or #hours == 0 then
        return { hour = 20, reason = "Aucune donnee horaire disponible. Essaie vers 20h." }
    end

    -- hours is sorted by activity descending; first entry is the best
    local best = hours[1]
    if not best or (best.activity or 0) == 0 then
        return { hour = 20, reason = "Pas encore d'activite enregistree. Essaie vers 20h." }
    end

    local currentHour = tonumber(date("%H")) or 0
    local reason

    if currentHour == best.hour then
        reason = string.format(
            "C'est le meilleur moment ! %dh est ton heure la plus active (%d actions enregistrees).",
            best.hour, best.activity
        )
    else
        local diff = best.hour - currentHour
        if diff < 0 then diff = diff + 24 end
        reason = string.format(
            "L'heure optimale est %dh (%d actions). Reviens dans ~%dh pour maximiser tes chances.",
            best.hour, best.activity, diff
        )
    end

    return { hour = best.hour, reason = reason }
end

---------------------------------------------------------------------------
-- 2.  Best Template
---------------------------------------------------------------------------
function SS:GetBestTemplate()
    if not ns.Statistics then
        return { templateId = "default", successRate = 0, reason = "Stats indisponibles, template par defaut recommande." }
    end

    local perf = safeCall(ns.Statistics.GetTemplatePerformance, ns.Statistics)
    if not perf or #perf == 0 then
        return { templateId = "default", successRate = 0, reason = "Aucune donnee de template. Utilise le template par defaut pour commencer." }
    end

    -- perf is sorted by successRate descending
    local best = perf[1]

    -- Resolve template display name
    local tplName = best.template or "default"
    if ns.Templates_All then
        local all = ns.Templates_All()
        if all and all[best.template] then
            tplName = all[best.template].name or best.template
        end
    end

    local reason = string.format(
        "Le template '%s' a le meilleur taux de succes : %.0f%% (%d/%d utilisations converties).",
        tplName, best.successRate or 0, best.success or 0, best.used or 0
    )

    return {
        templateId = best.template,
        successRate = best.successRate,
        reason = reason,
    }
end

---------------------------------------------------------------------------
-- 3.  Contacts to Re-contact  (stale contacted, score > 40)
---------------------------------------------------------------------------
function SS:GetContactsToRecontact()
    if not hasDB() or not ns.db.global.contacts then return {} end

    local now = getNow()
    local threeDays = 3 * DAY_SEC
    local results = {}

    for key, contact in pairs(ns.db.global.contacts) do
        -- Must be "contacted" but NOT "invited" / "joined"
        if contact.status == "contacted" then
            -- Determine when they were contacted (lastWhisperOut or lastSeen)
            local contactedAt = contact.lastWhisperOut
            if (not contactedAt or contactedAt == 0) then
                contactedAt = contact.lastSeen or contact.firstSeen or 0
            end

            local elapsed = now - contactedAt
            if elapsed >= threeDays then
                -- Reputation score check
                local score = 0
                if ns.Reputation and ns.Reputation.CalculateScore then
                    score = safeCall(ns.Reputation.CalculateScore, ns.Reputation, contact) or 0
                end

                if score > 40 then
                    local daysSince = math.floor(elapsed / DAY_SEC)
                    table.insert(results, {
                        key = key,
                        contact = contact,
                        score = score,
                        daysSince = daysSince,
                    })
                end
            end
        end
    end

    -- Sort by score descending
    table.sort(results, function(a, b) return a.score > b.score end)

    -- Limit to top 10
    local capped = {}
    for i = 1, math.min(10, #results) do
        capped[i] = results[i]
    end
    return capped
end

---------------------------------------------------------------------------
-- 4.  Hot Leads  (in queue, score >= 70, not yet contacted)
---------------------------------------------------------------------------
function SS:GetHotLeads()
    if not hasDB() then return {} end
    if not ns.DB_QueueList then return {} end

    local queueKeys = safeCall(ns.DB_QueueList) or {}
    local results = {}

    for _, key in ipairs(queueKeys) do
        local contact = ns.DB_GetContact and ns.DB_GetContact(key)
        if contact and contact.status ~= "contacted" and contact.status ~= "invited" and contact.status ~= "joined" then
            local score = 0
            if ns.Reputation and ns.Reputation.CalculateScore then
                score = safeCall(ns.Reputation.CalculateScore, ns.Reputation, contact) or 0
            end

            if score >= 70 then
                table.insert(results, {
                    key = key,
                    contact = contact,
                    score = score,
                })
            end
        end
    end

    -- Sort by score descending
    table.sort(results, function(a, b) return a.score > b.score end)

    -- Limit to top 10
    local capped = {}
    for i = 1, math.min(10, #results) do
        capped[i] = results[i]
    end
    return capped
end

---------------------------------------------------------------------------
-- 5.  Class Gaps
---------------------------------------------------------------------------
function SS:GetClassGaps()
    if not ns.Statistics then return {} end

    local dist, total = nil, 0
    local ok, r1, r2 = pcall(ns.Statistics.GetClassDistribution, ns.Statistics)
    if ok then
        dist = r1
        total = r2 or 0
    end

    if not dist then return {} end

    -- Build lookup of recruited counts
    local recruited = {}
    for _, entry in ipairs(dist) do
        recruited[entry.class] = entry.recruited
    end

    -- If total is 0 we cannot compute meaningful gaps
    if total == 0 then return {} end

    local results = {}
    for _, class in ipairs(ALL_CLASSES) do
        local count = recruited[class] or 0
        local actualPct = (count / total) * 100
        local gap = IDEAL_PCT - actualPct  -- positive = under-represented

        if gap > 2 then  -- only flag classes notably underrepresented
            table.insert(results, {
                class = class,
                recruited = count,
                gap = gap,
                suggestion = string.format(
                    "%s est sous-represente (%.0f%% vs %.0f%% ideal). Cible davantage cette classe.",
                    class, actualPct, IDEAL_PCT
                ),
            })
        end
    end

    -- Sort by gap descending (biggest gap first)
    table.sort(results, function(a, b) return a.gap > b.gap end)

    return results
end

---------------------------------------------------------------------------
-- 6.  Weekly Insight
---------------------------------------------------------------------------
function SS:GetWeeklyInsight()
    if not ns.Statistics then
        return "Donnees insuffisantes pour generer un bilan hebdomadaire."
    end

    local trends = safeCall(ns.Statistics.GetTrends, ns.Statistics)
    if not trends then
        return "Impossible de calculer les tendances cette semaine."
    end

    -- Build change strings
    local parts = {}

    local function fmtChange(label, pct)
        if pct > 0 then
            return string.format("+%.0f%% %s", pct, label)
        elseif pct < 0 then
            return string.format("%.0f%% %s", pct, label)
        else
            return string.format("= %s", label)
        end
    end

    table.insert(parts, fmtChange("contactes", trends.contactedChange or 0))
    table.insert(parts, fmtChange("invites", trends.invitedChange or 0))
    table.insert(parts, fmtChange("recrues", trends.joinedChange or 0))

    local summary = "Cette semaine: " .. table.concat(parts, ", ") .. "."

    -- Append best template recommendation
    local bestTpl = self:GetBestTemplate()
    if bestTpl and bestTpl.templateId and bestTpl.successRate > 0 then
        local tplName = bestTpl.templateId
        if ns.Templates_All then
            local all = ns.Templates_All()
            if all and all[bestTpl.templateId] then
                tplName = all[bestTpl.templateId].name or bestTpl.templateId
            end
        end
        summary = summary .. string.format(
            " Essaie le template '%s' qui a le meilleur taux (%.0f%%).",
            tplName, bestTpl.successRate
        )
    end

    return summary
end

---------------------------------------------------------------------------
-- 7.  Get All Suggestions  (unified, sorted by priority)
---------------------------------------------------------------------------
function SS:GetAllSuggestions()
    local suggestions = {}

    -- Helper to safely add a suggestion
    local function add(sug)
        if sug then
            table.insert(suggestions, sug)
        end
    end

    -- --- Hot Leads (priority 5) ----------------------------------------
    local hotLeads = self:GetHotLeads()
    if #hotLeads > 0 then
        local top = hotLeads[1]
        local contactName = (top.contact and top.contact.name) or top.key
        add({
            type = "hot_lead",
            priority = 5,
            title = "Lead prioritaire disponible",
            description = string.format(
                "%s a un score de %d et attend dans la file. Contacte-le rapidement !",
                contactName, top.score
            ),
            action = { type = "contact", value = top.key },
        })
        -- If there are more hot leads, add a grouped suggestion
        if #hotLeads > 1 then
            add({
                type = "hot_lead",
                priority = 4,
                title = string.format("%d autres leads chauds", #hotLeads - 1),
                description = string.format(
                    "%d contacts avec un score >= 70 sont dans la file d'attente.",
                    #hotLeads - 1
                ),
            })
        end
    end

    -- --- Re-contact stale contacts (priority 4) -----------------------
    local recontacts = self:GetContactsToRecontact()
    if #recontacts > 0 then
        local top = recontacts[1]
        local contactName = (top.contact and top.contact.name) or top.key
        add({
            type = "recontact",
            priority = 4,
            title = "Recontacter un prospect",
            description = string.format(
                "%s a ete contacte il y a %d jours (score %d). Un rappel pourrait convertir.",
                contactName, top.daysSince, top.score
            ),
            action = { type = "contact", value = top.key },
        })
        if #recontacts > 1 then
            add({
                type = "recontact",
                priority = 3,
                title = string.format("%d autres a recontacter", #recontacts - 1),
                description = string.format(
                    "%d contacts meritent un second message (contactes il y a 3+ jours, score > 40).",
                    #recontacts - 1
                ),
            })
        end
    end

    -- --- Best time (priority 3) ----------------------------------------
    local bestTime = self:GetBestTimeToRecruit()
    if bestTime then
        local currentHour = tonumber(date("%H")) or 0
        local prio = (currentHour == bestTime.hour) and 4 or 3
        add({
            type = "time",
            priority = prio,
            title = string.format("Heure optimale : %dh", bestTime.hour),
            description = bestTime.reason,
        })
    end

    -- --- Best template (priority 3) ------------------------------------
    local bestTpl = self:GetBestTemplate()
    if bestTpl and bestTpl.successRate > 0 then
        add({
            type = "template",
            priority = 3,
            title = "Meilleur template",
            description = bestTpl.reason,
            action = { type = "use_template", value = bestTpl.templateId },
        })
    end

    -- --- Class gaps (priority 2) ---------------------------------------
    local gaps = self:GetClassGaps()
    if #gaps > 0 then
        local top = gaps[1]
        add({
            type = "class_gap",
            priority = 2,
            title = string.format("Classe manquante : %s", top.class),
            description = top.suggestion,
        })
        if #gaps > 1 then
            local names = {}
            for i = 2, math.min(4, #gaps) do
                table.insert(names, gaps[i].class)
            end
            add({
                type = "class_gap",
                priority = 1,
                title = "Autres classes sous-representees",
                description = "Aussi a cibler : " .. table.concat(names, ", ") .. ".",
            })
        end
    end

    -- --- Weekly insight (priority 2) -----------------------------------
    local insight = self:GetWeeklyInsight()
    if insight and insight ~= "" then
        add({
            type = "insight",
            priority = 2,
            title = "Bilan hebdomadaire",
            description = insight,
        })
    end

    -- Sort by priority descending, then by type alphabetically for stability
    table.sort(suggestions, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        return a.type < b.type
    end)

    -- Cap at 8 suggestions
    local capped = {}
    for i = 1, math.min(8, #suggestions) do
        capped[i] = suggestions[i]
    end

    return capped
end

---------------------------------------------------------------------------
-- 8.  Suggestion Count  (for badge display)
---------------------------------------------------------------------------
function SS:GetSuggestionCount()
    local ok, suggestions = pcall(self.GetAllSuggestions, self)
    if ok and suggestions then
        return #suggestions
    end
    return 0
end
