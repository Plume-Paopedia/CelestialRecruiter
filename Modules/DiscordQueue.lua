local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Discord Queue Module
-- Queues events to SavedVariables for external webhook delivery
-- ═══════════════════════════════════════════════════════════════════

ns.DiscordQueue = ns.DiscordQueue or {}
local DQ = ns.DiscordQueue

---------------------------------------------------------------------------
-- Event Type Configuration
---------------------------------------------------------------------------

-- Color codes for Discord embeds
local COLORS = {
    GREEN = 3066993,    -- 0x2ecc71 - positive events
    BLUE = 3447003,     -- 0x3498db - info events
    ORANGE = 15105570,  -- 0xe67e22 - warning events
    RED = 15158332,     -- 0xe74c3c - negative events
    PURPLE = 10181046,  -- 0x9b59b6 - system events
    GOLD = 16766720,    -- 0xffd700 - special events
}

-- Event type metadata
local EVENT_TYPES = {
    -- Guild events
    guild_join = { color = COLORS.GREEN, icon = "🎉", label = "Nouvelle Recrue" },
    guild_leave = { color = COLORS.ORANGE, icon = "👋", label = "Départ de Guilde" },
    guild_promote = { color = COLORS.BLUE, icon = "⬆️", label = "Promotion" },
    guild_demote = { color = COLORS.ORANGE, icon = "⬇️", label = "Rétrogradation" },

    -- Recruitment events
    whisper_received = { color = COLORS.GREEN, icon = "📩", label = "Whisper Recu" },
    player_whispered = { color = COLORS.BLUE, icon = "💬", label = "Message Envoyé" },
    player_invited = { color = COLORS.BLUE, icon = "✉️", label = "Invitation Envoyée" },
    player_accepted = { color = COLORS.GREEN, icon = "✅", label = "Invitation Acceptée" },
    player_declined = { color = COLORS.ORANGE, icon = "❌", label = "Invitation Refusée" },
    player_joined = { color = COLORS.GREEN, icon = "🎊", label = "Joueur Rejoint" },

    -- Queue management
    queue_added = { color = COLORS.BLUE, icon = "➕", label = "Ajouté à la File" },
    queue_removed = { color = COLORS.ORANGE, icon = "➖", label = "Retiré de la File" },

    -- Blacklist
    player_blacklisted = { color = COLORS.RED, icon = "🚫", label = "Joueur Blacklisté" },

    -- Scanner
    scanner_started = { color = COLORS.PURPLE, icon = "🔍", label = "Scanner Démarré" },
    scanner_stopped = { color = COLORS.PURPLE, icon = "⏹️", label = "Scanner Arrêté" },
    scanner_complete = { color = COLORS.PURPLE, icon = "✅", label = "Scan Terminé" },

    -- Summaries
    daily_summary = { color = COLORS.PURPLE, icon = "📊", label = "Résumé Quotidien" },
    session_summary = { color = COLORS.PURPLE, icon = "📈", label = "Résumé de Session" },

    -- Auto-recruiter
    autorecruiter_started = { color = COLORS.PURPLE, icon = "🤖", label = "Auto-Recruteur Démarré" },
    autorecruiter_stopped = { color = COLORS.PURPLE, icon = "⏸️", label = "Auto-Recruteur Arrêté" },
    autorecruiter_complete = { color = COLORS.PURPLE, icon = "✅", label = "Auto-Recruteur Terminé" },

    -- Alerts
    limit_reached = { color = COLORS.RED, icon = "⚠️", label = "Limite Atteinte" },
    error_alert = { color = COLORS.RED, icon = "❌", label = "Erreur" },
}

