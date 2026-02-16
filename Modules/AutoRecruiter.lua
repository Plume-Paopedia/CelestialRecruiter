local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Intelligent Auto-Recruitment System
-- Automated recruiting with smart rules and safety limits
-- ═══════════════════════════════════════════════════════════════════

ns.AutoRecruiter = ns.AutoRecruiter or {}
local AR = ns.AutoRecruiter

-- Auto-recruiter state
AR.active = false
AR.paused = false
AR.currentIndex = 1
AR.ticker = nil
AR.stats = {
    startedAt = 0,
    processed = 0,
    contacted = 0,
    invited = 0,
    skipped = 0,
    errors = 0,
}

-- Default rules
AR.rules = {
    enabled = false,
    mode = "recruit",        -- "whisper", "invite", "recruit" (both)
    template = "default",
    delayBetweenActions = 15, -- seconds between actions
    maxPerSession = 50,
    levelMin = 10,
    levelMax = 80,
    classes = {},            -- Empty = all classes
    priorityClasses = {},    -- These classes get processed first
    excludeCrossRealm = false,
    requireOptIn = false,
    timeRestrictions = {     -- Only recruit during certain hours
        enabled = false,
        startHour = 18,      -- 18:00
        endHour = 23,        -- 23:00
    },
    dayLimits = {           -- Daily limits
        enabled = true,
        maxContactsPerDay = 100,
        maxInvitesPerDay = 50,
    },
    skipConditions = {
        skipGuilded = true,
        skipContacted = true,
        skipInvited = true,
    },
}

function AR:Init()
    -- Load saved rules
    if ns.db and ns.db.profile and ns.db.profile.autoRecruiterRules then
        for k, v in pairs(ns.db.profile.autoRecruiterRules) do
            if self.rules[k] ~= nil then
                self.rules[k] = v
            end
        end
    end
end

function AR:SaveRules()
    if ns.db and ns.db.profile then
        ns.db.profile.autoRecruiterRules = self.rules
    end
end

---------------------------------------------------------------------------
-- Rule Checking
---------------------------------------------------------------------------

function AR:CheckTimeRestrictions()
    if not self.rules.timeRestrictions.enabled then
        return true
    end

    local hour = tonumber(date("%H"))
    local start = self.rules.timeRestrictions.startHour
    local endH = self.rules.timeRestrictions.endHour

    if start <= endH then
        -- Normal range (e.g., 18:00 to 23:00)
        return hour >= start and hour <= endH
    else
        -- Wraps midnight (e.g., 22:00 to 02:00)
        return hour >= start or hour <= endH
    end
end

