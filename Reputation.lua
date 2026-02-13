local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Reputation & Scoring System
-- Intelligent contact scoring for optimized recruitment
-- ═══════════════════════════════════════════════════════════════════

ns.Reputation = ns.Reputation or {}
local Rep = ns.Reputation

---------------------------------------------------------------------------
-- Scoring Algorithm
---------------------------------------------------------------------------
function Rep:CalculateScore(contact, scanData)
    if not contact then return 0 end

    local score = 50  -- Base score

    -- Recency bonus (recently seen = more likely active)
    local now = time()
    local lastSeen = contact.lastSeen or contact.firstSeen or 0
    local daysSinceLastSeen = (now - lastSeen) / 86400

    if daysSinceLastSeen <= 1 then
        score = score + 20  -- Seen today
    elseif daysSinceLastSeen <= 7 then
        score = score + 10  -- Seen this week
    elseif daysSinceLastSeen <= 30 then
        score = score + 5   -- Seen this month
    else
        score = score - 10  -- Not seen recently
    end

    -- Opt-in bonus (explicitly wants invite)
    if contact.optedIn then
        score = score + 30
    end

    -- Level bonus (higher level = more experienced)
    local level = contact.level or (scanData and scanData.level) or 0
    if level >= 70 then
        score = score + 15  -- Max level
    elseif level >= 60 then
        score = score + 10
    elseif level >= 40 then
        score = score + 5
    elseif level < 20 then
        score = score - 5   -- Very low level
    end

    -- Response bonus (if they replied to us)
    if contact.lastWhisperIn and contact.lastWhisperOut then
        if contact.lastWhisperIn > contact.lastWhisperOut then
            score = score + 25  -- They messaged us after we messaged them
        end
    end

    -- Source bonus
    if contact.source == "inbox" then
        score = score + 20  -- They contacted us first
    elseif contact.source == "scanner" then
        score = score + 5   -- We found them
    end

    -- Cross-realm penalty (harder to recruit)
    if contact.crossRealm then
        score = score - 10
    end

    -- Already contacted penalty
    if contact.status == "contacted" then
        score = score - 5   -- Already tried once
    elseif contact.status == "invited" then
        score = score - 15  -- Already invited, didn't join yet
    elseif contact.status == "ignored" then
        score = score - 50  -- Explicitly ignored
    elseif contact.status == "joined" then
        score = score + 100 -- Already recruited!
    end

    -- Tags bonus (custom priority)
    if contact.tags then
        for _, tag in ipairs(contact.tags) do
            local tagLower = tag:lower()
            if tagLower:find("priority") or tagLower:find("hot") then
                score = score + 15
            elseif tagLower:find("tank") or tagLower:find("heal") then
                score = score + 10  -- Needed roles
            elseif tagLower:find("friend") then
                score = score + 20
            elseif tagLower:find("spam") or tagLower:find("bot") then
                score = score - 30
            end
        end
    end

    -- Clamp score to 0-100
    return math.max(0, math.min(100, score))
end

---------------------------------------------------------------------------
-- Score Classification
---------------------------------------------------------------------------
function Rep:GetScoreClass(score)
    if score >= 80 then
        return "hot", "Prioritaire", {1.0, 0.4, 0.0}  -- Orange/Red
    elseif score >= 60 then
        return "promising", "Prometteur", {0.2, 0.88, 0.48}  -- Green
    elseif score >= 40 then
        return "neutral", "Neutre", {0.55, 0.58, 0.66}  -- Gray
    elseif score >= 20 then
        return "cold", "Froid", {0.4, 0.6, 0.9}  -- Blue
    else
        return "ignore", "A ignorer", {1.0, 0.4, 0.4}  -- Red
    end
end

---------------------------------------------------------------------------
-- Batch Scoring
---------------------------------------------------------------------------
function Rep:ScoreContacts(contacts, scanDataMap)
    local scored = {}

    for key, contact in pairs(contacts) do
        local scanData = scanDataMap and scanDataMap[key]
        local score = self:CalculateScore(contact, scanData)

        table.insert(scored, {
            key = key,
            contact = contact,
            score = score,
            scoreClass = self:GetScoreClass(score)
        })
    end

    -- Sort by score descending
    table.sort(scored, function(a, b)
        return a.score > b.score
    end)

    return scored