---------------------------------------------------------------------------
-- Initialize Discord Settings
---------------------------------------------------------------------------
function DQ:Init()
    if not ns.db then return end

    -- Initialize profile settings
    if not ns.db.profile.discordNotify then
        ns.db.profile.discordNotify = {}
    end

    local discord = ns.db.profile.discordNotify

    -- Webhook URL
    if discord.webhookUrl == nil then
        discord.webhookUrl = ""
    end

    -- Master enable
    if discord.enabled == nil then
        discord.enabled = false
    end

    -- Per-event toggles (default all enabled)
    if not discord.events then
        discord.events = {}
    end

    for eventType, _ in pairs(EVENT_TYPES) do
        if discord.events[eventType] == nil then
            -- Default enable states
            if eventType:match("^guild_") or eventType:match("joined") or eventType:match("summary") or eventType == "whisper_received" then
                discord.events[eventType] = true
            else
                discord.events[eventType] = false
            end
        end
    end

    -- Auto-flush: auto-reload on critical events (guild join/leave)
    if discord.autoFlush == nil then
        discord.autoFlush = true
    end

    -- Initialize global queue
    if not ns.db.global.discordQueue then
        ns.db.global.discordQueue = {}
    end
end

---------------------------------------------------------------------------
-- Auto-Flush: schedule ReloadUI for immediate Discord delivery
---------------------------------------------------------------------------
local autoFlushPending = false
local flushButton = nil

local function showFlushButton()
    if flushButton and flushButton:IsShown() then return end
    if not flushButton then
        flushButton = CreateFrame("Button", "CelRecFlushBtn", UIParent, "UIPanelButtonTemplate")
        flushButton:SetSize(220, 32)
        flushButton:SetPoint("TOP", UIParent, "TOP", 0, -80)
        flushButton:SetFrameStrata("DIALOG")
        flushButton:SetText("|cff00d1ff[Discord]|r Envoyer maintenant")
        flushButton:SetScript("OnClick", function(self)
            self:Hide()
            autoFlushPending = false
            ReloadUI()
        end)
    end
    flushButton:Show()
    -- Auto-hide after 15 seconds
    C_Timer.After(15, function()
        if flushButton then flushButton:Hide() end
        autoFlushPending = false
    end)
end

function DQ:ScheduleAutoFlush()
    -- Guard: already pending, or disabled
    if autoFlushPending then return end
    if not ns.db or not ns.db.profile or not ns.db.profile.discordNotify then return end
    local d = ns.db.profile.discordNotify
    if not d.enabled or d.autoFlush == false then return end

    autoFlushPending = true

    local function doFlush()
        autoFlushPending = false
        ns.Util_Print("|cff00d1ff[Discord]|r Envoi en cours...")
        -- Try ReloadUI — if it's protected (needs hardware event), show fallback button
        local ok = pcall(ReloadUI)
        if not ok then
            showFlushButton()
        end
    end

    -- Don't reload during combat — wait for combat end
    if InCombatLockdown() then
        ns.Util_Print("|cff00d1ff[Discord]|r Envoi prevu apres le combat...")
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            C_Timer.After(1, doFlush)
        end)
    else
        -- 2s delay: batch multiple events before reload
        C_Timer.After(2, doFlush)
    end
end

---------------------------------------------------------------------------
-- Queue Event
---------------------------------------------------------------------------
function DQ:QueueEvent(eventType, data)
    if not ns.db or not ns.db.global.discordQueue then return false end
    if not ns.db.profile.discordNotify or not ns.db.profile.discordNotify.enabled then return false end
    if not ns.db.profile.discordNotify.events[eventType] then return false end

    local eventMeta = EVENT_TYPES[eventType]
    if not eventMeta then return false end

    local queue = ns.db.global.discordQueue

    -- Build event entry
    local event = {
        timestamp = ns.Util_Now(),
        eventType = eventType,
        icon = eventMeta.icon,
        color = eventMeta.color,
        title = data.title or eventMeta.label,
        description = data.description or "",
        fields = data.fields or {},
    }

    -- Add to queue
    table.insert(queue, event)

    -- Limit queue size (keep last 100 events)
    while #queue > 100 do
        table.remove(queue, 1)
    end

    return true
end

---------------------------------------------------------------------------
-- Get Pending Events
---------------------------------------------------------------------------
function DQ:GetPendingEvents()
    if not ns.db or not ns.db.global.discordQueue then return {} end
    return ns.db.global.discordQueue
