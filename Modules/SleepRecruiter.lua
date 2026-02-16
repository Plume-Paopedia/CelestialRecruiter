local _, ns = ...
local W = ns.UIWidgets
local C = W and W.C or {}

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Sleep Recruiter (Mode Nuit)
-- AFK overnight queue processor with AI integration
-- ═══════════════════════════════════════════════════════════════════

ns.SleepRecruiter = ns.SleepRecruiter or {}
local SR = ns.SleepRecruiter

-- Runtime state (not persisted directly)
SR.active = false
SR.ticker = nil
SR.reloadTimer = nil
SR.startedAt = 0
SR.reloadCount = 0
SR.stopReason = nil
SR.lastContactKey = nil
SR.consecutiveSkips = 0
SR.stats = {
    processed = 0,
    contacted = 0,
    invited = 0,
    skipped = 0,
    errors = 0,
    aiMessages = 0,
    aiResponses = 0,
}

local overlay = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh%02dm", h, m)
    else
        return string.format("%dm%02ds", m, s)
    end
end

local function getSettings()
    return ns.db and ns.db.profile and ns.db.profile.sleepRecruiter or {}
end

local function cancelTimer(timer)
    if timer then pcall(timer.Cancel, timer) end
    return nil
end

---------------------------------------------------------------------------
-- Init: called on addon load, handles resume after ReloadUI
---------------------------------------------------------------------------
function SR:Init()
    if not ns.db or not ns.db.profile then return end

    local saved = ns.db.profile.sleepRecruiter
    if not saved then return end

    -- Resume after ReloadUI (Mode Nuit was running before reload)
    if saved._active then
        saved._active = nil
        self.startedAt = saved._startedAt or ns.Util_Now()
        self.stats = saved._stats or self.stats
        self.reloadCount = (saved._reloadCount or 0)
        saved._startedAt = nil
        saved._stats = nil
        saved._reloadCount = nil

        -- Delayed resume to let UI fully load
        C_Timer.After(3, function()
            self:Resume()
        end)
        return
    end

    -- Check for crash/disconnect (had _lastStats but no explicit stopReason)
    if saved._lastStats and not saved._lastStats.stopReason then
        saved._lastStats.stopReason = "disconnect"
        C_Timer.After(5, function()
            self:ShowCompletionSummary(saved._lastStats)
        end)
    end

    -- Send pending AI responses after reload
    if ns.AIConversation and ns.AIConversation.SendPendingResponses then
        C_Timer.After(4, function()
            local sent = ns.AIConversation:SendPendingResponses()
            if sent > 0 then
                self.stats.aiResponses = self.stats.aiResponses + sent
                ns.DB_Log("AI", string.format("%d reponses AI envoyees apres reload", sent))
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Start Mode Nuit
---------------------------------------------------------------------------
function SR:Start()
    if self.active then return end

    -- Tier gate
    if ns.Tier and not ns.Tier:CanUse("sleep_recruiter") then
        ns.Tier:ShowUpgrade("sleep_recruiter")
        return
    end

    -- Mutual exclusion: stop AutoRecruiter if running
    if ns.AutoRecruiter and ns.AutoRecruiter.IsActive and ns.AutoRecruiter:IsActive() then
        ns.AutoRecruiter:Stop()
        ns.Util_Print("Auto-recruteur arr\195\170t\195\169 (Mode Nuit activ\195\169)")
    end

    -- Validate queue has contacts
    local queue = ns.DB_QueueList and ns.DB_QueueList() or {}
    if #queue == 0 then
        if ns.Notifications_Info then
            ns.Notifications_Info("Mode Nuit", "File d'attente vide. Lancez un scan d'abord.")
        end
        return
    end

    -- Initialize
    self.active = true
    self.startedAt = ns.Util_Now()
    self.stopReason = nil
    self.lastContactKey = nil
    self.consecutiveSkips = 0
    self.stats = {
        processed = 0, contacted = 0, invited = 0,
        skipped = 0, errors = 0, aiMessages = 0, aiResponses = 0,
    }

    local settings = getSettings()
    local delay = math.max(30, math.min(300, settings.delayBetweenActions or 60))

    -- Create processing ticker
    self.ticker = C_Timer.NewTicker(delay, function()
        self:ProcessNext()
    end)

    -- Schedule periodic ReloadUI for AI sync
    self:ScheduleReload()

    -- Show overlay
    self:ShowOverlay()
    self:UpdateOverlay()

    -- Log and notify
    ns.DB_Log("NUIT", string.format("Mode Nuit demarre: %d contacts en file, delai %ds",
        #queue, delay))

    if ns.Notifications_Success then
        ns.Notifications_Success("Mode Nuit activ\195\169",
            string.format("%d joueur(s) en file, %ds entre chaque action", #queue, delay))
    end

    -- Discord notification
    if ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
        ns.DiscordQueue:QueueEvent("sleeprecruiter_started", {
            title = "Mode Nuit d\195\169marr\195\169",
            description = string.format("%d contacts en file", #queue),
            fields = {
                { name = "D\195\169lai", value = delay .. "s", inline = true },
                { name = "Dur\195\169e max", value = (settings.maxDurationHours or 8) .. "h", inline = true },
                { name = "Max contacts", value = tostring(settings.maxContacts or 200), inline = true },
                { name = "AI", value = settings.useAI and "Actif" or "D\195\169sactiv\195\169", inline = true },
            },
        })
    end

    ns.UI_Refresh()
end

---------------------------------------------------------------------------
-- Resume after ReloadUI (internal, called from Init)
---------------------------------------------------------------------------
function SR:Resume()
    if self.active then return end -- already running

    self.active = true
    local settings = getSettings()
    local delay = math.max(30, math.min(300, settings.delayBetweenActions or 60))

    -- Recreate ticker
    self.ticker = C_Timer.NewTicker(delay, function()
        self:ProcessNext()
    end)

    -- Schedule next reload
    self:ScheduleReload()

    -- Show overlay
    self:ShowOverlay()
    self:UpdateOverlay()

    -- Send any AI responses that Python generated during the reload
    if ns.AIConversation and ns.AIConversation.SendPendingResponses then
        local sent = ns.AIConversation:SendPendingResponses()
        if sent > 0 then
            self.stats.aiResponses = self.stats.aiResponses + sent
        end
    end

    ns.DB_Log("NUIT", string.format("Mode Nuit repris apres reload #%d", self.reloadCount))
    ns.UI_Refresh()
end

---------------------------------------------------------------------------
-- Stop Mode Nuit
---------------------------------------------------------------------------
function SR:Stop(reason)
    if not self.active then return end

    self.active = false
    self.stopReason = reason or "manual"
    self.ticker = cancelTimer(self.ticker)
    self.reloadTimer = cancelTimer(self.reloadTimer)

    local elapsed = ns.Util_Now() - self.startedAt

    -- Save last stats for review
    local lastStats = {
        startedAt = self.startedAt,
        stoppedAt = ns.Util_Now(),
        stopReason = self.stopReason,
        elapsed = elapsed,
        processed = self.stats.processed,
        contacted = self.stats.contacted,
        invited = self.stats.invited,
        skipped = self.stats.skipped,
        errors = self.stats.errors,
        aiMessages = self.stats.aiMessages,
        aiResponses = self.stats.aiResponses,
        reloads = self.reloadCount,
    }
    if ns.db and ns.db.profile and ns.db.profile.sleepRecruiter then
        ns.db.profile.sleepRecruiter._lastStats = lastStats
    end

    -- Show completion summary
    self:ShowCompletionSummary(lastStats)

    -- Discord notification
    if ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
        local reasons = {
            manual = "Arr\195\170t manuel",
            duration = "Dur\195\169e max atteinte",
            max_contacts = "Max contacts atteint",
            queue_empty = "File vid\195\169e",
            disconnect = "D\195\169connexion",
            auto_recruiter_override = "Auto-recruteur d\195\169marr\195\169",
        }
        ns.DiscordQueue:QueueEvent("sleeprecruiter_complete", {
            title = "Mode Nuit termin\195\169",
            description = reasons[self.stopReason] or self.stopReason,
            fields = {
                { name = "Dur\195\169e", value = formatDuration(elapsed), inline = true },
                { name = "Contact\195\169s", value = tostring(self.stats.contacted), inline = true },
                { name = "Invit\195\169s", value = tostring(self.stats.invited), inline = true },
                { name = "Skip\195\169s", value = tostring(self.stats.skipped), inline = true },
                { name = "Erreurs", value = tostring(self.stats.errors), inline = true },
                { name = "Messages AI", value = tostring(self.stats.aiMessages), inline = true },
                { name = "Reloads", value = tostring(self.reloadCount), inline = true },
            },
        })
    end

    -- Hide overlay
    self:HideOverlay()

    ns.DB_Log("NUIT", string.format("Mode Nuit arrete (%s) - %s, %d contactes, %d invites",
        self.stopReason, formatDuration(elapsed), self.stats.contacted, self.stats.invited))

    ns.UI_Refresh()
end

---------------------------------------------------------------------------
-- Toggle
---------------------------------------------------------------------------
function SR:Toggle()
    if self.active then
        self:Stop("manual")
    else
        self:Start()
    end
end

function SR:IsActive()
    return self.active
end

function SR:GetStats()
    return self.stats
end

---------------------------------------------------------------------------
-- Schedule periodic ReloadUI (for AI sync)
---------------------------------------------------------------------------
function SR:ScheduleReload()
    self.reloadTimer = cancelTimer(self.reloadTimer)

    local settings = getSettings()
    if not settings.useAI then return end  -- no reload needed without AI

    local delay = math.max(300, math.min(1200, (settings.reloadIntervalMin or 10) * 60))

    self.reloadTimer = C_Timer.NewTimer(delay, function()
        if not self.active then return end

        -- Persist state before reload
        if ns.db and ns.db.profile and ns.db.profile.sleepRecruiter then
            ns.db.profile.sleepRecruiter._active = true
            ns.db.profile.sleepRecruiter._startedAt = self.startedAt
            ns.db.profile.sleepRecruiter._stats = self.stats
            ns.db.profile.sleepRecruiter._reloadCount = self.reloadCount + 1
        end

        ns.DB_Log("NUIT", "ReloadUI pour sync AI (reload #" .. tostring(self.reloadCount + 1) .. ")")
        ReloadUI()
    end)
end

---------------------------------------------------------------------------
-- Process next contact in queue
---------------------------------------------------------------------------
function SR:ProcessNext()
    if not self.active then return end

    local settings = getSettings()

    -- Check auto-stop: duration
    local elapsed = ns.Util_Now() - self.startedAt
    local maxSeconds = (settings.maxDurationHours or 8) * 3600
    if elapsed >= maxSeconds then
        self:Stop("duration")
        return
    end

    -- Check auto-stop: max contacts
    if self.stats.processed >= (settings.maxContacts or 200) then
        self:Stop("max_contacts")
        return
    end

    -- Get eligible queue
    local eligible = self:GetEligibleQueue()

    -- Check auto-stop: queue empty
    if #eligible == 0 then
        self:Stop("queue_empty")
        return
    end

    -- Pick next contact
    local key = eligible[1]
    local contact = ns.DB_GetContact(key)
    if not contact then
        self.stats.skipped = self.stats.skipped + 1
        self:UpdateOverlay()
        return
    end

    -- Determine action mode
    local mode = settings.mode or "recruit"
    local ok, why

    if mode == "whisper" then
        ok, why = self:SendAIWhisper(key, settings)
    elseif mode == "invite" then
        ok, why = ns.Queue_Invite(key)
    else -- "recruit"
        ok, why = self:SendAIRecruit(key, settings)
    end

    -- Update stats
    self.stats.processed = self.stats.processed + 1

    if ok then
        self.consecutiveSkips = 0
        if mode == "invite" then
            self.stats.invited = self.stats.invited + 1
        else
            self.stats.contacted = self.stats.contacted + 1
        end
        self.lastContactKey = key
    else
        -- Distinguish AntiSpam blocks from real errors
        why = why or ""
        if why:find("limite") or why:find("temps de recharge") or why:find("cible AFK") then
            self.stats.skipped = self.stats.skipped + 1
            self.consecutiveSkips = self.consecutiveSkips + 1
        else
            self.stats.errors = self.stats.errors + 1
        end
    end

    self:UpdateOverlay()
end

---------------------------------------------------------------------------
-- Send whisper with AI message (falls back to template)
---------------------------------------------------------------------------
function SR:SendAIWhisper(key, settings)
    -- Try AI message first
    local aiMsg = nil
    if settings.useAI and ns.AIConversation then
        aiMsg = ns.AIConversation:GetAIMessage(key)
    end

    if aiMsg and aiMsg ~= "" then
        -- Send AI-generated message directly
        key = ns.Util_EnsurePlayerRealm(key)
        if not key then return false, "invalid_target" end

        local can, why = ns.AntiSpam_CanWhisper(key)
        if not can then return false, why end

        -- Truncate
        if #aiMsg > 240 then aiMsg = aiMsg:sub(1, 237) .. "..." end

        local sendOk = pcall(SendChatMessage, aiMsg, "WHISPER", nil, key)
        if not sendOk then return false, "send_blocked" end

        ns.AntiSpam_MarkWhisper(key)
        ns.DB_UpsertContact(key, { status = "contacted", recruitedBy = UnitName("player") })
        ns.DB_AddMessage(key, "out", aiMsg)
        ns.DB_Log("NUIT", "AI whisper -> " .. key)
        self.stats.aiMessages = self.stats.aiMessages + 1

        if ns.DiscordQueue and ns.DiscordQueue.NotifyWhisperSent then
            ns.DiscordQueue:NotifyWhisperSent(key, "AI")
        end
        if ns.Statistics and ns.Statistics.RecordEvent then
            ns.Statistics:RecordEvent("contacted", {template = "AI"})
        end
        if ns.Goals and ns.Goals.RecordActivity then
            ns.Goals:RecordActivity("contact")
        end
        if ns.Leaderboard and ns.Leaderboard.RecordDaily then
            ns.Leaderboard:RecordDaily("whisper")
            ns.Leaderboard:RecordDaily("contact")
        end

        ns.UI_Refresh()
        return true
    end

    -- Fallback to normal template whisper
    return ns.Queue_Whisper(key, settings.template or "default")
end

---------------------------------------------------------------------------
-- Send recruit (whisper + invite) with AI message
---------------------------------------------------------------------------
function SR:SendAIRecruit(key, settings)
    ns._silentNotifications = true
    local msgOk, msgWhy = self:SendAIWhisper(key, settings)

    local invOk, invWhy = false, "guilded"
    local c = ns.DB_GetContact(key)
    if not c or not c.guild or c.guild == "" then
        invOk, invWhy = ns.Queue_Invite(key)
        if invOk then self.stats.invited = self.stats.invited + 1 end
    end
    ns._silentNotifications = false

    if not msgOk and not invOk then
        return false, msgWhy or invWhy
    end
    return true
end

---------------------------------------------------------------------------
-- Get eligible queue contacts (sorted by AI priority or score)
---------------------------------------------------------------------------
function SR:GetEligibleQueue()
    local queue = ns.DB_QueueList and ns.DB_QueueList() or {}
    local eligible = {}

    for _, key in ipairs(queue) do
        local c = ns.DB_GetContact(key)
        if c then
            local dominated = false
            -- Skip based on status
            if c.status == "joined" or c.status == "ignored" then dominated = true end
            if c.status == "contacted" then dominated = true end
            if c.status == "invited" then dominated = true end
            -- Skip if recently ignored
            if c.ignoredUntil and c.ignoredUntil > ns.Util_Now() then dominated = true end

            if not dominated then
                eligible[#eligible + 1] = key
            end
        end
    end

    -- Try AI priority ordering first
    if ns.AIConversation and ns.AIConversation.GetPriorityList then
        local priority = ns.AIConversation:GetPriorityList()
        if priority and #priority > 0 then
            local prioSet = {}
            for i, k in ipairs(priority) do prioSet[k] = i end
            table.sort(eligible, function(a, b)
                local pa = prioSet[a] or 99999
                local pb = prioSet[b] or 99999
                return pa < pb
            end)
            return eligible
        end
    end

    -- Fallback: sort by reputation score (best first)
    if ns.Reputation and ns.Reputation.CalculateScore then
        table.sort(eligible, function(a, b)
            local sa = ns.Reputation:CalculateScore(ns.DB_GetContact(a)) or 0
            local sb = ns.Reputation:CalculateScore(ns.DB_GetContact(b)) or 0
            return sa > sb
        end)
    end

    return eligible
end

---------------------------------------------------------------------------
-- Floating Overlay
---------------------------------------------------------------------------
local function CreateOverlay()
    if overlay then return overlay end

    local f = CreateFrame("Frame", "CelRecSleepOverlay", UIParent, "BackdropTemplate")
    f:SetSize(210, 115)
    f:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.06, 0.05, 0.10, 0.94)
    f:SetBackdropBorderColor(0.58, 0.44, 0.86, 0.55)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 10, -8)
    f.title:SetText("|cff9370DB\226\152\189 Mode Nuit|r")

    -- Progress
    f.progress = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.progress:SetPoint("TOPLEFT", 10, -26)
    f.progress:SetTextColor(0.83, 0.77, 0.66)

    -- Time
    f.timeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.timeText:SetPoint("TOPLEFT", 10, -42)
    f.timeText:SetTextColor(0.55, 0.58, 0.66)

    -- Reload countdown
    f.reloadText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.reloadText:SetPoint("TOPLEFT", 10, -58)
    f.reloadText:SetTextColor(0.40, 0.35, 0.50)

    -- Last action
    f.lastAction = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.lastAction:SetPoint("TOPLEFT", 10, -74)
    f.lastAction:SetWidth(130)
    f.lastAction:SetJustifyH("LEFT")
    f.lastAction:SetWordWrap(false)
    f.lastAction:SetTextColor(0.35, 0.38, 0.45)

    -- Stop button
    f.stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.stopBtn:SetSize(70, 22)
    f.stopBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    f.stopBtn:SetText("Arr\195\170ter")
    f.stopBtn:SetScript("OnClick", function()
        ns.SleepRecruiter:Stop("manual")
    end)

    f:Hide()
    overlay = f
    return f
end

function SR:ShowOverlay()
    local f = CreateOverlay()
    f:Show()
end

function SR:HideOverlay()
    if overlay then overlay:Hide() end
end

function SR:UpdateOverlay()
    if not overlay or not overlay:IsVisible() then return end

    local settings = getSettings()
    local elapsed = ns.Util_Now() - self.startedAt
    local maxSeconds = (settings.maxDurationHours or 8) * 3600
    local remaining = math.max(0, maxSeconds - elapsed)
    local maxContacts = settings.maxContacts or 200

    overlay.progress:SetText(string.format("%d/%d trait\195\169s | %d OK %d skip",
        self.stats.processed, maxContacts,
        self.stats.contacted + self.stats.invited, self.stats.skipped))

    overlay.timeText:SetText(string.format("%s \195\169coul\195\169 | %s restant",
        formatDuration(elapsed), formatDuration(remaining)))

    if settings.useAI then
        overlay.reloadText:SetText(string.format("AI actif | %d msg AI | reload #%d",
            self.stats.aiMessages, self.reloadCount))
    else
        overlay.reloadText:SetText("AI d\195\169sactiv\195\169")
    end

    if self.lastContactKey then
        local shortName = self.lastContactKey:match("^([^%-]+)") or self.lastContactKey
        overlay.lastAction:SetText("Dernier: " .. shortName)
    else
        overlay.lastAction:SetText("En attente...")
    end
end

---------------------------------------------------------------------------
-- Completion summary (toast notification)
---------------------------------------------------------------------------
function SR:ShowCompletionSummary(stats)
    if not stats then return end

    local elapsed = stats.elapsed or (stats.stoppedAt and stats.startedAt and (stats.stoppedAt - stats.startedAt)) or 0
    local reasons = {
        manual = "Arr\195\170t manuel",
        duration = "Dur\195\169e max atteinte",
        max_contacts = "Max contacts atteint",
        queue_empty = "File vid\195\169e",
        disconnect = "D\195\169connexion",
        auto_recruiter_override = "Auto-recruteur lanc\195\169",
    }
    local reasonText = reasons[stats.stopReason] or (stats.stopReason or "?")

    local summary = string.format(
        "%s | %d contact\195\169s, %d invit\195\169s, %d skip\195\169s | %d msg AI | %s",
        reasonText, stats.contacted or 0, stats.invited or 0,
        stats.skipped or 0, stats.aiMessages or 0, formatDuration(elapsed))

    if ns.Notifications_Success then
        ns.Notifications_Success("Mode Nuit termin\195\169", summary)
    end
end
