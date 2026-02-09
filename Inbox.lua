local _, ns = ...

local function containsKeyword(msg)
  msg = ns.Util_Lower(msg or "")
  for _, k in ipairs(ns.db.profile.keywords or {}) do
    k = ns.Util_Lower(ns.Util_Trim(k))
    if k ~= "" and msg:find(k, 1, true) then
      return true, k
    end
  end
  return false, nil
end

local function hasInviteOptIn(msg)
  local inv = ns.Util_Lower(ns.Util_Trim(ns.db.profile.inviteKeyword or "!invite"))
  if inv == "" then
    return false
  end
  return ns.Util_Lower(msg or ""):find(inv, 1, true) ~= nil
end

function ns.Inbox_Init()
  ns.CR:RegisterEvent("CHAT_MSG_WHISPER", function(_, msg, author)
    if not msg or not author then return end

    local matchedAny, matched = containsKeyword(msg)
    local matchedOptIn = hasInviteOptIn(msg)
    if not matchedAny and not matchedOptIn then return end

    local key = ns.Util_Key(author)
    if not key or ns.DB_IsBlacklisted(key) then return end

    local now = ns.Util_Now()
    local existing = ns.DB_GetContact(key)
    local wasIgnored = existing and existing.status == "ignored" and (existing.ignoredUntil or 0) > now

    local patch = {
      name = key,
      lastWhisperIn = now,
    }
    if not wasIgnored or matchedOptIn then
      patch.status = "new"
    end
    if matchedOptIn then
      patch.optedIn = true
      patch.lastOptInAt = now
    end

    ns.DB_UpsertContact(key, patch)
    ns.DB_Log("IN", "Whisper recu de " .. key .. " (match: " .. tostring(matched or ns.db.profile.inviteKeyword) .. ")")

    if wasIgnored and not matchedOptIn then
      ns.DB_Log("SKIP", "Contact ignore non ajoute en file: " .. key)
      ns.UI_Refresh()
      return
    end

    ns.DB_Log("IN", "Ajout manuel requis dans la liste d'attente: " .. key)

    ns.UI_Refresh()
  end)
end