end

---------------------------------------------------------------------------
-- Clear Processed Events
---------------------------------------------------------------------------
function DQ:ClearProcessedEvents(upToTimestamp)
    if not ns.db or not ns.db.global.discordQueue then return 0 end

    local queue = ns.db.global.discordQueue
    local removed = 0

    -- Remove events up to timestamp
    local i = 1
    while i <= #queue do
        if queue[i].timestamp <= upToTimestamp then
            table.remove(queue, i)
            removed = removed + 1
        else
            i = i + 1
        end
    end

    return removed
end

---------------------------------------------------------------------------
-- Clear All Events (for testing/reset)
---------------------------------------------------------------------------
function DQ:ClearAllEvents()
    if not ns.db or not ns.db.global.discordQueue then return end
    ns.db.global.discordQueue = {}
end

---------------------------------------------------------------------------
-- Utility: Build Contact Fields (enriched)
---------------------------------------------------------------------------
local function buildContactFields(contact, key)
    local fields = {}

    if contact then
        -- Level
        if contact.level then
            table.insert(fields, {
                name = "Niveau",
                value = tostring(contact.level),
                inline = true
            })
        end

        -- Class
        if contact.classLabel or contact.classFile then
            table.insert(fields, {
                name = "Classe",
                value = contact.classLabel or contact.classFile or "?",
                inline = true
            })
        end

        -- Race
        if contact.race and contact.race ~= "" then
            table.insert(fields, {
                name = "Race",
                value = contact.race,
                inline = true
            })
        end

        -- Zone
        if contact.zone and contact.zone ~= "" then
            table.insert(fields, {
                name = "Zone",
                value = contact.zone,
                inline = true
            })
        end

        -- Guild (if any)
        if contact.guild and contact.guild ~= "" then
            table.insert(fields, {
                name = "Guilde",
                value = contact.guild,
                inline = true
            })
        end

        -- Status
        if contact.status then
            local statusLabels = {
                new = "Nouveau",
                contacted = "Contacte",
                invited = "Invite",
                joined = "Rejoint",
                ignored = "Ignore"
            }
            table.insert(fields, {
                name = "Statut",
                value = statusLabels[contact.status] or contact.status,
                inline = true
            })
        end

        -- Recruited by
        if contact.recruitedBy and contact.recruitedBy ~= "" then
            table.insert(fields, {
                name = "Recrute par",
                value = contact.recruitedBy,
                inline = true
            })
        end

        -- Source
        if contact.source and contact.source ~= "" then
            local sourceLabels = {
                scanner = "Scanner /who",
                manual = "Ajout manuel",
                import = "Import",
                whisper = "Whisper entrant",
            }
            table.insert(fields, {
                name = "Source",
                value = sourceLabels[contact.source] or contact.source,
                inline = true
            })
        end

        -- Template used
        if contact.lastTemplate and contact.lastTemplate ~= "" then
            table.insert(fields, {
                name = "Template",
                value = contact.lastTemplate,
                inline = true
            })
        end

        -- Opt-in
        if contact.optedIn then
            table.insert(fields, {
                name = "Opt-in",
                value = "Oui",
                inline = true
            })
        end

        -- First seen
        if contact.firstSeen and contact.firstSeen > 0 and ns.Util_FormatAgo then
            table.insert(fields, {
                name = "Premier contact",
                value = ns.Util_FormatAgo(contact.firstSeen),
                inline = true
            })
        end
    else
        -- Just player name if no contact data
        table.insert(fields, {
            name = "Joueur",
            value = key or "Inconnu",
            inline = false
        })
    end

    return fields
end

---------------------------------------------------------------------------
-- Event Helpers
---------------------------------------------------------------------------

