local _, ns = ...

local function hasExplicitOptIn(c)
  if not ns.db.profile.inviteKeywordOnly then
    return true
  end
  if c and c.optedIn == true then
    return true
  end
  if c and c.source == "scanner" and ns.db.profile.scannerBypassOptIn then
    return true
  end
  return false
end

local function sendGuildInvite(key)
  if C_GuildInfo and C_GuildInfo.Invite then
    return pcall(C_GuildInfo.Invite, key)
  end
  if GuildInvite then
    return pcall(GuildInvite, key)
  end
  return false
end

function ns.Queue_Init() end

function ns.Queue_Whisper(key, tplId)
  key = ns.Util_EnsurePlayerRealm(key)
  if not key then
    ns.Util_Print("Message bloque (cible invalide)")
    return false, "invalid_target"
  end

  local c = ns.DB_GetContact(key)
  if not hasExplicitOptIn(c) then
    ns.Util_Print("Message bloque (pas d'opt-in)")
    ns.DB_Log("SKIP", "Message bloque, pas d'opt-in: " .. key)
    return false, "no_opt_in"
  end

  local can, why = ns.AntiSpam_CanWhisper(key)
  if not can then
    ns.Util_Print("Message bloque (" .. tostring(why) .. ")")
    ns.DB_Log("SKIP", "Message bloque pour " .. key .. ": " .. tostring(why))
    return false, tostring(why)
  end

  -- A/B Testing: pick template variant if a test is active
  local actualTplId = tplId
  if ns.ABTesting and ns.ABTesting.PickTemplate then
    actualTplId = ns.ABTesting:PickTemplate(tplId)
  end
  -- Ensure actualTplId is never nil (fallback to original tplId or "default")
  actualTplId = actualTplId or tplId or "default"

  -- AI message fallback: use pre-generated AI message during Mode Nuit
  local msg
  if ns.SleepRecruiter and ns.SleepRecruiter:IsActive() and ns.AIConversation then
    msg = ns.AIConversation:GetAIMessage(key)
  end
  if not msg or msg == "" then
    msg = ns.Templates_Render(key, actualTplId)
  end
  if not msg or msg == "" then
    ns.Util_Print("Message bloque (modele vide)")
    return false, "empty_template"
  end

  local sendOk = pcall(SendChatMessage, msg, "WHISPER", nil, key)
  if not sendOk then
    ns.Util_Print("Message bloque (SendChatMessage protege)")
    ns.DB_Log("ERR", "SendChatMessage bloque pour: " .. key)
    return false, "send_blocked"
  end

  ns.AntiSpam_MarkWhisper(key)
  ns.DB_UpsertContact(key, { status = "contacted", lastTemplate = actualTplId, recruitedBy = UnitName("player") })
  ns.DB_Log("OUT", "Message envoye a " .. key .. " (tpl: " .. tostring(actualTplId) .. ")")
  if ns.sessionStats then ns.sessionStats.whispersSent = ns.sessionStats.whispersSent + 1 end

  -- Discord notification + auto-flush
  if ns.DiscordQueue and ns.DiscordQueue.NotifyWhisperSent then
    ns.DiscordQueue:NotifyWhisperSent(key, actualTplId)
    if ns.DiscordQueue.ScheduleAutoFlush then
      ns.DiscordQueue:ScheduleAutoFlush()
    end
  end

  -- Record A/B Testing
  if ns.ABTesting and ns.ABTesting.RecordSent then
    ns.ABTesting:RecordSent(actualTplId)
  end

  -- Record statistics
  if ns.Statistics and ns.Statistics.RecordEvent then
    ns.Statistics:RecordEvent("contacted", {template = actualTplId})
  end

  -- Record Goals activity
  if ns.Goals and ns.Goals.RecordActivity then
    ns.Goals:RecordActivity("contact")
  end

  -- Record Leaderboard whisper + contact
  if ns.Leaderboard and ns.Leaderboard.RecordDaily then
    ns.Leaderboard:RecordDaily("whisper")
    ns.Leaderboard:RecordDaily("contact")
  end

  -- Show success notification (unless silenced by Queue_Recruit)
  if not ns._silentNotifications and ns.Notifications_Success then
    ns.Notifications_Success("Message envoyé", key)
  end

  ns.UI_Refresh()
  return true
