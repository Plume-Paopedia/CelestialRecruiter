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

  local msg = ns.Templates_Render(key, tplId)
  if msg == "" then
    ns.Util_Print("Message bloque (modele vide)")
    return false, "empty_template"
  end

  SendChatMessage(msg, "WHISPER", nil, key)

  ns.AntiSpam_MarkWhisper(key)
  ns.DB_UpsertContact(key, { status = "contacted" })
  ns.DB_Log("OUT", "Message envoye a " .. key)
  if ns.sessionStats then ns.sessionStats.whispersSent = ns.sessionStats.whispersSent + 1 end
  ns.UI_Refresh()
  return true
end

function ns.Queue_Recruit(key, tplId)
  local msgOk, msgWhy = ns.Queue_Whisper(key, tplId)
  local invOk, invWhy = ns.Queue_Invite(key)
  if not msgOk and not invOk then
    return false, msgWhy or invWhy
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
  ns.DB_UpsertContact(key, { status = "invited" })
  ns.DB_Log("INV", "Invitation guilde -> " .. key)
  if ns.sessionStats then ns.sessionStats.invitesSent = ns.sessionStats.invitesSent + 1 end
  ns.UI_Refresh()
  return true
end

