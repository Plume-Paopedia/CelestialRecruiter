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
  resultCount = 0,
  timeoutTimer = nil,
  cappedQueries = 0,
  totalQueries = 0,
  _dirty = true,
  _cachedRows = nil,
  _statsClassName = nil,
  _statsClassFile = nil,
  _statsLevelRange = nil,

  autoScanTimer = nil,
  autoScanCycles = 0,
  autoReady = false,
  autoHooked = false,
}

ns.Scanner = Scanner

local RECENT_INVITE_COOLDOWN = 7 * 24 * 3600 -- 7 days in seconds

local function cancelTimer(t)
  if t and t.Cancel then
    t:Cancel()
  end
  return nil
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

local function autoScanDelay()
  return ns.Util_ToNumber(ns.db.profile.scanAutoDelayMinutes, 5, 1, 60) * 60
end

local function isAutoScanEnabled()
  return ns.db and ns.db.profile and ns.db.profile.scanAutoEnabled
end

-- Forward declarations (filled after sendNextQuery is defined)
local scheduleAutoReady
local scheduleAutoScanCycleRestart

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
  local skipReason = nil
  if guild ~= "" and not ns.db.profile.scanIncludeGuilded then
    skipReason = "guild"
  end

  if not skipReason and ns.DB_IsBlacklisted(inviteName) then
    skipReason = "blacklist"
  end

  local isCrossRealm = not ns.Util_IsSameRealmPlayer(inviteName)
  if not skipReason and isCrossRealm and not ns.db.profile.scanIncludeCrossRealm then
    skipReason = "crossrealm"
  end

  -- 7-day invite cooldown: skip players invited within the last 7 days
  if not skipReason then
    local contact = ns.DB_GetContact and ns.DB_GetContact(inviteName) or nil
    if contact and (contact.lastInviteAt or 0) > 0 then
      if (ns.Util_Now() - contact.lastInviteAt) < RECENT_INVITE_COOLDOWN then
        skipReason = "recent_invite"
      end
    end
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
    skipReason = skipReason,
    firstSeen = now,
    lastSeen = now,
  }
end

local function mergeRecord(record)
  local existing = Scanner.results[record.key]
  if not existing then
    Scanner.results[record.key] = record
    Scanner.resultCount = Scanner.resultCount + 1
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
  existing.skipReason = record.skipReason
  existing.lastSeen = record.lastSeen or existing.lastSeen
  return false, existing
end

local function queueFromScan(rec)
  if not rec then
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
    guild = rec.guild or "",
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
        if isNew and not rec.skipReason then
          addedPlayers = addedPlayers + 1
          if queueFromScan(current) then
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
      addedPlayers, addedQueue, Scanner.resultCount
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
  Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
  if logLine then
    ns.DB_Log("SCAN", logLine)
  end

  -- Discord notification
  if ns.DiscordQueue and ns.DiscordQueue.NotifyScannerComplete then
    ns.DiscordQueue:NotifyScannerComplete({
      found = Scanner.resultCount or 0,
      queries = Scanner.querySent or 0,
    })
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
    finishScan(("Scan termine: %d joueurs uniques"):format(Scanner.resultCount))
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

  -- Cache parsed class/level info (avoid regex in Scanner_GetStats every tick)
  local cn = query:match('c%-"([^"]+)"')
  Scanner._statsClassName = cn or ""
  Scanner._statsLevelRange = query:match("(%d+%-%d+)") or ""
  Scanner._statsClassFile = nil
  if cn then
    local src = LOCALIZED_CLASS_NAMES_MALE or {}
    for cf, name in pairs(src) do
      if name == cn then Scanner._statsClassFile = cf; break end
    end
  end

  if not ((C_FriendList and C_FriendList.SendWho) or SendWho) then
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    table.insert(Scanner.queries, 1, query)
    ns.DB_Log("ERR", "API /who indisponible sur ce client")
    return false, "who api unavailable"
  end

  local ok = sendWhoQuery(query)
  if not ok then
    Scanner.awaiting = false
    Scanner.currentQuery = nil
    table.insert(Scanner.queries, 1, query)
    ns.DB_Log("ERR", "SendWho bloque pour la requete: " .. tostring(query))
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
      if isAutoScanEnabled() and Scanner.active then
        scheduleAutoReady()
      end
      ns.UI_Refresh()
    end
  end)

  ns.UI_Refresh()
  return true
end