-- Guild: Player Joined
function DQ:NotifyGuildJoin(playerName)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)

    -- Time-to-join calculation (from first whisper to now)
    if contact and (contact.lastWhisperOut or 0) > 0 then
        local diff = time() - contact.lastWhisperOut
        local timeStr
        if diff < 3600 then
            timeStr = string.format("%d min", math.floor(diff / 60))
        elseif diff < 86400 then
            timeStr = string.format("%.1f h", diff / 3600)
        else
            timeStr = string.format("%.1f j", diff / 86400)
        end
        table.insert(fields, {
            name = "Temps de conversion",
            value = timeStr,
            inline = true
        })
    end

    -- Recruiter highlight in description
    local desc = string.format("**%s** a rejoint la guilde!", playerName)
    if contact and contact.recruitedBy and contact.recruitedBy ~= "" then
        desc = desc .. string.format("\nRecrute par **%s**", contact.recruitedBy)
    end

    self:QueueEvent("guild_join", {
        description = desc,
        fields = fields
    })
end

-- Guild: Player Left
function DQ:NotifyGuildLeave(playerName)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)

    local desc = string.format("**%s** a quitte la guilde.", playerName)
    if contact and contact.recruitedBy and contact.recruitedBy ~= "" then
        desc = desc .. string.format("\n(Avait ete recrute par **%s**)", contact.recruitedBy)
    end

    self:QueueEvent("guild_leave", {
        description = desc,
        fields = fields
    })
end

-- Recruitment: Whisper Sent
function DQ:NotifyWhisperSent(playerName, template)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)

    local desc = string.format("Message envoye a **%s**", playerName)
    local recruiter = UnitName("player")
    if recruiter then
        desc = desc .. string.format(" par **%s**", recruiter)
    end

    self:QueueEvent("player_whispered", {
        description = desc,
        fields = fields
    })
end

-- Recruitment: Invite Sent
function DQ:NotifyInviteSent(playerName)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)

    local desc = string.format("Invitation de guilde envoyee a **%s**", playerName)
    local recruiter = UnitName("player")
    if recruiter then
        desc = desc .. string.format(" par **%s**", recruiter)
    end

    self:QueueEvent("player_invited", {
        description = desc,
        fields = fields
    })
end

-- Recruitment: Player Joined (from contact)
function DQ:NotifyPlayerJoined(playerName)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)

    -- Time-to-join calculation
    if contact and (contact.lastWhisperOut or 0) > 0 then
        local diff = time() - contact.lastWhisperOut
        local timeStr
        if diff < 3600 then
            timeStr = string.format("%d min", math.floor(diff / 60))
        elseif diff < 86400 then
            timeStr = string.format("%.1f h", diff / 3600)
        else
            timeStr = string.format("%.1f j", diff / 86400)
        end
        table.insert(fields, {
            name = "Temps de conversion",
            value = timeStr,
            inline = true
        })
    end

    local desc = string.format("**%s** a rejoint la guilde apres recrutement!", playerName)
    if contact and contact.recruitedBy and contact.recruitedBy ~= "" then
        desc = desc .. string.format("\nRecrute par **%s**", contact.recruitedBy)
    end

    self:QueueEvent("player_joined", {
        description = desc,
        fields = fields
    })
end

-- Queue: Player Added
function DQ:NotifyQueueAdded(playerName)
    local contact = ns.DB_GetContact(playerName)
    self:QueueEvent("queue_added", {
        description = string.format("**%s** ajouté à la file de recrutement", playerName),
        fields = buildContactFields(contact, playerName)
    })
end

-- Queue: Player Removed
function DQ:NotifyQueueRemoved(playerName, reason)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)
    if reason then
        table.insert(fields, {
            name = "Raison",
            value = reason,
            inline = false
        })
    end

    self:QueueEvent("queue_removed", {
        description = string.format("**%s** retiré de la file", playerName),
        fields = fields
    })
end

-- Blacklist: Player Blacklisted
function DQ:NotifyBlacklisted(playerName, reason)
    local contact = ns.DB_GetContact(playerName)
    local fields = buildContactFields(contact, playerName)
    if reason then
        table.insert(fields, {
            name = "Raison",
            value = reason,
            inline = false
        })
    end

    self:QueueEvent("player_blacklisted", {
        description = string.format("**%s** ajouté à la liste noire", playerName),
        fields = fields
    })