end

---------------------------------------------------------------------------
-- Get Priority Queue (sorted by score)
---------------------------------------------------------------------------
function Rep:GetPriorityQueue()
    if not ns.db or not ns.db.global then return {} end

    local queueKeys = ns.DB_QueueList and ns.DB_QueueList() or {}
    local contacts = {}

    -- Gather contacts
    for _, key in ipairs(queueKeys) do
        local contact = ns.DB_GetContact and ns.DB_GetContact(key)
        if contact then
            contacts[key] = contact
        end
    end

    -- Get scanner data if available
    local scanDataMap = nil
    if ns.Scanner and ns.Scanner.results then
        scanDataMap = ns.Scanner.results
    end

    -- Score and sort
    return self:ScoreContacts(contacts, scanDataMap)
end

---------------------------------------------------------------------------
-- Reputation Badge (for UI)
---------------------------------------------------------------------------
function Rep:GetBadge(score)
    local class, label, color = self:GetScoreClass(score)

    return string.format(
        "|cff%02x%02x%02x%d|r",
        color[1] * 255,
        color[2] * 255,
        color[3] * 255,
        score
    )
end

---------------------------------------------------------------------------
-- Predicted Conversion Probability
---------------------------------------------------------------------------
function Rep:PredictConversion(contact, scanData)
    local score = self:CalculateScore(contact, scanData)

    -- Simple linear model: score 0-100 → probability 0-1
    -- With some adjustments based on stats

    local baseProbability = score / 100

    -- Adjust based on historical data
    if ns.Statistics and ns.Statistics.GetConversionRates then
        local rates = ns.Statistics:GetConversionRates()
        if rates and rates.contactToJoin then
            -- Scale base probability by historical success rate
            local historicalRate = rates.contactToJoin / 100
            baseProbability = baseProbability * (0.5 + historicalRate * 0.5)
        end
    end

    -- Clamp to 0-1
    return math.max(0, math.min(1, baseProbability))
end

---------------------------------------------------------------------------
-- Feedback System (track actual outcomes to improve scoring)
---------------------------------------------------------------------------
function Rep:RecordOutcome(key, outcome)
    -- outcome: "accepted", "declined", "no_response", "joined"

    if not ns.db or not ns.db.global then return end

    if not ns.db.global.reputationFeedback then
        ns.db.global.reputationFeedback = {}
    end

    if not ns.db.global.reputationFeedback[key] then
        ns.db.global.reputationFeedback[key] = {}
    end

    table.insert(ns.db.global.reputationFeedback[key], {
        timestamp = time(),
        outcome = outcome
    })

    -- Keep only last 10 outcomes per contact
    local feedback = ns.db.global.reputationFeedback[key]
    if #feedback > 10 then
        table.remove(feedback, 1)
    end
end

function Rep:GetContactFeedback(key)
    if not ns.db or not ns.db.global or not ns.db.global.reputationFeedback then
        return {}
    end

    return ns.db.global.reputationFeedback[key] or {}
end

---------------------------------------------------------------------------
-- Auto-Tag Based on Score
---------------------------------------------------------------------------
function Rep:AutoTagByScore(key, score)
    local class, label = self:GetScoreClass(score)

    -- Remove old score tags
    local oldTags = {"hot", "promising", "neutral", "cold", "ignore"}
    for _, tag in ipairs(oldTags) do
        if ns.DB_HasTag and ns.DB_HasTag(key, tag) then
            ns.DB_RemoveTag(key, tag)
        end
    end

    -- Add new score tag
    if class ~= "neutral" then  -- Don't tag neutral
        ns.DB_AddTag(key, class)
    end
end

---------------------------------------------------------------------------
-- Batch Auto-Tag All Contacts
---------------------------------------------------------------------------
function Rep:AutoTagAll()
    if not ns.db or not ns.db.global or not ns.db.global.contacts then
        return
    end

    local count = 0
    for key, contact in pairs(ns.db.global.contacts) do
        local score = self:CalculateScore(contact, nil)
        self:AutoTagByScore(key, score)
        count = count + 1
    end

    if ns.Notifications_Success then
        ns.Notifications_Success("Auto-Tag", string.format("%d contacts evalues et etiquetes", count))
    end
    if ns.UI_Refresh then
        ns.UI_Refresh()
    end
end
