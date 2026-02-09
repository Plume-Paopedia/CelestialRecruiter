local ADDON, ns = ...
local CR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0")
ns.CR = CR

function CR:OnInitialize()
  ns.DB_Init()
  ns.Templates_Init()
  ns.Queue_Init()
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
  ns.UI_Init()
  ns.Inbox_Init()

  -- Track guild joins from invited contacts
  CR:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg)
    if not msg then return end
    -- WoW patterns: ERR_GUILD_JOIN_S = "%s has joined the guild."
    -- French: "%s a rejoint la guilde."
    local joined = msg:match("(.+) a rejoint la guilde") or msg:match("(.+) has joined the guild")
    if not joined then return end
    local key = ns.Util_EnsurePlayerRealm(ns.Util_Key(joined))
    if not key then return end
    local c = ns.DB_GetContact(key)
    if c and (c.status == "invited" or c.status == "contacted") then
      ns.DB_UpsertContact(key, { status = "joined" })
      ns.DB_Log("JOIN", "Recrue a rejoint la guilde: " .. key)
      if ns.sessionStats then
        ns.sessionStats.recruitsJoined = ns.sessionStats.recruitsJoined + 1
      end
      ns.UI_Refresh()
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
