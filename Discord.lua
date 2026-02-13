local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Discord Webhook Integration
-- Real-time notifications to Discord for guild coordination
-- ═══════════════════════════════════════════════════════════════════

ns.Discord = ns.Discord or {}
local Discord = ns.Discord

-- Rate limiting
local lastSend = 0
local MIN_INTERVAL = 2  -- seconds between webhooks

---------------------------------------------------------------------------
-- Send Discord Webhook
---------------------------------------------------------------------------
local function sendWebhook(webhookUrl, payload)
    if not webhookUrl or webhookUrl == "" then
        return false, "No webhook URL configured"
    end

    -- Rate limiting
    local now = GetTime()
    if now - lastSend < MIN_INTERVAL then
        return false, "Rate limited"
    end
    lastSend = now

    -- Note: WoW Lua cannot make HTTP requests directly
    -- This function prepares the data format, but actual sending
    -- requires an external companion app or addon like RESTFul

    -- For now, we'll output to chat with instructions
    local jsonPayload = ns.Discord:EncodePayload(payload)

    if ns.db and ns.db.profile and ns.db.profile.discordWebhookUrl then
        -- Log the webhook data for debugging
        ns.Util_Print("Discord webhook prepared (requires external sender):")
        ns.Util_Print("URL: " .. (webhookUrl or "not set"))
        ns.DB_Log("DISCORD", "Webhook prepared: " .. (payload.content or ""))
    end

    return true
end