end

-- Scanner: Started
function DQ:NotifyScannerStarted(levelRange)
    self:QueueEvent("scanner_started", {
        description = string.format("Scanner lancé (niveaux %s)", levelRange or "tous"),
        fields = {
            {
                name = "Mode",
                value = "Recherche de recrues potentielles",
                inline = false
            }
        }
    })
end

-- Scanner: Stopped
function DQ:NotifyScannerStopped(stats)
    local fields = {}
    if stats then
        if stats.found then
            table.insert(fields, {
                name = "Joueurs Trouvés",
                value = tostring(stats.found),
                inline = true
            })
        end
        if stats.added then
            table.insert(fields, {
                name = "Ajoutés à la File",
                value = tostring(stats.added),
                inline = true
            })
        end
        if stats.queries then
            table.insert(fields, {
                name = "Requêtes /who",
                value = tostring(stats.queries),
                inline = true
            })
        end
    end

    self:QueueEvent("scanner_stopped", {
        description = "Scanner arrêté",
        fields = fields
    })
end

-- Scanner: Complete
function DQ:NotifyScannerComplete(stats)
    local fields = {}
    if stats then
        if stats.found then
            table.insert(fields, {
                name = "Joueurs Trouvés",
                value = tostring(stats.found),
                inline = true
            })
        end
        if stats.added then
            table.insert(fields, {
                name = "Ajoutés à la File",
                value = tostring(stats.added),
                inline = true
            })
        end
        if stats.queries then
            table.insert(fields, {
                name = "Requêtes /who",
                value = tostring(stats.queries),
                inline = true
            })
        end
        if stats.duration then
            table.insert(fields, {
                name = "Durée",
                value = string.format("%.1f min", stats.duration / 60),
                inline = true
            })
        end
    end

    self:QueueEvent("scanner_complete", {
        description = "Scan terminé avec succès",
        fields = fields
    })
end

-- Daily Summary
function DQ:NotifyDailySummary(stats)
    local fields = {}

    if stats then
        if stats.scans then
            table.insert(fields, {
                name = "Scans",
                value = tostring(stats.scans),
                inline = true
            })
        end
        if stats.found then
            table.insert(fields, {
                name = "Joueurs Trouvés",
                value = tostring(stats.found),
                inline = true
            })
        end
        if stats.contacted then
            table.insert(fields, {
                name = "Contactés",
                value = tostring(stats.contacted),
                inline = true
            })
        end
        if stats.invited then
            table.insert(fields, {
                name = "Invités",
                value = tostring(stats.invited),
                inline = true
            })
        end
        if stats.joined then
            table.insert(fields, {
                name = "Recrues",
                value = tostring(stats.joined),
                inline = true
            })
        end
    end

    local day = stats and stats.day or date("%Y-%m-%d")

    self:QueueEvent("daily_summary", {
        title = "Résumé Quotidien - " .. day,
        description = "Statistiques de recrutement de la journée",
        fields = fields
    })
end

-- Session Summary
function DQ:NotifySessionSummary(stats)
    local fields = {}

    if stats then
        if stats.whispersSent then
            table.insert(fields, {
                name = "Messages Envoyés",
                value = tostring(stats.whispersSent),
                inline = true
            })
        end
        if stats.invitesSent then
            table.insert(fields, {
                name = "Invitations Envoyées",
                value = tostring(stats.invitesSent),
                inline = true
            })
        end
        if stats.queueAdded then
            table.insert(fields, {
                name = "Ajoutés à la File",
                value = tostring(stats.queueAdded),
                inline = true
            })
        end
        if stats.duration then
            table.insert(fields, {
                name = "Durée de Session",
                value = string.format("%.1f min", stats.duration / 60),
                inline = true
            })
        end
    end

    self:QueueEvent("session_summary", {
        description = "Statistiques de la session de recrutement",
        fields = fields
    })
end

