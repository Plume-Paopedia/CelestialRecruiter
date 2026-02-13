local ADDON, ns = ...
local CR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0")
ns.CR = CR

function CR:OnInitialize()
  ns.DB_Init()
  ns.Templates_Init()
  ns.Queue_Init()
  if ns.Themes and ns.Themes.Init then
    ns.Themes:Init()
  end
  if ns.Filters and ns.Filters.Init then
    ns.Filters:Init()
  end
  if ns.Statistics and ns.Statistics.Init then
    ns.Statistics:Init()
  end
  if ns.AutoRecruiter and ns.AutoRecruiter.Init then
    ns.AutoRecruiter:Init()
  end
  if ns.Discord and ns.Discord.Init then
    ns.Discord:Init()
  end
  if ns.ABTesting and ns.ABTesting.Init then
    ns.ABTesting:Init()
  end
  if ns.Campaigns and ns.Campaigns.Init then
    ns.Campaigns:Init()
  end
  if ns.Goals and ns.Goals.Init then
    ns.Goals:Init()
  end
  if ns.SmartSuggestions and ns.SmartSuggestions.Init then
    ns.SmartSuggestions:Init()
  end
end

function CR:OnEnable()
  ns.sessionStats = {
    startedAt = time(),
    scansStarted = 0,
    invitesSent = 0,
    whispersSent = 0,
    playersFound = 0,
    queueAdded = 0,
    recruitsJoined = 0,
  }
  ns.AntiSpam_Init()
  ns.Scanner_Init()
  ns.Minimap_Init()

  -- Initialize particle system
  if ns.ParticleSystem and ns.ParticleSystem.Init then
    ns.ParticleSystem:Init()
  end

  ns.UI_Init()
  ns.Inbox_Init()

  -- Auto-backup once per day
  if ns.ImportExport then
    local lastBackup = ns.db.global.lastAutoBackup or 0
    local now = time()
    local dayInSeconds = 24 * 3600

    if now - lastBackup > dayInSeconds then
      ns.ImportExport:CreateAutoBackup()
      ns.db.global.lastAutoBackup = now
      ns.Util_Print("Sauvegarde automatique effectuée")
    end
  end

  -- ═══════════════════════════════════════════════════════════════
  -- Track guild joins - robust multi-method detection
  -- ═══════════════════════════════════════════════════════════════

  local function onRecruitJoined(key)
    if not key then return end
    local c = ns.DB_GetContact(key)
    if not c then return end
    -- Skip if already marked as joined
    if c.status == "joined" then return end
    -- Only track contacts we actually contacted or invited (not "new"/uncontacted)
    if c.status ~= "invited" and c.status ~= "contacted" then return end

    local lastTemplate = c.lastTemplate
    local campaignId = c._campaignId

    ns.DB_UpsertContact(key, { status = "joined" })
    ns.DB_Log("JOIN", "Recrue a rejoint la guilde: " .. key)
    if ns.sessionStats then
      ns.sessionStats.recruitsJoined = ns.sessionStats.recruitsJoined + 1
    end

    -- Record statistics
    if ns.Statistics and ns.Statistics.RecordEvent then
      ns.Statistics:RecordEvent("joined", {contact = c})
    end

    -- Show celebration notification
    if ns.Notifications_Success then
      ns.Notifications_Success("Nouvelle recrue !", key .. " a rejoint la guilde")
    end

    -- Play epic visual effects!
    if ns.ParticleSystem and ns.ParticleSystem.PlayRecruitJoinedEffect and ns.UI and ns.UI.mainFrame then
      ns.ParticleSystem:PlayRecruitJoinedEffect(ns.UI.mainFrame)
    end

    -- Notify Discord
    if ns.Discord and ns.Discord.NotifyRecruitJoined then
      ns.Discord:NotifyRecruitJoined(key, c)
    end

    -- Record A/B Testing outcome
    if ns.ABTesting and ns.ABTesting.RecordJoined and lastTemplate then
      ns.ABTesting:RecordJoined(lastTemplate)
    end

    -- Record Campaigns outcome
    if ns.Campaigns and campaignId then
      ns.Campaigns:RecordJoined(campaignId, key)
    end

    -- Record Goals activity
    if ns.Goals and ns.Goals.RecordActivity then
      ns.Goals:RecordActivity("join")
    end

    ns.UI_Refresh()
  end

  -- Method 1: CHAT_MSG_SYSTEM - parse the guild join message
  -- Build pattern from WoW global string for locale safety
  local joinPatterns = {}
  if ERR_GUILD_JOIN_S then
    local pat = ERR_GUILD_JOIN_S:gsub("%%s", "(.+)")
    pat = pat:gsub("%.", "%%.")  -- escape trailing period
    table.insert(joinPatterns, pat)
  end
  -- Fallback hardcoded patterns
  table.insert(joinPatterns, "(.+) a rejoint la guilde")
  table.insert(joinPatterns, "(.+) has joined the guild")

  CR:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg)
    if not msg then return end
    local joined
    for _, pat in ipairs(joinPatterns) do
      joined = msg:match(pat)
      if joined then break end
    end
    if not joined then return end
    local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(joined))
    onRecruitJoined(key)
  end)

  -- Method 2: CLUB_MEMBER_ADDED - Communities API (modern WoW retail)
  if C_Club and C_Club.GetGuildClubId then
    CR:RegisterEvent("CLUB_MEMBER_ADDED", function(_, clubId, memberId)
      local guildClubId = C_Club.GetGuildClubId()
      if not guildClubId or clubId ~= guildClubId then return end
      local memberInfo = C_Club.GetMemberInfo(clubId, memberId)
      if not memberInfo or not memberInfo.name then return end
      local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(memberInfo.name))
      onRecruitJoined(key)
    end)
  end

  -- Method 3: Periodic roster check for invited contacts
  -- Runs every 30s, checks if any "invited"/"contacted" contacts are now guild members
  -- Also re-verifies "joined" contacts are still in guild (cleans up false positives)
  local rosterCheckInterval = 30
  C_Timer.NewTicker(rosterCheckInterval, function()
    if not IsInGuild() then return end
    if not ns.db or not ns.db.global or not ns.db.global.contacts then return end

    local totalMembers = GetNumGuildMembers()
    if totalMembers == 0 then return end

    -- Build a set of current guild member names (strict full Name-Realm keys)
    local guildMembers = {}
    for i = 1, totalMembers do
      local name = GetGuildRosterInfo(i)
      if name then
        local memberKey = ns.Util_Key(name)
        if memberKey then
          guildMembers[memberKey] = true
        end
      end
    end

    -- Check invited/contacted contacts against guild roster (strict match only)
    for key, c in pairs(ns.db.global.contacts) do
      if c.status == "invited" or c.status == "contacted" then
        if guildMembers[key] then
          onRecruitJoined(key)
        end
      end
    end

    -- Re-verify "joined" contacts: remove false positives not actually in guild
    for key, c in pairs(ns.db.global.contacts) do
      if c.status == "joined" and not guildMembers[key] then
        if (c.lastInviteAt and c.lastInviteAt > 0) then
          ns.DB_UpsertContact(key, { status = "invited" })
        elseif (c.lastWhisperOut and c.lastWhisperOut > 0) then
          ns.DB_UpsertContact(key, { status = "contacted" })
        else
          ns.DB_UpsertContact(key, { status = "new" })
        end
      end
    end
  end)
  ns.Util_Print("Addon chargé. Utilise |cff00d1ff/cr|r pour ouvrir l'interface, bon recrutement ! Fait par plume.pao avec amour <3")
end

SLASH_CELESTIALRECRUITER1 = "/cr"
SLASH_CELESTIALRECRUITER2 = "/celestialrecruiter"
SlashCmdList["CELESTIALRECRUITER"] = function(msg)
  msg = ns.Util_Lower(ns.Util_Trim(msg or ""))

  if msg == "reset" then
    ns.DB_Reset()
    ns.Templates_Init()
    ns.UI_Refresh()
    ns.Util_Print("Reset effectué.")
    return
  end

  if msg == "help" then
    ns.Util_Print("Commandes: /cr, /cr reset, /cr help")
    ns.Util_Print("Scanner: bouton Scan (avec cooldown), import /who, joueurs sans guilde ajoutés en liste.")
    return
  end

  ns.UI_Toggle()
end
