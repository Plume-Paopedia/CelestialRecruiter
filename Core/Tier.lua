local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Tier Gating System
-- Central module: all other modules query ns.Tier for access checks
-- ═══════════════════════════════════════════════════════════════════

ns.Tier = {}
local T = ns.Tier

-- ───────────────────────────── Tier Levels ─────────────────────────────
local TIER_LEVELS = {
    free      = 0,
    recruteur = 1,
    pro       = 2,
    lifetime  = 2, -- same power as Pro, never expires
}

-- ───────────────────────────── Feature Limits ─────────────────────────────
-- { minTier, limitFree, limitRecruteur, limitPro }
-- For boolean features: false = locked, true = unlocked
-- For numeric features: the cap value (99999 = unlimited)
local LIMITS = {
    -- Scanner
    who_delay_min         = { "free",      10,     6,     3 },
    scan_query_cap        = { "free",      30, 99999, 99999 },
    auto_scan             = { "recruteur", false,  true,  true },
    auto_scan_continuous  = { "pro",       false, false,  true },

    -- Queue & Contacts
    contacts_max          = { "free",     100,   500, 99999 },
    queue_max             = { "free",      25,   100, 99999 },
    log_limit             = { "free",     100,   300,   500 },

    -- Templates
    custom_templates_max  = { "free",       1,     3, 99999 },
    template_vars_all     = { "recruteur", false, true,  true },

    -- Auto-Recruiter
    auto_recruiter        = { "pro",       false, false, true },

    -- Statistics
    stats_history_days    = { "free",       7,    30,    90 },
    stats_advanced        = { "recruteur", false, true,  true },

    -- A/B Testing
    ab_testing            = { "pro",       false, false, true },

    -- Campaigns
    campaigns_active_max  = { "free",       0,     1,     3 },
    campaigns_scheduling  = { "pro",       false, false, true },

    -- Discord
    discord_webhook       = { "recruteur", false, true,  true },
    discord_all_events    = { "pro",       false, false, true },

    -- Filters
    filter_dimensions     = { "free",       4,     8,    10 },
    filter_presets_max    = { "free",       0,     2, 99999 },

    -- Bulk Operations
    bulk_tag_status       = { "recruteur", false, true,  true },
    bulk_whisper_invite   = { "pro",       false, false, true },

    -- Themes
    themes_preset_max     = { "free",       2,     6,     6 },
    theme_custom          = { "pro",       false, false, true },

    -- Goals & Achievements
    achievements_full     = { "recruteur", false, true,  true },

    -- Leaderboard
    leaderboard_full      = { "recruteur", false, true,  true },

    -- Smart Suggestions
    suggestions_max       = { "free",       2,     5,     8 },

    -- Reputation
    reputation_full       = { "recruteur", false, true,  true },

    -- Welcome DM
    welcome_dm            = { "recruteur", false, true,  true },

    -- Import/Export
    auto_backup           = { "recruteur", false, true,  true },
    web_export            = { "recruteur", false, true,  true },
}

-- ───────────────────────────── License Key Crypto ─────────────────────────────
local SALT = "CelestialRecruiter2026PlumePao"

local function djb2(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + str:byte(i)) % 4294967296
    end
    return string.format("%08x", hash)
end

local function computeChecksum(tierCode, dateStr)
    return djb2(tierCode .. dateStr .. SALT)
end

-- Map short tier codes in license keys to internal tier names
local TIER_CODES = {
    REC  = "recruteur",
    PRO  = "pro",
    LIFE = "lifetime",
}

-- ───────────────────────────── Core State ─────────────────────────────
T.currentTier = "free"

-- ───────────────────────────── Init ─────────────────────────────
function T:Init()
    local license = ns.db and ns.db.profile and ns.db.profile.license
    if license and license.tier then
        self.currentTier = self:_Validate(license)
    else
        self.currentTier = "free"
    end

    -- Apply log limit based on tier
    if ns.db and ns.db.profile then
        ns.db.profile.logLimit = self:GetLimit("log_limit")
    end
end