---------------------------------------------------------------------------
-- Encode Payload to JSON-like Format
---------------------------------------------------------------------------
function Discord:EncodePayload(payload)
    -- Simple JSON encoder (WoW doesn't have native JSON)
    local parts = {}

    if payload.content then
        table.insert(parts, string.format('"content": "%s"', payload.content:gsub('"', '\\"')))
    end

    if payload.username then
        table.insert(parts, string.format('"username": "%s"', payload.username:gsub('"', '\\"')))
    end

    if payload.embeds and #payload.embeds > 0 then
        local embedParts = {}
        for _, embed in ipairs(payload.embeds) do
            local embedFields = {}

            if embed.title then
                table.insert(embedFields, string.format('"title": "%s"', embed.title:gsub('"', '\\"')))
            end
            if embed.description then
                table.insert(embedFields, string.format('"description": "%s"', embed.description:gsub('"', '\\"')))
            end
            if embed.color then
                table.insert(embedFields, string.format('"color": %d', embed.color))
            end

            if embed.fields and #embed.fields > 0 then
                local fieldParts = {}
                for _, field in ipairs(embed.fields) do
                    local fieldStr = string.format(
                        '{"name": "%s", "value": "%s", "inline": %s}',
                        field.name:gsub('"', '\\"'),
                        field.value:gsub('"', '\\"'),
                        field.inline and "true" or "false"
                    )
                    table.insert(fieldParts, fieldStr)
                end
                table.insert(embedFields, '"fields": [' .. table.concat(fieldParts, ', ') .. ']')
            end

            table.insert(embedParts, '{' .. table.concat(embedFields, ', ') .. '}')
        end
        table.insert(parts, '"embeds": [' .. table.concat(embedParts, ', ') .. ']')
    end

    return '{' .. table.concat(parts, ', ') .. '}'
end

---------------------------------------------------------------------------
-- Event Notifications
---------------------------------------------------------------------------

-- Recruit Joined
function Discord:NotifyRecruitJoined(contactKey, contact)
    if not ns.db or not ns.db.profile or not ns.db.profile.discordEnableRecruitJoined then
        return
    end

    local webhookUrl = ns.db.profile.discordWebhookUrl
    if not webhookUrl or webhookUrl == "" then return end

    local playerName = contactKey
    local classIcon = "⚔️"
    if contact and contact.classFile then
        local classIcons = {
            WARRIOR = "⚔️",
            PALADIN = "🛡️",
            HUNTER = "🏹",
            ROGUE = "🗡️",
            PRIEST = "✨",
            DEATHKNIGHT = "💀",
            SHAMAN = "⚡",
            MAGE = "🔮",
            WARLOCK = "😈",
            MONK = "🥋",
            DRUID = "🌿",
            DEMONHUNTER = "😈",
            EVOKER = "🐉",
        }
        classIcon = classIcons[contact.classFile] or "⚔️"
    end

    local payload = {
        username = "CelestialRecruiter",
        embeds = {
            {
                title = "🎉 Nouvelle Recrue!",
                description = string.format("%s **%s** a rejoint la guilde!", classIcon, playerName),
                color = 5814783,  -- Gold
                fields = {
                    {
                        name = "Niveau",
                        value = contact and tostring(contact.level) or "?",
                        inline = true
                    },
                    {
                        name = "Classe",
                        value = contact and (contact.classLabel or contact.classFile) or "?",
                        inline = true
                    },
                    {
                        name = "Source",
                        value = contact and (contact.source or "scanner") or "scanner",
                        inline = true
                    }
                }
            }
        }
    }

    sendWebhook(webhookUrl, payload)
end

-- Auto-Recruiter Session Complete
function Discord:NotifyAutoRecruiterComplete(stats)
    if not ns.db or not ns.db.profile or not ns.db.profile.discordEnableAutoRecruiter then
        return
    end

    local webhookUrl = ns.db.profile.discordWebhookUrl
    if not webhookUrl or webhookUrl == "" then return end

    local payload = {
        username = "CelestialRecruiter",
        embeds = {
            {
                title = "🤖 Session Auto-Recrutement Terminée",
                description = "Statistiques de la session",
                color = 3447003,  -- Blue
                fields = {
                    {
                        name = "Traités",
                        value = tostring(stats.processed or 0),
                        inline = true
                    },
                    {
                        name = "Contactés",
                        value = tostring(stats.contacted or 0),
                        inline = true
                    },
                    {
                        name = "Invités",
                        value = tostring(stats.invited or 0),
                        inline = true
                    },
                    {
                        name = "Ignorés",
                        value = tostring(stats.skipped or 0),
                        inline = true
                    },
                    {
                        name = "Erreurs",
                        value = tostring(stats.errors or 0),
                        inline = true
                    }
                }
            }
        }
    }

    sendWebhook(webhookUrl, payload)
end

-- Daily Summary
function Discord:NotifyDailySummary()
    if not ns.db or not ns.db.profile or not ns.db.profile.discordEnableDailySummary then
        return
    end

    local webhookUrl = ns.db.profile.discordWebhookUrl
    if not webhookUrl or webhookUrl == "" then return end

    if not ns.Statistics then return end

    local today = date("%Y-%m-%d")
    local history = ns.Statistics:GetDailyHistory()
    local todayData = history[today]

    if not todayData then return end

    local payload = {
        username = "CelestialRecruiter",
        embeds = {
            {
                title = "📊 Résumé Quotidien",
                description = "Statistiques du " .. today,
                color = 10181046,  -- Purple
                fields = {
                    {
                        name = "Scans",
                        value = tostring(todayData.scans or 0),
                        inline = true
                    },
                    {
                        name = "Joueurs Trouvés",
                        value = tostring(todayData.found or 0),
                        inline = true
                    },
                    {
                        name = "Contactés",
                        value = tostring(todayData.contacted or 0),
                        inline = true
                    },
                    {
                        name = "Invités",
                        value = tostring(todayData.invited or 0),
                        inline = true
                    },
                    {
                        name = "Recrues",
                        value = tostring(todayData.joined or 0),
                        inline = true
                    }
                }
            }
        }
    }

    sendWebhook(webhookUrl, payload)
end

-- Limit Reached Alert
function Discord:NotifyLimitReached(limitType, current, max)
    if not ns.db or not ns.db.profile or not ns.db.profile.discordEnableAlerts then
        return
    end

    local webhookUrl = ns.db.profile.discordWebhookUrl
    if not webhookUrl or webhookUrl == "" then return end

    local payload = {
        username = "CelestialRecruiter",
        embeds = {
            {
                title = "⚠️ Limite Atteinte",
                description = string.format("**%s**: %d/%d", limitType, current, max),
                color = 15158332,  -- Red
            }
        }
    }

    sendWebhook(webhookUrl, payload)
end

---------------------------------------------------------------------------
-- Test Webhook
---------------------------------------------------------------------------
function Discord:TestWebhook(webhookUrl)
    local payload = {
        username = "CelestialRecruiter",
        content = "✅ Test de webhook réussi! CelestialRecruiter est connecté à Discord."
    }

    local success, err = sendWebhook(webhookUrl, payload)
    if success then
        ns.Util_Print("Webhook Discord testé (données préparées)")
        ns.Notifications_Info("Webhook Test", "Payload préparé - Consultez les logs")
    else
        ns.Util_Print("Erreur webhook: " .. tostring(err))
        ns.Notifications_Error("Webhook Erreur", tostring(err))
    end

    return success, err
end

---------------------------------------------------------------------------
-- Initialize Discord Settings
---------------------------------------------------------------------------
function Discord:Init()
    -- Add default settings if not present
    if ns.db and ns.db.profile then
        if ns.db.profile.discordWebhookUrl == nil then
            ns.db.profile.discordWebhookUrl = ""
        end
        if ns.db.profile.discordEnableRecruitJoined == nil then
            ns.db.profile.discordEnableRecruitJoined = true
        end
        if ns.db.profile.discordEnableAutoRecruiter == nil then
            ns.db.profile.discordEnableAutoRecruiter = true
        end
        if ns.db.profile.discordEnableDailySummary == nil then
            ns.db.profile.discordEnableDailySummary = false
        end
        if ns.db.profile.discordEnableAlerts == nil then
            ns.db.profile.discordEnableAlerts = true
        end
    end
end