-- Auto-Recruiter Complete
function DQ:NotifyAutoRecruiterComplete(stats)
    local fields = {}

    if stats then
        if stats.processed then
            table.insert(fields, {
                name = "Traités",
                value = tostring(stats.processed),
                inline = true
            })
        end
        if stats.contacted then
            table.insert(fields, {
                name = "Contactés",
                value = tostring(stats.contacted),
                inline = true
            })
        end
        if stats.invited then
            table.insert(fields, {
                name = "Invités",
                value = tostring(stats.invited),
                inline = true
            })
        end
        if stats.skipped then
            table.insert(fields, {
                name = "Ignorés",
                value = tostring(stats.skipped),
                inline = true
            })
        end
        if stats.errors then
            table.insert(fields, {
                name = "Erreurs",
                value = tostring(stats.errors),
                inline = true
            })
        end
    end

    self:QueueEvent("autorecruiter_complete", {
        description = "Session d'auto-recrutement terminée",
        fields = fields
    })
end

-- Limit Reached Alert
function DQ:NotifyLimitReached(limitType, current, max)
    self:QueueEvent("limit_reached", {
        description = string.format("**%s** atteint: %d/%d", limitType, current, max),
        fields = {
            {
                name = "Action Requise",
                value = "Attendez avant de continuer le recrutement",
                inline = false
            }
        }
    })
end

---------------------------------------------------------------------------
-- Test Webhook
---------------------------------------------------------------------------
function DQ:TestWebhook()
    if not ns.db or not ns.db.profile.discordNotify then return false end

    local webhookUrl = ns.db.profile.discordNotify.webhookUrl
    if not webhookUrl or webhookUrl == "" then
        ns.Util_Print("Aucune URL de webhook Discord configurée")
        return false
    end

    -- Queue test event
    local testEvent = {
        timestamp = ns.Util_Now(),
        eventType = "test",
        icon = "✅",
        color = COLORS.GREEN,
        title = "Test Webhook",
        description = "Connexion Discord établie avec succès! CelestialRecruiter est prêt à envoyer des notifications.",
        fields = {
            {
                name = "Statut",
                value = "Opérationnel",
                inline = true
            },
            {
                name = "Version",
                value = "3.4.0",
                inline = true
            }
        }
    }

    table.insert(ns.db.global.discordQueue, testEvent)

    ns.Util_Print("Événement de test ajouté à la file Discord")
    if ns.Notifications_Info then
        ns.Notifications_Info("Test Discord", "Événement ajouté - Vérifiez que le script Python est en cours d'exécution")
    end

    return true
end

---------------------------------------------------------------------------
-- Get Event Types for Settings UI
---------------------------------------------------------------------------
function DQ:GetEventTypes()
    local categories = {
        {
            label = "Événements de Guilde",
            events = {
                { id = "guild_join", label = "Nouveau membre" },
                { id = "guild_leave", label = "Membre quitte" },
                { id = "guild_promote", label = "Promotion" },
                { id = "guild_demote", label = "Rétrogradation" },
            }
        },
        {
            label = "Recrutement",
            events = {
                { id = "whisper_received", label = "Whisper recu" },
                { id = "player_whispered", label = "Message envoyé" },
                { id = "player_invited", label = "Invitation envoyée" },
                { id = "player_joined", label = "Joueur rejoint" },
                { id = "queue_added", label = "Ajouté à la file" },
                { id = "queue_removed", label = "Retiré de la file" },
                { id = "player_blacklisted", label = "Joueur blacklisté" },
            }
        },
        {
            label = "Scanner & Auto-Recruteur",
            events = {
                { id = "scanner_started", label = "Scanner démarré" },
                { id = "scanner_stopped", label = "Scanner arrêté" },
                { id = "scanner_complete", label = "Scan terminé" },
                { id = "autorecruiter_complete", label = "Auto-recruteur terminé" },
            }
        },
        {
            label = "Résumés & Alertes",
            events = {
                { id = "daily_summary", label = "Résumé quotidien" },
                { id = "session_summary", label = "Résumé de session" },
                { id = "limit_reached", label = "Limite atteinte" },
            }
        }
    }

    return categories
end
