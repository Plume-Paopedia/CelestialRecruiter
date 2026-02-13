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
  if ns.DiscordQueue and ns.DiscordQueue.Init then
    ns.DiscordQueue:Init()
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
  if ns.Leaderboard and ns.Leaderboard.Init then
    ns.Leaderboard:Init()
    if ns.Leaderboard.InitGuildSync then
      ns.Leaderboard:InitGuildSync()
    end
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
      ns.Util_Print("Sauvegarde automatique effectuee.")
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

    -- Show celebration banner for this important event
    if ns.Notifications_Celebrate then
      ns.Notifications_Celebrate("Nouvelle recrue !", key .. " a rejoint la guilde")
    end

    -- Play epic visual effects!
    if ns.ParticleSystem and ns.ParticleSystem.PlayRecruitJoinedEffect and ns.UI and ns.UI.mainFrame then
      ns.ParticleSystem:PlayRecruitJoinedEffect(ns.UI.mainFrame)
    end

    -- Notify Discord (legacy)
    if ns.Discord and ns.Discord.NotifyRecruitJoined then
      ns.Discord:NotifyRecruitJoined(key, c)
    end

    -- Notify Discord Queue (new webhook system)
    if ns.DiscordQueue and ns.DiscordQueue.NotifyPlayerJoined then
      ns.DiscordQueue:NotifyPlayerJoined(key)
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

    -- Record Leaderboard join
    if ns.Leaderboard and ns.Leaderboard.RecordDaily then
      ns.Leaderboard:RecordDaily("join")

      -- Calculer le temps le plus rapide contact -> join
      if c.lastWhisperOut and c.lastWhisperOut > 0 then
        local joinTime = time()
        local contactTime = c.lastWhisperOut
        local diffMinutes = math.floor((joinTime - contactTime) / 60)
        if diffMinutes > 0 then
          ns.Leaderboard:RecordFastestJoin(diffMinutes)
        end
      end
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

  -- Guild leave patterns
  local leavePatterns = {}
  if ERR_GUILD_LEAVE_S then
    local pat = ERR_GUILD_LEAVE_S:gsub("%%s", "(.+)")
    pat = pat:gsub("%.", "%%.")
    table.insert(leavePatterns, pat)
  end
  table.insert(leavePatterns, "(.+) a quitte la guilde")
  table.insert(leavePatterns, "(.+) has left the guild")

  -- Guild promote/demote patterns
  local promotePatterns = {}
  if ERR_GUILD_PROMOTE_SSS then
    local pat = ERR_GUILD_PROMOTE_SSS:gsub("%%s", "(.+)")
    pat = pat:gsub("%.", "%%.")
    table.insert(promotePatterns, pat)
  end
  table.insert(promotePatterns, "(.+) a ete promu (.+) par (.+)")
  table.insert(promotePatterns, "(.+) has been promoted to (.+) by (.+)")

  local demotePatterns = {}
  if ERR_GUILD_DEMOTE_SSS then
    local pat = ERR_GUILD_DEMOTE_SSS:gsub("%%s", "(.+)")
    pat = pat:gsub("%.", "%%.")
    table.insert(demotePatterns, pat)
  end
  table.insert(demotePatterns, "(.+) a ete retrograde (.+) par (.+)")
  table.insert(demotePatterns, "(.+) has been demoted to (.+) by (.+)")

  CR:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg)
    if not msg then return end

    -- Check guild join
    local joined
    for _, pat in ipairs(joinPatterns) do
      joined = msg:match(pat)
      if joined then break end
    end
    if joined then
      local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(joined))
      -- Notify Discord for ALL guild joins (not just recruited contacts)
      if key and ns.DiscordQueue and ns.DiscordQueue.NotifyGuildJoin then
        ns.DiscordQueue:NotifyGuildJoin(key)
        -- Auto-flush: reload UI to send Discord notification immediately
        if ns.DiscordQueue.ScheduleAutoFlush then
          ns.DiscordQueue:ScheduleAutoFlush()
        end
      end
      onRecruitJoined(key)
      return
    end

    -- Check guild leave
    for _, pat in ipairs(leavePatterns) do
      local left = msg:match(pat)
      if left then
        local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(left))
        if key and ns.DiscordQueue and ns.DiscordQueue.NotifyGuildLeave then
          ns.DiscordQueue:NotifyGuildLeave(key)
          -- Auto-flush: reload UI to send Discord notification immediately
          if ns.DiscordQueue.ScheduleAutoFlush then
            ns.DiscordQueue:ScheduleAutoFlush()
          end
        end
        return
      end
    end

    -- Check guild promote
    for _, pat in ipairs(promotePatterns) do
      local player, rank = msg:match(pat)
      if player then
        local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(player))
        if key and ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
          ns.DiscordQueue:QueueEvent("guild_promote", {
            description = string.format("**%s** a ete promu **%s**", key, rank or "?"),
            fields = { { name = "Nouveau rang", value = rank or "?", inline = true } }
          })
        end
        return
      end
    end

    -- Check guild demote
    for _, pat in ipairs(demotePatterns) do
      local player, rank = msg:match(pat)
      if player then
        local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(player))
        if key and ns.DiscordQueue and ns.DiscordQueue.QueueEvent then
          ns.DiscordQueue:QueueEvent("guild_demote", {
            description = string.format("**%s** a ete retrograde **%s**", key, rank or "?"),
            fields = { { name = "Nouveau rang", value = rank or "?", inline = true } }
          })
        end
        return
      end
    end
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
    -- Collect keys first to avoid modifying table during iteration
    local pendingJoins = {}
    for key, c in pairs(ns.db.global.contacts) do
      if c and (c.status == "invited" or c.status == "contacted") then
        if guildMembers[key] then
          pendingJoins[#pendingJoins + 1] = key
        end
      end
    end
    for _, key in ipairs(pendingJoins) do
      onRecruitJoined(key)
    end

    -- Re-verify "joined" contacts: remove false positives not actually in guild
    -- Collect keys first to avoid modifying table during iteration
    local pendingDemote = {}
    for key, c in pairs(ns.db.global.contacts) do
      if c and c.status == "joined" and not guildMembers[key] then
        pendingDemote[#pendingDemote + 1] = {key = key, c = c}
      end
    end
    for _, entry in ipairs(pendingDemote) do
      local c = entry.c
      if (c.lastInviteAt and c.lastInviteAt > 0) then
        ns.DB_UpsertContact(entry.key, { status = "invited" })
      elseif (c.lastWhisperOut and c.lastWhisperOut > 0) then
        ns.DB_UpsertContact(entry.key, { status = "contacted" })
      else
        ns.DB_UpsertContact(entry.key, { status = "new" })
      end
    end
  end)
  ns.Util_Print("Addon charge. Utilise |cff00d1ff/cr|r pour ouvrir l'interface, bon recrutement ! Fait par plume.pao avec amour <3")
end

SLASH_CELESTIALRECRUITER1 = "/cr"
SLASH_CELESTIALRECRUITER2 = "/celestialrecruiter"
SlashCmdList["CELESTIALRECRUITER"] = function(msg)
  msg = ns.Util_Lower(ns.Util_Trim(msg or ""))

  if msg == "reset" then
    ns.DB_Reset()
    ns.Templates_Init()
    ns.UI_Refresh()
    ns.Util_Print("Reset effectue.")
    return
  end

  if msg == "flush" then
    local count = 0
    if ns.db and ns.db.global and ns.db.global.discordQueue then
      count = #ns.db.global.discordQueue
    end
    if count > 0 then
      ns.Util_Print("Envoi de " .. count .. " notifications Discord... (reload en cours)")
    else
      ns.Util_Print("Aucune notification Discord en attente.")
      return
    end
    C_Timer.After(0.1, function()
      ReloadUI()
    end)
    return
  end

  if msg == "help" then
    ns.Util_Print("Commandes: /cr, /cr reset, /cr flush, /cr help")
    ns.Util_Print("/cr flush : Envoie les notifications Discord en attente (reload)")
    ns.Util_Print("Scanner: bouton Scan (avec cooldown), import /who, joueurs sans guilde ajoutes en file.")
    return
  end

  ns.UI_Toggle()
end
