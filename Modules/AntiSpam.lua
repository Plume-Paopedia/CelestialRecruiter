local _, ns = ...
local initialized = false

local history = {
  all = {},
  whisper = {},
  invite = {},
}

local function pruneWindow(list, windowSeconds, now)
  while #list > 0 and (now - list[1]) > windowSeconds do
    table.remove(list, 1)
  end
end

local function wouldExceed(list, limit, windowSeconds, now)
  limit = ns.Util_ToNumber(limit, 0, 0, 10000)
  if limit <= 0 then return false end
  pruneWindow(list, windowSeconds, now)
  return #list >= limit
end

local function trackAction(kind)
  local now = ns.Util_Now()
  table.insert(history.all, now)
  table.insert(history[kind], now)
end

local function isSelfTarget(key)
  local player = UnitName("player")
  if not player then return false end

  local me = ns.Util_Key(player)
  if key == me then return true end

  local realm = GetRealmName()
  if realm and realm ~= "" then
    local meRealm = ns.Util_Key(player .. "-" .. realm)
    if key == meRealm then return true end
  end
  return false
end

local function isBlockedByContext()
  if not ns.db.profile.blockInInstance then return false end
  local inInstance, instanceType = IsInInstance()
  if inInstance and instanceType and instanceType ~= "none" then
    return true, "en instance (" .. instanceType .. ")"
  end
  return false
end

local function canPassRate(kind)
  local now = ns.Util_Now()
  local p = ns.db.profile

  if wouldExceed(history.all, p.maxActionsPerMinute, 60, now) then
    return false, "limite (minute)"
  end

  if kind == "whisper" and wouldExceed(history.whisper, p.maxWhispersPerHour, 3600, now) then
    return false, "limite (chuchotements/heure)"
  end

  if kind == "invite" and wouldExceed(history.invite, p.maxInvitesPerHour, 3600, now) then
    return false, "limite (invitations/heure)"
  end

  return true
end

local function canPassAfkDnd(c)
  local holdSeconds = ns.Util_ToNumber(ns.db.profile.afkDndHoldSeconds, 900, 0, 86400)
  if holdSeconds <= 0 then return true end

  local now = ns.Util_Now()
  if ns.db.profile.respectAFK and (now - (c.lastAFKAt or 0)) < holdSeconds then
    return false, "cible AFK recemment"
  end
  if ns.db.profile.respectDND and (now - (c.lastDNDAt or 0)) < holdSeconds then
    return false, "cible NPD recemment"
  end
  return true
end

local function canContactBase(key, kind)
  key = ns.Util_Key(key)
  if not key then
    return false, "cible invalide"
  end
  if isSelfTarget(key) then
    return false, "auto-ciblage"
  end
  if ns.DB_IsBlacklisted(key) then
    return false, "liste noire"
  end

  local blocked, reason = isBlockedByContext()
  if blocked then
    return false, reason
  end

  local c = ns.DB_UpsertContact(key)
  local now = ns.Util_Now()
  if (c.ignoredUntil or 0) > now then
    return false, "ignore"
  end

  local cd = ns.Util_ToNumber(kind == "invite" and ns.db.profile.cooldownInvite or ns.db.profile.cooldownWhisper, kind == "invite" and 300 or 180, 0, 86400)
  local last = kind == "invite" and (c.lastInviteAt or 0) or (c.lastWhisperOut or 0)
  if (now - last) < cd then
    return false, "temps de recharge"
  end

  if kind == "whisper" then
    local okAfk, whyAfk = canPassAfkDnd(c)
    if not okAfk then
      return false, whyAfk
    end
  end

  local okRate, whyRate = canPassRate(kind)
  if not okRate then
    return false, whyRate
  end

  return true
end

function ns.AntiSpam_Init()
  if initialized then return end
  initialized = true

  ns.CR:RegisterEvent("CHAT_MSG_AFK", function(_, msg, author)
    local key = ns.Util_Key(author)
    if not key then return end
    ns.DB_UpsertContact(key, { lastAFKAt = ns.Util_Now() })
    ns.DB_Log("AFK", "Reponse AFK detectee: " .. key .. " -> " .. tostring(msg or ""))
  end)

  ns.CR:RegisterEvent("CHAT_MSG_DND", function(_, msg, author)
    local key = ns.Util_Key(author)
    if not key then return end
    ns.DB_UpsertContact(key, { lastDNDAt = ns.Util_Now() })
    ns.DB_Log("DND", "Reponse DND detectee: " .. key .. " -> " .. tostring(msg or ""))
  end)
end

function ns.AntiSpam_CanWhisper(key)
  return canContactBase(key, "whisper")
end

function ns.AntiSpam_MarkWhisper(key)
  trackAction("whisper")
  ns.DB_UpsertContact(key, { lastWhisperOut = ns.Util_Now() })
end

function ns.AntiSpam_CanInvite(key)
  return canContactBase(key, "invite")
end

function ns.AntiSpam_MarkInvite(key)
  trackAction("invite")
  ns.DB_UpsertContact(key, { lastInviteAt = ns.Util_Now() })
end
