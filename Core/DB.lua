local _, ns = ...

local DEFAULTS = {
  profile = {
    guildName = "",
    discord = "",
    raidDays = "",
    goal = "",
    keywords = { "guilde", "guild", "recrute", "recrutement", "raid", "roster", "mythique" },
    inviteKeywordOnly = true,
    inviteKeyword = "!invite",

    cooldownInvite = 300,
    cooldownWhisper = 180,
    maxActionsPerMinute = 8,
    maxInvitesPerHour = 10,
    maxWhispersPerHour = 20,

    respectAFK = true,
    respectDND = true,
    afkDndHoldSeconds = 900,
    blockInInstance = true,

    logLimit = 300,

    scanLevelMin = 10,
    scanLevelMax = 80,
    scanLevelSlice = 5,
    scanWhoDelaySeconds = 6,
    scanWhoTimeoutSeconds = 8,
    scanIncludeGuilded = false,
    scanIncludeCrossRealm = true,
    scanUseClassFilters = false,
    scannerBypassOptIn = true,
    scanAutoEnabled = false,
    scanAutoDelayMinutes = 5,
    customTemplates = {},
    showMinimapButton = true,
    minimapAngle = 220,
  },
  char = {
    leaderboard = {
      daily = {},
      personalBests = {
        bestDayRecruits = 0,
        bestDayDate = "",
        bestDayContacts = 0,
        bestDayContactsDate = "",
        bestWeekRecruits = 0,
        bestWeekDate = "",
        longestStreak = 0,
        fastestJoinMinutes = 0,
      },
      currentTier = "none",
      totalAllTime = {
        contacted = 0,
        invited = 0,
        joined = 0,
        whispers = 0,
      },
    },
  },
  global = {
    contacts = {},   -- [key] = {...}
    queue = {},      -- array of keys
    blacklist = {},  -- [key]=true
    logs = {},       -- ring buffer
  }
}

local function deepCopy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do
    out[k] = deepCopy(v)
  end
  return out
end

