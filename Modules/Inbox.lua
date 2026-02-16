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

    local isNewContact = not existing
    ns.DB_UpsertContact(key, patch)
    ns.DB_AddMessage(key, "in", msg)
    ns.DB_Log("IN", "Whisper recu de " .. key .. " (match: " .. tostring(matched or ns.db.profile.inviteKeyword) .. ")")

    -- Discord notification for incoming whisper
    if ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
      ns.DiscordQueue:QueueEvent("whisper_received", {
        title = matchedOptIn and "Opt-in recu!" or "Whisper entrant",
        description = string.format("**%s** a envoye un whisper", key),
        fields = {
          { name = "Message", value = msg:sub(1, 100), inline = false },
          { name = "Opt-in", value = matchedOptIn and "Oui" or "Non", inline = true },
        }
      })
      -- Auto-flush: send whisper notification immediately
      if ns.DiscordQueue.ScheduleAutoFlush then
        ns.DiscordQueue:ScheduleAutoFlush()
      end
    end

    -- Green burst particle effect for new contacts
    if isNewContact then
        local PS = ns.ParticleSystem
        local mainFrame = ns._mainFrame
        if PS and PS.PlayNewContactEffect and mainFrame and mainFrame:IsVisible() then
            PS:PlayNewContactEffect(mainFrame)
        end
    end

    if wasIgnored and not matchedOptIn then
      ns.DB_Log("SKIP", "Contact ignore non ajoute en file: " .. key)
      ns.UI_Refresh()
      return
    end

    -- Record A/B Testing reply (if contact was previously messaged)
    local contact = ns.DB_GetContact(key)
    if contact and contact.lastTemplate and ns.ABTesting and ns.ABTesting.RecordReply then
      ns.ABTesting:RecordReply(contact.lastTemplate)
    end

    -- Record Campaign reply
    if contact and contact._campaignId and ns.Campaigns and ns.Campaigns.RecordReply then
      ns.Campaigns:RecordReply(contact._campaignId, key)
    end

    -- Record Goals activity
    if ns.Goals and ns.Goals.RecordActivity then
      ns.Goals:RecordActivity("reply")
    end

    ns.DB_Log("IN", "Ajout manuel requis dans la liste d'attente: " .. key)

    -- Mode Nuit: AI Conversation engine handles incoming whispers
    if ns.AIConversation and ns.SleepRecruiter and ns.SleepRecruiter:IsActive() then
      ns.AIConversation:HandleIncoming(key, msg)
    end

    ns.UI_Refresh()
  end)

  -- Capture outgoing whispers for conversation history
  ns.CR:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(_, msg, recipient)
    if not msg or not recipient then return end
    local key = ns.Util_Key(recipient)
    if not key then return end
    local c = ns.DB_GetContact(key)
    if c then
      ns.DB_AddMessage(key, "out", msg)
    end
  end)
end
