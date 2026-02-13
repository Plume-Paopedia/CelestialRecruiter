local _, ns = ...

local Scanner = {
  initialized = false,
  active = false,
  awaiting = false,

  currentQuery = nil,
  queries = {},
  querySent = 0,
  totalWhoRows = 0,
  lastResultAt = 0,
  lastWhoSent = 0,

  results = {}, -- [key] = record
  timeoutTimer = nil,
  cappedQueries = 0,
  totalQueries = 0,
  _dirty = true,
  _cachedRows = nil,
}

ns.Scanner = Scanner

local function cancelTimer(t)
  if t and t.Cancel then
    t:Cancel()
  end
  return nil
end

local function countMapKeys(map)
  local n = 0
  for _ in pairs(map or {}) do
    n = n + 1
  end
  return n
end

local function whoDelay()
  return ns.Util_ToNumber(ns.db.profile.scanWhoDelaySeconds, 6, 3, 30)
end

local function cooldownRemaining()
  local delay = whoDelay()
  local now = GetTime and GetTime() or 0
  if Scanner.lastWhoSent <= 0 then
    return 0
  end
  local remain = delay - (now - Scanner.lastWhoSent)
  if remain < 0 then
    remain = 0
  end
  return remain
end

local function buildClassFilters()
  local out = {}
  local seen = {}
  local numClasses = GetNumClasses and GetNumClasses() or 0
  if numClasses > 0 then
    for i = 1, numClasses do
      local name, _, _ = GetClassInfo(i)
      if name and name ~= "" and not seen[name] then
        seen[name] = true
        table.insert(out, name)
      end
    end
  else
    local src = LOCALIZED_CLASS_NAMES_MALE or {}
    for _, localizedName in pairs(src) do
      local name = ns.Util_Trim(localizedName)
      if name ~= "" and not seen[name] then
        seen[name] = true
        table.insert(out, name)
      end
    end
  end
  table.sort(out)
  return out
end

local WHO_CAP = 49

local function buildWhoQueries()
  local p = ns.db.profile
  local minLevel = ns.Util_ToNumber(p.scanLevelMin, 10, 1, 80)
  local maxLevel = ns.Util_ToNumber(p.scanLevelMax, 80, 1, 80)
  local slice = ns.Util_ToNumber(p.scanLevelSlice, 5, 1, 40)
  if minLevel > maxLevel then
    minLevel, maxLevel = maxLevel, minLevel
  end

  local classes = buildClassFilters()

  -- Build level ranges (highest first)
  local ranges = {}
  for level = minLevel, maxLevel, slice do
    local rangeEnd = math.min(level + slice - 1, maxLevel)
    table.insert(ranges, {level, rangeEnd})
  end

  -- Class-first: each class × each level range (high levels first)
  local queries = {}
  for _, className in ipairs(classes) do
    for i = #ranges, 1, -1 do
      local r = ranges[i]
      table.insert(queries, ('c-"%s" %d-%d'):format(className, r[1], r[2]))
    end
  end
  return queries
end

local function getNumWhoResults()
  if C_FriendList and C_FriendList.GetNumWhoResults then
    local n = C_FriendList.GetNumWhoResults()
    if type(n) == "number" then
      return n
    end
  end
  if GetNumWhoResults then
    local n = GetNumWhoResults()
    if type(n) == "number" then
      return n
    end
  end
  return 0
end

local function setWhoToUiEnabled(state)
  local flag = state and true or false
  if C_FriendList then
    local f = C_FriendList.SetWhoToUi or C_FriendList.SetWhoToUI
    if f then
      pcall(f, flag)
      return
    end
  end
  if SetWhoToUi then
    pcall(SetWhoToUi, flag)
    return
  end
  if SetWhoToUI then
    pcall(SetWhoToUI, flag and 1 or 0)
  end
end

local function sendWhoQuery(query)
  if C_FriendList and C_FriendList.SendWho then
    local origin = Enum and Enum.SocialWhoOrigin and Enum.SocialWhoOrigin.Social
    if origin ~= nil then
      return pcall(C_FriendList.SendWho, query, origin)
    end
    return pcall(C_FriendList.SendWho, query)
  end
  if SendWho then
    return pcall(SendWho, query)
  end
  return false