---------------------------------------------------------------------------
-- Auto-Scan: WorldFrame mouse-hook approach
-- C_FriendList.SendWho requires a hardware event (physical click/keypress).
-- We hook WorldFrame:OnMouseDown so every game-world click triggers the
-- next queued WHO query (after cooldown).
---------------------------------------------------------------------------

-- Schedule autoReady = true after the WHO cooldown expires.
-- Uses C_Timer only to flip a boolean flag — the actual SendWho call
-- happens in the WorldFrame OnMouseDown handler (hardware event).
scheduleAutoReady = function()
  Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
  Scanner.autoReady = false

  local remain = cooldownRemaining()
  local delay = math.max(remain + 0.1, 0.5)

  Scanner.autoScanTimer = C_Timer.NewTimer(delay, function()
    Scanner.autoScanTimer = nil
    if not isAutoScanEnabled() then return end
    Scanner.autoReady = true
    -- Ticker refreshes UI every 0.5s, no explicit refresh needed
  end)
end

scheduleAutoScanCycleRestart = function()
  Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
  Scanner.autoReady = false
  Scanner.autoScanCycles = Scanner.autoScanCycles + 1

  local delaySeconds = autoScanDelay()
  ns.DB_Log("SCAN", ("Cycle %d termine (%d joueurs). Prochain cycle dans %d min"):format(
    Scanner.autoScanCycles, Scanner.resultCount, math.floor(delaySeconds / 60)
  ))

  Scanner.active = false
  Scanner.awaiting = false
  Scanner.currentQuery = nil
  Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)

  -- After inter-cycle delay, prepare for new cycle on next click
  Scanner.autoScanTimer = C_Timer.NewTimer(delaySeconds, function()
    Scanner.autoScanTimer = nil
    if not isAutoScanEnabled() then
      ns.DB_Log("SCAN", "Auto-scan desactive pendant l'attente inter-cycle")
      ns.UI_Refresh()
      return
    end
    -- Don't call Scanner_ScanStep here (timer context = no hardware event).
    -- Just set autoReady; the next WorldFrame click will start the new cycle.
    Scanner.autoReady = true
    ns.DB_Log("SCAN", "Pret pour le prochain cycle — cliquez dans le jeu")
    ns.UI_Refresh()
  end)
  ns.UI_Refresh()
end

-- Shared trigger: fires the next WHO query.
-- Must ONLY be called from a hardware event context (OnMouseDown / OnKeyDown).
local function autoScanTrigger()
  if not isAutoScanEnabled() then return end
  if not Scanner.autoReady then return end
  if Scanner.awaiting then return end

  Scanner.autoReady = false

  if not Scanner.active then
    -- Start a new scan cycle (ScanStep builds queries + fires first query,
    -- all within this hardware event context)
    ns.Scanner_ScanStep(false)
  else
    sendNextQuery()
  end

  -- Schedule autoReady for the next query after cooldown
  if Scanner.active then
    scheduleAutoReady()
  end
end

-- 1) WorldFrame OnMouseDown: game-world clicks trigger WHO queries
local function installWorldFrameHook()
  if Scanner.autoHooked then return end
  Scanner.autoHooked = true
  WorldFrame:HookScript("OnMouseDown", function() autoScanTrigger() end)
end

-- 2) Keyboard listener: any key press (WASD, abilities, etc.) triggers WHO.
--    Uses EnableKeyboard + SetPropagateKeyboardInput(true) so all keys
--    still reach the game normally. The frame is invisible (1×1, no texture).
local autoScanKeyFrame = nil

local function showKeyboardListener()
  if not autoScanKeyFrame then
    local kf = CreateFrame("Frame", "CelestialRecruiterAutoScanKeys", UIParent)
    kf:SetSize(1, 1)
    kf:SetPoint("TOPLEFT")
    kf:EnableKeyboard(true)
    kf:SetPropagateKeyboardInput(true)
    kf:SetFrameStrata("TOOLTIP")
    kf:SetScript("OnKeyDown", function() autoScanTrigger() end)
    autoScanKeyFrame = kf
  end
  autoScanKeyFrame:Show()
end

local function hideKeyboardListener()
  if autoScanKeyFrame then
    autoScanKeyFrame:Hide()
  end
end