local function ensureDefaults(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      dst[k] = deepCopy(v)
    elseif type(v) == "table" and type(dst[k]) == "table" then
      ensureDefaults(dst[k], v)
    end
  end
end

local function normalizeContact(c, key)
  local now = ns.Util_Now()
  c.key = key
  c.name = c.name or key
  c.status = c.status or "new" -- new/contacted/invited/joined/ignored
  c.firstSeen = tonumber(c.firstSeen) or now
  c.lastSeen = tonumber(c.lastSeen) or now
  c.lastWhisperIn = tonumber(c.lastWhisperIn) or 0
  c.lastWhisperOut = tonumber(c.lastWhisperOut) or 0
  c.lastInviteAt = tonumber(c.lastInviteAt) or 0
  c.lastAFKAt = tonumber(c.lastAFKAt) or 0
  c.lastDNDAt = tonumber(c.lastDNDAt) or 0
  c.lastOptInAt = tonumber(c.lastOptInAt) or 0
  c.ignoredUntil = tonumber(c.ignoredUntil) or 0
  c.optedIn = c.optedIn and true or false
  c.tags = type(c.tags) == "table" and c.tags or {}
  c.notes = tostring(c.notes or "")
  return c
end

local function migrateStorage()
  ensureDefaults(ns.db.profile, DEFAULTS.profile)
  ensureDefaults(ns.db.global, DEFAULTS.global)

  local contacts = ns.db.global.contacts
  local rebuilt = {}
  for rawKey, c in pairs(contacts) do
    local key = ns.Util_Key(rawKey)
    if key and type(c) == "table" then
      rebuilt[key] = normalizeContact(c, key)
    end
  end
  ns.db.global.contacts = rebuilt

  local rebuiltBlacklist = {}
  for rawKey, val in pairs(ns.db.global.blacklist or {}) do
    local key = ns.Util_Key(rawKey)
    if key and val then
      rebuiltBlacklist[key] = true
    end
  end
  ns.db.global.blacklist = rebuiltBlacklist

  local newQueue = {}
  local seen = {}
  for _, rawKey in ipairs(ns.db.global.queue or {}) do
    local key = ns.Util_Key(rawKey)
    if key and not seen[key] and rebuilt[key] and not rebuiltBlacklist[key] then
      seen[key] = true
      table.insert(newQueue, key)
    end
  end
  ns.db.global.queue = newQueue
end

-- O(1) queue membership set (rebuilt on add/remove for consistency)
local queueSet = {}

local function rebuildQueueSet()
  queueSet = {}
  if ns.db and ns.db.global then
    for _, k in ipairs(ns.db.global.queue) do
      queueSet[k] = true
    end
  end
end

-- Expose queueSet for O(1) lookup (avoids rebuilding in UI)
function ns.DB_IsQueued(key)
  return queueSet[key] == true
end

-- Fast queue count (avoids iterating + filtering in DB_QueueList)
function ns.DB_QueueCount()
  local n = 0
  for _ in pairs(queueSet) do n = n + 1 end
  return n
end

function ns.DB_Init()
  ns.db = LibStub("AceDB-3.0"):New("CelestialRecruiterDB", DEFAULTS, true)
  migrateStorage()
  rebuildQueueSet()

  if ns.db.profile.guildName == "" then
    local g = GetGuildInfo("player")
    if g then ns.db.profile.guildName = g end
  end
end

function ns.DB_Reset()
  ns.db:ResetDB("Default")
  migrateStorage()
  rebuildQueueSet()
  if ns.db.profile.guildName == "" then
    local g = GetGuildInfo("player")
    if g then ns.db.profile.guildName = g end
  end
end

function ns.DB_GetContact(key)
  key = ns.Util_Key(key)
  if not key then return nil end
  return ns.db.global.contacts[key]
end

function ns.DB_UpsertContact(key, patch)
  key = ns.Util_Key(key)
  if not key then return nil end

  local c = ns.db.global.contacts[key]
  if not c then
    c = normalizeContact({}, key)
    ns.db.global.contacts[key] = c
  else
    normalizeContact(c, key)
  end

  c.lastSeen = ns.Util_Now()
  if patch then
    for k, v in pairs(patch) do
      c[k] = v
    end
    normalizeContact(c, key)
  end
  return c
end

function ns.DB_IsBlacklisted(key)
  key = ns.Util_Key(key)
  return key and ns.db.global.blacklist[key] == true
end

function ns.DB_SetBlacklisted(key, val)
  key = ns.Util_Key(key)
  if not key then return end
  ns.db.global.blacklist[key] = val and true or nil
  if val then
    ns.DB_QueueRemove(key)
    ns.DB_UpsertContact(key, { status = "ignored", ignoredUntil = ns.Util_Now() + (365 * 24 * 3600) })

    -- Discord notification
    if ns.DiscordQueue and ns.DiscordQueue.NotifyBlacklisted then
      ns.DiscordQueue:NotifyBlacklisted(key, "Added to blacklist")
    end
  end
end

function ns.DB_Log(kind, text)
  local logs = ns.db.global.logs
  table.insert(logs, 1, { t = ns.Util_Now(), kind = tostring(kind or "LOG"), text = tostring(text or "") })
  local limit = ns.Util_ToNumber(ns.db.profile.logLimit, 300, 50, 1000)
  while #logs > limit do
    table.remove(logs, #logs)
  end
end

function ns.DB_ClearLogs()
  ns.db.global.logs = {}
end

function ns.DB_QueueAdd(key)
  key = ns.Util_Key(key)
  if not key then return false end
  if ns.DB_IsBlacklisted(key) then return false end
  local c = ns.db.global.contacts[key]
  if c and c.status == "ignored" and (c.ignoredUntil or 0) > ns.Util_Now() then
    return false
  end
  -- 7-day invite cooldown: don't re-queue recently invited players
  if c and (c.lastInviteAt or 0) > 0 then
    if (ns.Util_Now() - c.lastInviteAt) < (7 * 24 * 3600) then
      return false
    end
  end
  if queueSet[key] then return false end
  table.insert(ns.db.global.queue, key)
  queueSet[key] = true
  if ns.sessionStats then ns.sessionStats.queueAdded = ns.sessionStats.queueAdded + 1 end

  -- Discord notification
  if ns.DiscordQueue and ns.DiscordQueue.NotifyQueueAdded then
    ns.DiscordQueue:NotifyQueueAdded(key)
  end

  return true
end

function ns.DB_QueueRemove(key)
  key = ns.Util_Key(key)
  if not key then return false end
  if not queueSet[key] then return false end
  for i, k in ipairs(ns.db.global.queue) do
    if k == key then
      table.remove(ns.db.global.queue, i)
      queueSet[key] = nil
      return true
    end
  end
  queueSet[key] = nil
  return false
end

function ns.DB_QueueList()
  local out = {}
  local seen = {}
  local now = ns.Util_Now()
  for _, k in ipairs(ns.db.global.queue) do
    local c = ns.db.global.contacts[k]
    local ignored = c and c.status == "ignored" and (c.ignoredUntil or 0) > now
    if not seen[k] and c and not ignored and not ns.DB_IsBlacklisted(k) then
      seen[k] = true
      table.insert(out, k)
    end
  end
  return out
end

function ns.DB_ListContactsForInbox()
  local out = {}
  for key, c in pairs(ns.db.global.contacts) do
    if c then
      table.insert(out, key)
    end
  end
  ns.Util_SortKeysByRecent(out, function(key)
    local c = ns.db.global.contacts[key]
    return c and c.lastWhisperIn or 0
  end)
  return out
end

---------------------------------------------------------------------------
-- Tags System
---------------------------------------------------------------------------

function ns.DB_AddTag(key, tag)
  key = ns.Util_Key(key)
  tag = ns.Util_Trim(tag)
  if not key or tag == "" then return false end

  local c = ns.DB_UpsertContact(key)
  if not c.tags then c.tags = {} end

  -- Check if tag already exists
  for _, t in ipairs(c.tags) do
    if t == tag then return false end
  end

  table.insert(c.tags, tag)
  return true
end

function ns.DB_RemoveTag(key, tag)
  key = ns.Util_Key(key)
  tag = ns.Util_Trim(tag)
  if not key or tag == "" then return false end

  local c = ns.DB_GetContact(key)
  if not c or not c.tags then return false end

  for i, t in ipairs(c.tags) do
    if t == tag then
      table.remove(c.tags, i)
      return true
    end
  end
  return false
end

function ns.DB_HasTag(key, tag)
  key = ns.Util_Key(key)
  tag = ns.Util_Trim(tag)
  if not key or tag == "" then return false end

  local c = ns.DB_GetContact(key)
  if not c or not c.tags then return false end

  for _, t in ipairs(c.tags) do
    if t == tag then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- Message History
---------------------------------------------------------------------------
local MSG_LIMIT = 50  -- max messages per contact

function ns.DB_AddMessage(key, dir, text)
  key = ns.Util_Key(key)
  if not key or not text or text == "" then return end
  local c = ns.DB_GetContact(key)
  if not c then return end
  if not c.messages then c.messages = {} end
  local msgs = c.messages
  msgs[#msgs + 1] = { t = ns.Util_Now(), d = dir, m = tostring(text) }
  -- Trim oldest if over limit
  while #msgs > MSG_LIMIT do
    table.remove(msgs, 1)
  end
end

function ns.DB_GetMessages(key)
  key = ns.Util_Key(key)
  if not key then return {} end
  local c = ns.DB_GetContact(key)
  if not c or not c.messages then return {} end
  return c.messages
end

function ns.DB_GetAllTags()
  local tags = {}
  local seen = {}
  for _, c in pairs(ns.db.global.contacts) do
    if c and c.tags then
      for _, tag in ipairs(c.tags) do
        if not seen[tag] then
          seen[tag] = true
          table.insert(tags, tag)
        end
      end
    end
  end
  table.sort(tags)
  return tags
end
