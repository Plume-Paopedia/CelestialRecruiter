local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  AI Conversation Engine
-- Pattern matching (instant) + AI response loading (deferred via Python)
-- ═══════════════════════════════════════════════════════════════════

ns.AIConversation = ns.AIConversation or {}
local AIC = ns.AIConversation

---------------------------------------------------------------------------
-- Pattern matching dictionaries (French + English)
---------------------------------------------------------------------------
local PATTERNS = {
    positive = {
        "oui", "ok", "d'accord", "interesse", "invite", "!invite",
        "yes", "sure", "yeah", "yep", "go", "je veux", "dispo",
        "j'arrive", "j'accepte", "volontiers", "avec plaisir",
    },
    negative = {
        "non", "non merci", "pas interesse", "stop", "no", "nope",
        "deja guilde", "j'ai une guilde", "leave me alone",
        "pas envie", "arrete", "spam", "signale",
    },
    question = {
        "quel", "quoi", "quand", "comment", "combien", "c'est quoi",
        "what", "when", "how", "which", "pourquoi", "why", "where",
        "votre guilde", "ta guilde", "quel contenu", "quel ilvl",
        "raid", "mythique", "pvp", "horaire", "discord",
    },
    afk = {
        "afk", "occupe", "busy", "plus tard", "later", "pas la",
        "en raid", "en donjons", "en bg", "en arena",
    },
}

-- Pre-built FAQ responses (used when no AI response available)
local FAQ_RESPONSES = {
    guilde   = "On est une guilde ambiance chill avec progression stable. Viens sur notre Discord pour en savoir plus !",
    contenu  = "On fait du raid, du M+ et du PvP selon les envies. L'important c'est de s'amuser ensemble !",
    horaire  = "On raid en general 2-3 soirs par semaine, les horaires sont flexibles. Rejoins le Discord pour les details !",
    discord  = "Rejoins notre Discord pour discuter avec la team et voir nos activites !",
    niveau   = "On accepte tous les niveaux, l'important c'est la motivation !",
}

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
function AIC:Init()
    if not ns.db or not ns.db.global then return end
    if not ns.db.global.aiPendingReplies then
        ns.db.global.aiPendingReplies = {}
    end
end

---------------------------------------------------------------------------
-- Classify an incoming message
-- Returns: category ("positive", "negative", "question", "afk", "unknown"), matched keyword
---------------------------------------------------------------------------
function AIC:Classify(msg)
    if not msg or msg == "" then return "unknown", nil end
    local lower = (ns.Util_Lower or string.lower)(msg)

    -- Check each category in priority order
    for _, category in ipairs({"positive", "negative", "afk", "question"}) do
        for _, pattern in ipairs(PATTERNS[category]) do
            if lower:find(pattern, 1, true) then
                return category, pattern
            end
        end
    end

    return "unknown", nil
end

---------------------------------------------------------------------------
-- Handle incoming whisper during Mode Nuit
-- Returns: true if handled, false if needs AI
---------------------------------------------------------------------------
function AIC:HandleIncoming(key, msg)
    if not key or not msg then return false end

    local category, matched = self:Classify(msg)
    ns.DB_Log("AI", string.format("Conversation %s: [%s] match=%s - %s",
        key, category, tostring(matched), msg:sub(1, 60)))

    if category == "positive" then
        -- Player is interested -> send guild invite immediately
        local invOk = false
        local c = ns.DB_GetContact(key)
        if not c or not c.guild or c.guild == "" then
            invOk = ns.Queue_Invite(key)
        end

        local response = invOk
            and "Super, invite envoy\195\169e ! Bienvenue parmi nous !"
            or "G\195\169nial ! Rejoins notre Discord et on t'invite d\195\168s que possible !"
        self:SendResponse(key, response)
        ns.DB_UpsertContact(key, { status = "invited" })
        return true

    elseif category == "negative" then
        -- Player not interested -> polite goodbye, mark ignored
        self:SendResponse(key, "Pas de souci, bonne continuation et bon jeu !")
        ns.DB_UpsertContact(key, {
            status = "ignored",
            ignoredUntil = ns.Util_Now() + 86400 * 30,  -- ignore 30 days
        })
        return true

    elseif category == "afk" then
        -- Player is busy -> postpone 1 hour
        ns.DB_UpsertContact(key, {
            ignoredUntil = ns.Util_Now() + 3600,
        })
        ns.DB_Log("AI", "Contact " .. key .. " reporte (AFK/occupe)")
        return true

    elseif category == "question" then
        -- Try FAQ response first
        local faqResponse = self:FindFAQResponse(msg)
        if faqResponse then
            self:SendResponse(key, faqResponse)
            return true
        end

        -- Queue for AI response (Python will handle at next reload)
        self:QueueForAI(key, msg)
        return false

    else
        -- Unknown -> queue for AI
        self:QueueForAI(key, msg)
        return false
    end