-- ───────────────────────────── Validation ─────────────────────────────
function T:_Validate(license)
    if not license or not license.tier or not license.expiry then
        return "free"
    end

    -- Check expiry (YYYYMMDD format as number)
    local now = tonumber(os.date("%Y%m%d"))
    if license.expiry < now then
        -- Expired
        if ns.Notifications_Info then
            ns.Notifications_Info("Licence expir\195\169e",
                "Votre licence " .. (license.tier or "") .. " a expir\195\169. Renouvelez sur Patreon.")
        end
        return "free"
    end

    -- Verify the tier is valid
    if TIER_LEVELS[license.tier] then
        return license.tier
    end

    return "free"
end

-- ───────────────────────────── Public API ─────────────────────────────

function T:GetTier()
    return self.currentTier or "free"
end

function T:GetTierLevel()
    return TIER_LEVELS[self.currentTier] or 0
end

function T:HasAccess(requiredTier)
    local current = TIER_LEVELS[self.currentTier] or 0
    local required = TIER_LEVELS[requiredTier] or 0
    return current >= required
end

function T:GetLimit(featureId)
    local def = LIMITS[featureId]
    if not def then return 99999 end

    local level = self:GetTierLevel()
    -- def = { minTier, limitFree, limitRecruteur, limitPro }
    if level >= 2 then
        return def[4]
    elseif level >= 1 then
        return def[3]
    else
        return def[2]
    end
end

function T:CanUse(featureId)
    local val = self:GetLimit(featureId)
    if type(val) == "boolean" then
        return val
    end
    -- Numeric limits: usable if > 0
    return val > 0
end

-- ───────────────────────────── Upgrade Prompts ─────────────────────────────

local TIER_NAMES = {
    free      = "Le Scout",
    recruteur = "Le Recruteur (3\226\130\172/mois)",
    pro       = "L'\195\137lite (7\226\130\172/mois)",
    lifetime  = "Le L\195\169gendaire (20\226\130\172)",
}

local UPGRADE_HINTS = {
    auto_scan            = "L'Auto-Scan d\195\169couvre des joueurs en arri\195\168re-plan pendant que vous jouez.",
    auto_scan_continuous = "Auto-scan arr\195\170t\195\169 apr\195\168s 1 cycle. Cycles illimit\195\169s en continu.",
    auto_recruiter       = "Recrutement 100% automatique. Z\195\169ro clic, z\195\169ro effort.",
    contacts_max         = "Base pleine ! Plus de contacts = plus de recrues potentielles.",
    queue_max            = "File d'attente pleine ! \195\137largissez-la pour ne perdre aucun prospect.",
    custom_templates_max = "Cr\195\169ez plus de mod\195\168les personnalis\195\169s pour chaque situation.",
    template_vars_all    = "D\195\169bloquez {discord}, {raidDays}, {goal} pour des messages plus percutants.",
    stats_advanced       = "D\195\169couvrez vos meilleures heures et templates les plus efficaces.",
    ab_testing           = "Testez vos templates automatiquement et trouvez le plus performant.",
    campaigns_active_max = "Limite de campagnes atteinte. G\195\169rez-en plus simultan\195\169ment.",
    campaigns_scheduling = "Planifiez vos campagnes par jour et heure pour cibler les pics d'activit\195\169.",
    discord_webhook      = "Notifications Discord en temps r\195\169el quand un joueur rejoint ou \195\169crit.",
    discord_all_events   = "Tous les 30+ types d'\195\169v\195\169nements Discord pour un suivi complet.",
    bulk_tag_status      = "Op\195\169rations en masse : taguez et changez le statut de dizaines de contacts.",
    bulk_whisper_invite  = "Whisper et invite en masse. Gagnez des heures chaque semaine.",
    themes_preset_max    = "D\195\169bloquez les 6 th\195\168mes visuels pour personnaliser votre interface.",
    theme_custom         = "Cr\195\169ez votre propre th\195\168me avec le cr\195\169ateur de couleurs.",
    achievements_full    = "D\195\169bloquez les 29 succ\195\168s et toutes les cat\195\169gories.",
    leaderboard_full     = "Classement complet sans plafond et participation guilde.",
    suggestions_max      = "Toutes les suggestions intelligentes pour optimiser votre recrutement.",
    reputation_full      = "Score de r\195\169putation d\195\169taill\195\169 (0-100) avec analyse des facteurs.",
    welcome_dm           = "Message de bienvenue automatique aux nouvelles recrues.",
    auto_backup          = "Sauvegarde automatique quotidienne de vos donn\195\169es.",
    web_export           = "Exportez vos donn\195\169es vers le dashboard web.",
    filter_presets_max   = "Sauvegardez vos combinaisons de filtres pr\195\169f\195\169r\195\169es.",
    scan_query_cap       = "Scan limit\195\169 (free). Le scan complet couvre tout le serveur.",
}