end

function ns.Queue_Recruit(key, tplId)
  -- Suppress individual notifications during combined recruit
  ns._silentNotifications = true
  local msgOk, msgWhy = ns.Queue_Whisper(key, tplId)

  -- Skip guild invite if target already has a guild (it would fail anyway)
  local invOk, invWhy = false, "guilded"
  local c = ns.DB_GetContact(key)
  if not c or not c.guild or c.guild == "" then
    invOk, invWhy = ns.Queue_Invite(key)
  end
  ns._silentNotifications = false

  if not msgOk and not invOk then
    return false, msgWhy or invWhy
  end

  -- Show one combined notification
  if ns.Notifications_Success then
    local parts = {}
    if msgOk then parts[#parts + 1] = "Message" end
    if invOk then parts[#parts + 1] = "Invitation" end
    ns.Notifications_Success(table.concat(parts, " + "), key)
  end
  return true
end

function ns.Queue_Invite(key)
  key = ns.Util_EnsurePlayerRealm(key)
  if not key then
    ns.Util_Print("Invitation bloquee (cible invalide)")
    return false, "invalid_target"
  end

  local c = ns.DB_GetContact(key)
  if not hasExplicitOptIn(c) then
    ns.Util_Print("Invitation bloquee (pas d'opt-in)")
    ns.DB_Log("SKIP", "Invitation bloquee, pas d'opt-in: " .. key)
    return false, "no_opt_in"
  end

  if not IsInGuild() then
    ns.Util_Print("Invitation bloquee (tu n'es pas en guilde)")
    ns.DB_Log("SKIP", "Invitation bloquee, pas en guilde: " .. key)
    return false, "not_in_guild"
  end

  if CanGuildInvite and not CanGuildInvite() then
    ns.Util_Print("Invitation bloquee (droit guilde manquant)")
    ns.DB_Log("SKIP", "Invitation bloquee, droit manquant: " .. key)
    return false, "missing_permission"
  end

  local can, why = ns.AntiSpam_CanInvite(key)
  if not can then
    ns.Util_Print("Invitation bloquee (" .. tostring(why) .. ")")
    ns.DB_Log("SKIP", "Invitation bloquee pour " .. key .. ": " .. tostring(why))
    return false, tostring(why)
  end

  local ok = sendGuildInvite(key)
  if not ok then
    ns.Util_Print("Invitation bloquee (clic materiel Blizzard requis)")
    ns.DB_Log("ERR", "API invitation bloquee (clic materiel requis?): " .. key)
    return false, "invite_api_blocked"
  end

  ns.AntiSpam_MarkInvite(key)
  ns.DB_UpsertContact(key, { status = "invited", recruitedBy = UnitName("player") })
  ns.DB_Log("INV", "Invitation guilde -> " .. key)
  if ns.sessionStats then ns.sessionStats.invitesSent = ns.sessionStats.invitesSent + 1 end

  -- Discord notification + auto-flush
  if ns.DiscordQueue and ns.DiscordQueue.NotifyInviteSent then
    ns.DiscordQueue:NotifyInviteSent(key)
    if ns.DiscordQueue.ScheduleAutoFlush then
      ns.DiscordQueue:ScheduleAutoFlush()
    end
  end

  -- Record statistics
  if ns.Statistics and ns.Statistics.RecordEvent then
    ns.Statistics:RecordEvent("invited")
  end

  -- Record Goals activity
  if ns.Goals and ns.Goals.RecordActivity then
    ns.Goals:RecordActivity("invite")
  end

  -- Record Leaderboard invite
  if ns.Leaderboard and ns.Leaderboard.RecordDaily then
    ns.Leaderboard:RecordDaily("invite")
  end

  -- Show success notification (unless silenced by Queue_Recruit)
  if not ns._silentNotifications and ns.Notifications_Success then
    ns.Notifications_Success("Invitation envoyée", key)
  end

  ns.UI_Refresh()
  return true
end