function AR:GetDailyLimits()
    if not self.rules.dayLimits.enabled then
        return {
            contactsRemaining = 999999,
            invitesRemaining = 999999,
        }
    end

    local today = date("%Y-%m-%d")
    if not ns.db.global.autoRecruiterDaily then
        ns.db.global.autoRecruiterDaily = {}
    end

    local daily = ns.db.global.autoRecruiterDaily
    if not daily[today] then
        daily[today] = {
            contacted = 0,
            invited = 0,
        }
    end

    -- Cleanup old days (collect-then-delete for safe iteration)
    local toRemove = {}
    for day in pairs(daily) do
        if day ~= today then
            toRemove[#toRemove + 1] = day
        end
    end
    for _, day in ipairs(toRemove) do
        daily[day] = nil
    end

    local contactsRemaining = self.rules.dayLimits.maxContactsPerDay - daily[today].contacted
    local invitesRemaining = self.rules.dayLimits.maxInvitesPerDay - daily[today].invited

    return {
        contactsRemaining = math.max(0, contactsRemaining),
        invitesRemaining = math.max(0, invitesRemaining),
        today = daily[today],
    }
end

function AR:IncrementDailyCount(kind)
    local today = date("%Y-%m-%d")
    if not ns.db.global.autoRecruiterDaily then
        ns.db.global.autoRecruiterDaily = {}
    end
    if not ns.db.global.autoRecruiterDaily[today] then
        ns.db.global.autoRecruiterDaily[today] = {contacted = 0, invited = 0}
    end

    if kind == "contacted" then
        ns.db.global.autoRecruiterDaily[today].contacted = ns.db.global.autoRecruiterDaily[today].contacted + 1
    elseif kind == "invited" then
        ns.db.global.autoRecruiterDaily[today].invited = ns.db.global.autoRecruiterDaily[today].invited + 1
    end
end

function AR:CanProcessContact(key, contact)
    -- Check skip conditions
    -- Only skip guilded contacts for pure "invite" mode (invite would fail).
    -- For "whisper" and "recruit" modes, guilded players still receive the message.
    if self.rules.skipConditions.skipGuilded and contact.guild and contact.guild ~= "" then
        if self.rules.mode == "invite" then
            return false, "guilded"
        end
    end

    if self.rules.skipConditions.skipContacted and contact.status == "contacted" then
        return false, "already_contacted"
    end

    if self.rules.skipConditions.skipInvited and (contact.status == "invited" or contact.status == "joined") then
        return false, "already_invited"
    end

    -- Check level range
    local level = contact.level or 0
    if level > 0 then
        if level < self.rules.levelMin or level > self.rules.levelMax then
            return false, "level_range"
        end
    end

    -- Check class filter
    local hasClassFilter = false
    for _ in pairs(self.rules.classes) do hasClassFilter = true; break end
    if hasClassFilter then
        local classFile = contact.classFile or ""
        if not self.rules.classes[classFile] then
            return false, "class_filter"
        end
    end

    -- Check cross-realm
    if self.rules.excludeCrossRealm and contact.crossRealm then
        return false, "cross_realm"
    end

    -- Check opt-in requirement
    if self.rules.requireOptIn and not contact.optedIn then
        return false, "no_opt_in"
    end

    return true
end

---------------------------------------------------------------------------
-- Processing Queue
---------------------------------------------------------------------------

function AR:GetProcessQueue()
    local queue = ns.DB_QueueList()
    local processed = {}

    for _, key in ipairs(queue) do
        local contact = ns.DB_GetContact(key)
        if contact then
            local canProcess, reason = self:CanProcessContact(key, contact)
            if canProcess then
                -- Check for priority classes
                local isPriority = false
                if contact.classFile then
                    for _, priorityClass in ipairs(self.rules.priorityClasses) do
                        if contact.classFile == priorityClass then
                            isPriority = true
                            break
                        end
                    end
                end

                table.insert(processed, {
                    key = key,
                    contact = contact,
                    priority = isPriority,
                })
            end
        end
    end

    -- Sort by priority (priority classes first)
    table.sort(processed, function(a, b)
        if a.priority ~= b.priority then
            return a.priority
        end
        return (a.contact.firstSeen or 0) < (b.contact.firstSeen or 0)
    end)

    return processed
end

---------------------------------------------------------------------------
-- Auto-Recruitment Logic
---------------------------------------------------------------------------

function AR:ProcessNext()
    if not self.active or self.paused then
        return
    end

    -- Check time restrictions
    if not self:CheckTimeRestrictions() then
        self:Pause()
        ns.Util_Print("Auto-recrutement en pause (hors horaires autorisés)")
        if ns.Notifications_Info then
            ns.Notifications_Info("Auto-recrutement en pause", "Hors horaires autorisés")
        end
        return
    end

    -- Check daily limits
    local limits = self:GetDailyLimits()
    if limits.contactsRemaining <= 0 and limits.invitesRemaining <= 0 then
        self:Stop()
        ns.Util_Print("Auto-recrutement arrêté (limites quotidiennes atteintes)")
        if ns.Notifications_Warning then
            ns.Notifications_Warning("Auto-recrutement arrêté", "Limites quotidiennes atteintes")
        end
        return
    end

    -- Check session limit
    if self.stats.processed >= self.rules.maxPerSession then
        self:Stop()
        ns.Util_Print("Auto-recrutement arrêté (limite de session atteinte)")
        if ns.Notifications_Info then
            ns.Notifications_Info("Auto-recrutement terminé", ("Traités: %d"):format(self.stats.processed))
        end
        return
    end

    -- Get queue and process next contact
    local queue = self:GetProcessQueue()
    if #queue == 0 then
        self:Stop()
        ns.Util_Print("Auto-recrutement arrêté (file vide)")
        if ns.Notifications_Info then
            ns.Notifications_Info("Auto-recrutement terminé", "Aucun contact éligible")
        end
        return
    end

    -- Get next contact (cycle through queue)
    if self.currentIndex > #queue then
        self.currentIndex = 1
    end

    local entry = queue[self.currentIndex]
    self.currentIndex = self.currentIndex + 1
    self.stats.processed = self.stats.processed + 1

    local key = entry.key
    local mode = self.rules.mode

    -- Process based on mode
    local success = false
    if mode == "whisper" and limits.contactsRemaining > 0 then
        local ok, why = ns.Queue_Whisper(key, self.rules.template)
        if ok then
            self.stats.contacted = self.stats.contacted + 1
            self:IncrementDailyCount("contacted")
            success = true
        else
            self.stats.errors = self.stats.errors + 1
            ns.DB_Log("AUTO", ("Échec message %s: %s"):format(key, tostring(why)))
        end
    elseif mode == "invite" and limits.invitesRemaining > 0 then
        local ok, why = ns.Queue_Invite(key)
        if ok then
            self.stats.invited = self.stats.invited + 1
            self:IncrementDailyCount("invited")
            success = true
        else
            self.stats.errors = self.stats.errors + 1
            ns.DB_Log("AUTO", ("Échec invitation %s: %s"):format(key, tostring(why)))
        end
    elseif mode == "recruit" and limits.contactsRemaining > 0 and limits.invitesRemaining > 0 then
        local ok, why = ns.Queue_Recruit(key, self.rules.template)
        if ok then
            self.stats.contacted = self.stats.contacted + 1
            self.stats.invited = self.stats.invited + 1
            self:IncrementDailyCount("contacted")
            self:IncrementDailyCount("invited")
            success = true
        else
            self.stats.errors = self.stats.errors + 1
            ns.DB_Log("AUTO", ("Échec recrutement %s: %s"):format(key, tostring(why)))
        end
    else
        -- Daily limit exhausted for current mode
        self.stats.skipped = self.stats.skipped + 1
        success = true  -- not a failure, just skipped due to limits
    end

    if not success then
        self.stats.skipped = self.stats.skipped + 1
    end

    ns.UI_Refresh()
end

---------------------------------------------------------------------------
-- Control Functions
---------------------------------------------------------------------------

function AR:Start()
    if self.active then return end

    -- Tier gate: Auto-Recruiter requires Pro tier
    if ns.Tier and not ns.Tier:CanUse("auto_recruiter") then
        ns.Tier:ShowUpgrade("auto_recruiter")
        return
    end

    -- Mutual exclusion with Sleep Recruiter
    if ns.SleepRecruiter and ns.SleepRecruiter:IsActive() then
        if ns.Notifications_Warning then
            ns.Notifications_Warning("Auto-recrutement", "Impossible : le Mode Nuit est actif.")
        end
        return
    end

    self.active = true
    self.paused = false
    self.currentIndex = 1
    self.stats = {
        startedAt = ns.Util_Now(),
        processed = 0,
        contacted = 0,
        invited = 0,
        skipped = 0,
        errors = 0,
    }

    -- Start ticker
    local delay = self.rules.delayBetweenActions or 15
    self.ticker = C_Timer.NewTicker(delay, function()
        self:ProcessNext()
    end)

    ns.DB_Log("AUTO", "Auto-recrutement démarré")
    if ns.Notifications_Success then
        ns.Notifications_Success("Auto-recrutement", "Démarré avec succès")
    end

    ns.UI_Refresh()
end

function AR:Stop()
    if not self.active then return end

    self.active = false
    self.paused = false

    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    local summary = ("Arrêté - Traités: %d, Messages: %d, Invitations: %d, Ignorés: %d"):format(
        self.stats.processed, self.stats.contacted, self.stats.invited, self.stats.skipped
    )
    ns.DB_Log("AUTO", summary)

    if ns.Notifications_Info then
        ns.Notifications_Info("Auto-recrutement arrêté", summary)
    end

    -- Discord notification
    if ns.DiscordQueue and ns.DiscordQueue.NotifyAutoRecruiterComplete then
      ns.DiscordQueue:NotifyAutoRecruiterComplete(self.stats)
    end

    ns.UI_Refresh()
end

function AR:Pause()
    if not self.active then return end
    self.paused = true
    ns.Util_Print("Auto-recrutement en pause")
    ns.UI_Refresh()
end

function AR:Resume()
    if not self.active then return end
    self.paused = false
    ns.Util_Print("Auto-recrutement repris")
    ns.UI_Refresh()
end

function AR:Toggle()
    if self.active then
        self:Stop()
    else
        self:Start()
    end
end

function AR:IsActive()
    return self.active
end

function AR:IsPaused()
    return self.paused
end

function AR:GetStats()
    local stats = {}
    for k, v in pairs(self.stats) do
        stats[k] = v
    end

    -- Add estimated time remaining
    if self.active and self.stats.processed > 0 then
        local elapsed = ns.Util_Now() - self.stats.startedAt
        local avgTimePerContact = elapsed / self.stats.processed
        local remaining = self.rules.maxPerSession - self.stats.processed
        stats.estimatedTimeRemaining = remaining * avgTimePerContact
    end

    return stats
end