function ns.Scanner_Init()
  if Scanner.initialized then return end
  Scanner.initialized = true

  -- Suppress default WHO panel once at init (safe context, no taint)
  setWhoToUiEnabled(false)

  -- Pre-install the WorldFrame hook if auto-scan was previously enabled
  -- (the setting persists across sessions, but auto-scan won't auto-start)
  if isAutoScanEnabled() then
    installWorldFrameHook()
  end

  ns.CR:RegisterEvent("WHO_LIST_UPDATE", function()
    if not Scanner.awaiting then return end
    Scanner.timeoutTimer = cancelTimer(Scanner.timeoutTimer)
    local completedQuery = Scanner.currentQuery
    Scanner.awaiting = false
    Scanner.currentQuery = nil

    processWhoResults(completedQuery)

    if Scanner.active and #Scanner.queries == 0 then
      if isAutoScanEnabled() then
        scheduleAutoScanCycleRestart()
      else
        finishScan(("Scan termine: %d joueurs uniques"):format(Scanner.resultCount))
      end
      return
    end

    if isAutoScanEnabled() and Scanner.active then
      scheduleAutoReady()
    end

    ns.UI_Refresh()
  end)
end

-- Reusable stats table (avoids creating a new table every 0.5s)
local _statsTable = {}

function ns.Scanner_GetStats()
  local st = _statsTable
  st.scanning = Scanner.active
  st.awaiting = Scanner.awaiting
  st.currentQuery = Scanner.currentQuery or ""
  st.currentClassName = Scanner._statsClassName or ""
  st.currentClassFile = Scanner._statsClassFile or ""
  st.currentLevelRange = Scanner._statsLevelRange or ""
  st.pendingQueries = #Scanner.queries
  st.querySent = Scanner.querySent
  st.totalQueries = Scanner.totalQueries
  st.totalWhoRows = Scanner.totalWhoRows
  st.listedPlayers = Scanner.resultCount
  st.cappedQueries = Scanner.cappedQueries
  st.lastResultAt = Scanner.lastResultAt
  st.cooldownRemaining = cooldownRemaining()
  st.autoScanEnabled = isAutoScanEnabled()
  st.autoScanCycles = Scanner.autoScanCycles
  st.autoScanReady = Scanner.autoReady
  st.autoScanWaiting = Scanner.autoScanTimer ~= nil and not Scanner.active
  st.autoScanDelayMinutes = ns.Util_ToNumber(ns.db.profile.scanAutoDelayMinutes, 5, 1, 60)
  return st
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
    Scanner.resultCount = 0
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
    Scanner.resultCount = 0
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

    -- Discord notification
    if ns.DiscordQueue and ns.DiscordQueue.NotifyScannerStarted then
      local levelRange = ns.db.profile.scanLevelMin .. "-" .. ns.db.profile.scanLevelMax
      ns.DiscordQueue:NotifyScannerStarted(levelRange)
    end

    -- Record statistics
    if ns.Statistics and ns.Statistics.RecordEvent then
      ns.Statistics:RecordEvent("scan")
    end

    -- Record Goals activity
    if ns.Goals and ns.Goals.RecordActivity then
      ns.Goals:RecordActivity("scan")
    end
  end

  return sendNextQuery()
end

function ns.Scanner_Stop()
  if not Scanner.active and not Scanner.awaiting and not Scanner.autoScanTimer and not Scanner.autoReady then
    return
  end
  Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
  Scanner.autoScanCycles = 0
  Scanner.autoReady = false
  hideKeyboardListener()
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
  Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
  Scanner.autoScanCycles = 0
  Scanner.autoReady = false
  Scanner.results = {}
  Scanner.resultCount = 0
  Scanner._dirty = true
  Scanner._cachedRows = nil
  Scanner.totalQueries = 0
  Scanner.totalWhoRows = 0
  Scanner.lastResultAt = 0
  ns.UI_Refresh()
end

function ns.Scanner_AutoScanToggle(enabled)
  ns.db.profile.scanAutoEnabled = enabled and true or false

  if enabled then
    installWorldFrameHook()
    showKeyboardListener()
    if Scanner.active and not Scanner.awaiting then
      -- Scan already running: schedule readiness for next query
      scheduleAutoReady()
    elseif not Scanner.active then
      -- No scan running: set ready so next click/keypress starts a cycle
      Scanner.autoScanCycles = 0
      Scanner.autoReady = true
    end
    ns.DB_Log("SCAN", "Auto-scan active — cliquez ou bougez pour scanner")
  else
    Scanner.autoScanTimer = cancelTimer(Scanner.autoScanTimer)
    Scanner.autoScanCycles = 0
    Scanner.autoReady = false
    hideKeyboardListener()
    ns.DB_Log("SCAN", "Auto-scan desactive")
  end

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
        if isNew and not rec.skipReason then
          addedPlayers = addedPlayers + 1
          if queueFromScan(current) then
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