end

local function parseWhoInfo(index)
  if C_FriendList and C_FriendList.GetWhoInfo then
    local info = C_FriendList.GetWhoInfo(index)
    if type(info) == "table" then
      return info
    end
  end

  if GetWhoInfo then
    local name, guildName, level, raceStr, classStr, area, filename, gender = GetWhoInfo(index)
    if name and name ~= "" then
      return {
        fullName = name,
        name = name,
        fullGuildName = guildName,
        level = level,
        raceStr = raceStr,
        classStr = classStr,
        area = area,
        filename = filename,
        gender = gender,
      }
    end
  end

  return nil
end

local function buildPlayerRecord(info)
  local rawName = info.fullName or info.name
  if not rawName or rawName == "" then
    return nil
  end

  local inviteName = ns.Util_Key(rawName)
  if not inviteName or inviteName == "" then
    return nil
  end

  if not inviteName:find("-", 1, true) then
    local realmFromInfo = info.realmName or rawName:match("%-(.+)$") or GetRealmName()
    inviteName = ns.Util_EnsurePlayerRealm(inviteName, realmFromInfo)
  end
  if not inviteName then
    return nil
  end

  local myName = UnitName("player")
  local myFull = ns.Util_EnsurePlayerRealm(myName, GetRealmName())
  if myFull and inviteName == myFull then
    return nil
  end

  local guild = ns.Util_Trim(info.fullGuildName or info.guildName or "")
  if guild ~= "" and not ns.db.profile.scanIncludeGuilded then
    return nil
  end

  if ns.DB_IsBlacklisted(inviteName) then
    return nil
  end

  local isCrossRealm = not ns.Util_IsSameRealmPlayer(inviteName)
  if isCrossRealm and not ns.db.profile.scanIncludeCrossRealm then
    return nil
  end

  local now = ns.Util_Now()
  return {
    key = inviteName,
    inviteName = inviteName,
    name = inviteName,
    level = tonumber(info.level) or 0,
    classFile = info.filename or "",
    classLabel = info.classStr or info.filename or "?",
    race = info.raceStr or "",
    zone = info.area or "",
    guild = guild,
    crossRealm = isCrossRealm,
    firstSeen = now,
    lastSeen = now,
  }
end

local function mergeRecord(record)
  local existing = Scanner.results[record.key]
  if not existing then
    Scanner.results[record.key] = record
    return true, record
  end

  existing.name = record.name or existing.name
  existing.level = record.level or existing.level
  existing.classFile = record.classFile or existing.classFile
  existing.classLabel = record.classLabel or existing.classLabel
  existing.race = record.race or existing.race
  existing.zone = record.zone or existing.zone
  existing.guild = record.guild or existing.guild
  existing.crossRealm = record.crossRealm and true or false
  existing.lastSeen = record.lastSeen or existing.lastSeen
  return false, existing
end

local function queueIfUnguilded(rec)
  if not rec then
    return false
  end
  if ns.Util_Trim(rec.guild or "") ~= "" then
    return false
  end
  local patch = {
    name = rec.name,
    source = "scanner",
    classFile = rec.classFile or "",
    classLabel = rec.classLabel or "",
    level = rec.level or 0,
    race = rec.race or "",
    zone = rec.zone or "",
  }
  -- Don't reset status if the contact already has a meaningful one
  local existing = ns.DB_GetContact(rec.key)
  if not existing or existing.status == "new" or not existing.status then
    patch.status = "new"
  end
  ns.DB_UpsertContact(rec.key, patch)
  return ns.DB_QueueAdd(rec.key)
end