end

---------------------------------------------------------------------------
-- Try to match a FAQ response
---------------------------------------------------------------------------
function AIC:FindFAQResponse(msg)
    local lower = (ns.Util_Lower or string.lower)(msg)

    if lower:find("guilde") or lower:find("guild") then
        return FAQ_RESPONSES.guilde
    end
    if lower:find("contenu") or lower:find("raid") or lower:find("mythique") or lower:find("pvp") then
        return FAQ_RESPONSES.contenu
    end
    if lower:find("horaire") or lower:find("quand") or lower:find("heure") or lower:find("soir") then
        return FAQ_RESPONSES.horaire
    end
    if lower:find("discord") then
        local disc = ns.db and ns.db.profile and ns.db.profile.discord or ""
        if disc ~= "" then
            return "Voici notre Discord : " .. disc
        end
        return FAQ_RESPONSES.discord
    end
    if lower:find("niveau") or lower:find("ilvl") or lower:find("level") then
        return FAQ_RESPONSES.niveau
    end

    return nil
end

---------------------------------------------------------------------------
-- Queue a message for AI processing (Python companion)
---------------------------------------------------------------------------
function AIC:QueueForAI(key, msg)
    if not ns.db or not ns.db.global then return end
    if not ns.db.global.aiPendingReplies then
        ns.db.global.aiPendingReplies = {}
    end

    -- Get conversation context (last 5 messages)
    local context = ""
    local messages = ns.DB_GetMessages and ns.DB_GetMessages(key) or {}
    local start = math.max(1, #messages - 4)
    for i = start, #messages do
        local m = messages[i]
        if m then
            local dir = m.d == "out" and "Moi" or key
            context = context .. dir .. ": " .. (m.m or "") .. "\n"
        end
    end

    ns.db.global.aiPendingReplies[key] = {
        msg = msg,
        timestamp = ns.Util_Now(),
        context = context,
    }

    ns.DB_Log("AI", "Question en attente AI: " .. key .. " -> " .. msg:sub(1, 60))
end

---------------------------------------------------------------------------
-- Send pending AI responses (called after ReloadUI loads new data)
---------------------------------------------------------------------------
function AIC:SendPendingResponses()
    local aiData = CelestialRecruiterAI
    if not aiData or not aiData.responses then return 0 end

    local sent = 0
    for key, response in pairs(aiData.responses) do
        if response and response ~= "" then
            local c = ns.DB_GetContact(key)
            if c and c.status ~= "ignored" then
                self:SendResponse(key, response)
                sent = sent + 1
                ns.DB_Log("AI", "Reponse AI envoyee a " .. key)
            end
        end
    end

    -- Clear processed responses
    aiData.responses = {}

    -- Clear pending replies that were answered
    if ns.db and ns.db.global and ns.db.global.aiPendingReplies then
        for key in pairs(aiData.responses or {}) do
            ns.db.global.aiPendingReplies[key] = nil
        end
    end

    return sent
end

---------------------------------------------------------------------------
-- Send a whisper response to a player
---------------------------------------------------------------------------
function AIC:SendResponse(key, msg)
    if not key or not msg or msg == "" then return false end

    -- Truncate to 240 chars (WoW whisper limit is ~255)
    if #msg > 240 then
        msg = msg:sub(1, 237) .. "..."
    end

    local ok = pcall(SendChatMessage, msg, "WHISPER", nil, key)
    if ok then
        ns.AntiSpam_MarkWhisper(key)
        ns.DB_AddMessage(key, "out", msg)
        ns.DB_Log("AI", "Reponse envoyee a " .. key .. ": " .. msg:sub(1, 60))

        -- Discord notification
        if ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
            ns.DiscordQueue:QueueEvent("ai_conversation", {
                title = "R\195\169ponse AI envoy\195\169e",
                description = string.format("**%s** -> %s", key, msg:sub(1, 100)),
            })
        end
    end
    return ok
end

---------------------------------------------------------------------------
-- Get AI-generated message for a contact (from pre-generated pool)
---------------------------------------------------------------------------
function AIC:GetAIMessage(key)
    local aiData = CelestialRecruiterAI
    if not aiData or not aiData.messages then return nil end
    return aiData.messages[key]
end

---------------------------------------------------------------------------
-- Get AI targeting priority list
---------------------------------------------------------------------------
function AIC:GetPriorityList()
    local aiData = CelestialRecruiterAI
    if not aiData or not aiData.targeting then return nil end
    return aiData.targeting.priority
end