-- Throttle: don't spam the same upgrade prompt
local lastPromptTime = {}
local PROMPT_COOLDOWN = 300 -- 5 minutes between same prompts

function T:ShowUpgrade(featureId)
    local now = GetTime and GetTime() or 0
    if lastPromptTime[featureId] and (now - lastPromptTime[featureId]) < PROMPT_COOLDOWN then
        return
    end
    lastPromptTime[featureId] = now

    local def = LIMITS[featureId]
    if not def then return end

    local requiredTier = def[1]
    local tierName = TIER_NAMES[requiredTier] or requiredTier
    local hint = UPGRADE_HINTS[featureId] or ""

    if ns.Notifications_Info then
        ns.Notifications_Info("Fonctionnalit\195\169 r\195\169serv\195\169e",
            hint .. " Disponible avec " .. tierName .. ".")
    else
        ns.Util_Print("|cffC9AA71[Tier]|r " .. hint .. " Disponible avec " .. tierName .. ".")
    end
end

-- ───────────────────────────── License Activation ─────────────────────────────

function T:Activate(keyStr)
    if not keyStr or keyStr == "" then
        return false, "Cl\195\169 vide. Format: CR-TIER-DATE-CHECKSUM"
    end

    -- Parse: CR-{TIER}-{YYYYMMDD}-{8hex}
    local tierCode, dateStr, checksum = keyStr:match("^CR%-(%u+)%-(%d%d%d%d%d%d%d%d)%-(%x%x%x%x%x%x%x%x)$")
    if not tierCode then
        return false, "Format invalide. Attendu: CR-TIER-YYYYMMDD-CHECKSUM"
    end

    -- Validate tier code
    local tier = TIER_CODES[tierCode]
    if not tier then
        return false, "Tier inconnu: " .. tierCode
    end

    -- Validate checksum
    local expected = computeChecksum(tierCode, dateStr)
    if checksum ~= expected then
        return false, "Cl\195\169 invalide (checksum incorrect)."
    end

    -- Store license
    local expiry = tonumber(dateStr)
    ns.db.profile.license = {
        key = keyStr,
        tier = tier,
        expiry = expiry,
        activatedAt = time(),
    }

    self.currentTier = tier

    -- Apply log limit
    ns.db.profile.logLimit = self:GetLimit("log_limit")

    -- Celebration!
    local tierName = TIER_NAMES[tier] or tier
    if ns.Notifications_Celebrate then
        ns.Notifications_Celebrate("Licence activ\195\169e !", tierName .. " d\195\169bloqu\195\169. Merci pour votre soutien !")
    else
        ns.Util_Print("|cff00ff00Licence activ\195\169e !|r " .. tierName .. " d\195\169bloqu\195\169. Merci !")
    end

    -- Play effects
    if ns.ParticleSystem and ns.ParticleSystem.PlayRecruitJoinedEffect and ns.UI and ns.UI.mainFrame then
        ns.ParticleSystem:PlayRecruitJoinedEffect(ns.UI.mainFrame)
    end

    -- Refresh UI
    if ns.UI_Refresh then
        ns.UI_Refresh()
    end

    return true
end

-- ───────────────────────────── Utility: Generate Key (for dev/testing) ─────────────────────────────

function T:GenerateKey(tierCode, dateStr)
    local checksum = computeChecksum(tierCode, dateStr)
    return "CR-" .. tierCode .. "-" .. dateStr .. "-" .. checksum
end

-- ───────────────────────────── Contact Count Helper ─────────────────────────────

function T:GetContactCount()
    if not ns.db or not ns.db.global or not ns.db.global.contacts then return 0 end
    local n = 0
    for _ in pairs(ns.db.global.contacts) do n = n + 1 end
    return n
end

function T:CanAddContact()
    local max = self:GetLimit("contacts_max")
    return self:GetContactCount() < max
end

function T:CanAddToQueue()
    local max = self:GetLimit("queue_max")
    return ns.DB_QueueCount() < max
end