local function processWhoResults(completedQuery)
  local totalRows = getNumWhoResults()
  local addedPlayers = 0
  local addedQueue = 0

  Scanner._dirty = true
  Scanner._cachedRows = nil
  Scanner.totalWhoRows = Scanner.totalWhoRows + totalRows
  Scanner.lastResultAt = ns.Util_Now()

  for i = 1, totalRows do
    local info = parseWhoInfo(i)
    if info then
      local rec = buildPlayerRecord(info)
      if rec then
        local isNew, current = mergeRecord(rec)
        if isNew then
          addedPlayers = addedPlayers + 1
          if queueIfUnguilded(current) then
            addedQueue = addedQueue + 1
          end
        end
      end
    end
  end

  if totalRows >= WHO_CAP and completedQuery then
    Scanner.cappedQueries = Scanner.cappedQueries + 1
    ns.DB_Log("SCAN", ("Plafond /who (%d) sur %s"):format(totalRows, completedQuery))
  end

  if addedPlayers > 0 or addedQueue > 0 then
    ns.DB_Log("SCAN", ("Trouves: +%d | Ajoutes en file: +%d | Total liste: %d"):format(
      addedPlayers, addedQueue, countMapKeys(Scanner.results)
    ))
    if ns.sessionStats then
      ns.sessionStats.playersFound = ns.sessionStats.playersFound + addedPlayers
    end

    -- Record statistics
    if ns.Statistics and ns.Statistics.RecordEvent then
      ns.Statistics:RecordEvent("found", {count = addedPlayers})
    end
  end
end

local function finishScan(logLine)
  Scanner.active = false
  Scanner.awaiting = false
  Scanner.currentQuery = nil
  Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
  if logLine then
    ns.DB_Log("SCAN", logLine)
  end
  ns.UI_Refresh()
end

local function sendNextQuery()
  if not Scanner.active then
    return false, "scanner not active"
  end
  if Scanner.awaiting then
    return false, "waiting WHO result"
  end

  local query = table.remove(Scanner.queries, 1)
  if not query then
    finishScan(("Scan termine: %d joueurs uniques"):format(countMapKeys(Scanner.results)))
    return false, "scan complete"
  end

  local remain = cooldownRemaining()
  if remain > 0 then
    table.insert(Scanner.queries, 1, query)
    return false, ("wait %.1fs"):format(remain)
  end

  Scanner.awaiting = true
  Scanner.currentQuery = query
  Scanner.querySent = Scanner.querySent + 1

  if not ((C_FriendList and C_FriendList.SendWho) or SendWho) then
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    table.insert(Scanner.queries, 1, query)
    ns.DB_Log("ERR", "API /who indisponible sur ce client")
    ns.UI_Refresh()
    return false, "who api unavailable"
  end

  setWhoToUiEnabled(false)
  local ok = sendWhoQuery(query)
  if not ok then
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    table.insert(Scanner.queries, 1, query)
    ns.DB_Log("ERR", "SendWho bloque pour la requete: " .. tostring(query))
    ns.UI_Refresh()
    return false, "SendWho blocked (needs hardware click)"
  end

  Scanner.lastWhoSent = GetTime and GetTime() or 0
  local timeout = ns.Util_ToNumber(ns.db.profile.scanWhoTimeoutSeconds, 8, 3, 30)
  Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
  Scanner.timeoutTimer = C_Timer.NewTimer(timeout, function()
    if Scanner.active and Scanner.awaiting and Scanner.currentQuery == query then
      if getNumWhoResults() > 0 then
        processWhoResults(query)
      end
      Scanner.awaiting = false
      Scanner.currentQuery = nil
      ns.DB_Log("SCAN", "Timeout WHO: " .. query)
      ns.UI_Refresh()
    end
  end)

  ns.UI_Refresh()
  return true
end

function ns.Scanner_Init()
  if Scanner.initialized then return end
  Scanner.initialized = true

  ns.CR:RegisterEvent("WHO_LIST_UPDATE", function()
    if not Scanner.awaiting then return end
    Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
    local completedQuery = Scanner.currentQuery
    Scanner.awaiting = false
    Scanner.currentQuery = nil

    processWhoResults(completedQuery)

    if Scanner.active and #Scanner.queries == 0 then
      finishScan(("Scan termine: %d joueurs uniques"):format(countMapKeys(Scanner.results)))
      return
    end

    ns.UI_Refresh()
  end)
end

function ns.Scanner_GetStats()
  local className, classFile, levelRange
  if Scanner.currentQuery then
    className = Scanner.currentQuery:match('c%-"([^"]+)"')
    levelRange = Scanner.currentQuery:match("(%d+%-%d+)")
    if className then
      local src = LOCALIZED_CLASS_NAMES_MALE or {}
      for cf, name in pairs(src) do
        if name == className then classFile = cf; break end
      end
    end
  end
  return {
    scanning = Scanner.active,
    awaiting = Scanner.awaiting,
    currentQuery = Scanner.currentQuery or "",
    currentClassName = className or "",
    currentClassFile = classFile or "",
    currentLevelRange = levelRange or "",
    pendingQueries = #Scanner.queries,
    querySent = Scanner.querySent,
    totalQueries = Scanner.totalQueries,
    totalWhoRows = Scanner.totalWhoRows,
    listedPlayers = countMapKeys(Scanner.results),
    cappedQueries = Scanner.cappedQueries,
    lastResultAt = Scanner.lastResultAt,
    cooldownRemaining = cooldownRemaining(),
  }
end

function ns.Scanner_GetRows()
  if not Scanner._dirty and Scanner._cachedRows then
    return Scanner._cachedRows
  end
  local out = {}
  for _, rec in pairs(Scanner.results) do
    if rec then
      out[#out + 1] = rec
    end
  end
  Scanner._cachedRows = out
  Scanner._dirty = false
  return out
end

function ns.Scanner_ScanStep(clearCurrentList)
  if clearCurrentList then
    Scanner.results = {}
    Scanner.active = false
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    Scanner.queries = {}
    Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
  end

  if not Scanner.active then
    local queries = buildWhoQueries()
    if #queries == 0 then
      return false, "no query generated"
    end

    Scanner.results = {}
    Scanner._dirty = true
    Scanner._cachedRows = nil
    Scanner.queries = queries
    Scanner.totalQueries = #queries
    Scanner.active = true
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    Scanner.querySent = 0
    Scanner.totalWhoRows = 0
    Scanner.cappedQueries = 0
    Scanner.lastResultAt = 0
    Scanner.lastWhoSent = 0
    Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)

    ns.DB_Log("SCAN", ("Demarrage scan: %d requetes WHO"):format(#queries))
    if ns.sessionStats then ns.sessionStats.scansStarted = ns.sessionStats.scansStarted + 1 end

    -- Record statistics
    if ns.Statistics and ns.Statistics.RecordEvent then
      ns.Statistics:RecordEvent("scan")
    end
  end

  return sendNextQuery()
end

function ns.Scanner_Stop()
  if not Scanner.active and not Scanner.awaiting then
    return
  end
  finishScan("Scan stoppe manuellement")
end

function ns.Scanner_IsBusy()
  return Scanner.awaiting and true or false
end

function ns.Scanner_Clear()
  Scanner.active = false
  Scanner.awaiting = false
  Scanner.currentQuery = nil
  Scanner.queries = {}
  Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
  Scanner.results = {}
  Scanner._dirty = true
  Scanner._cachedRows = nil
  Scanner.totalQueries = 0
  Scanner.totalWhoRows = 0
  Scanner.lastResultAt = 0
  ns.UI_Refresh()
end

function ns.Scanner_ImportCurrentWho()
  local totalRows = getNumWhoResults()
  if totalRows <= 0 then
    return 0, 0
  end

  local addedPlayers = 0
  local addedQueue = 0
  Scanner.totalWhoRows = Scanner.totalWhoRows + totalRows
  Scanner.lastResultAt = ns.Util_Now()

  for i = 1, totalRows do
    local info = parseWhoInfo(i)
    if info then
      local rec = buildPlayerRecord(info)
      if rec then
        local isNew, current = mergeRecord(rec)
        if isNew then
          addedPlayers = addedPlayers + 1
          if queueIfUnguilded(current) then
            addedQueue = addedQueue + 1
          end
        end
      end
    end
  end

  ns.DB_Log("SCAN", ("Import /who: +%d joueurs, +%d en file"):format(addedPlayers, addedQueue))
  ns.UI_Refresh()
  return addedPlayers, totalRows
end

