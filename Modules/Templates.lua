local _, ns = ...

local templates = {}

local BUILTIN = {
  default = {
    name = "Par defaut",
    text = "Salut {name}, la guilde {guild} recrute. Ambiance chill et progression stable. Discord: {discord}. Si interesse, reponds {inviteKeyword}.",
  },
  raid = {
    name = "Raid",
    text = "Salut {name}, {guild} recrute pour le roster raid. Jours: {raidDays}. Objectif: {goal}. Si tu veux une invite, ecris {inviteKeyword}.",
  },
  short = {
    name = "Court",
    text = "{name}, {guild} recrute. Si interesse: {inviteKeyword}.",
  },
}

local function clean(s)
  s = tostring(s or "")
  s = s:gsub("%s+", " ")
  s = ns.Util_Trim(s)
  return s
end

local function truncateWhisper(s)
  local maxLen = 240
  if #s <= maxLen then return s end
  -- Find a safe cut point that doesn't split a multi-byte UTF-8 character
  local cutAt = maxLen - 3
  -- Walk back if we're in the middle of a UTF-8 continuation byte (10xxxxxx)
  while cutAt > 0 and s:byte(cutAt) >= 128 and s:byte(cutAt) < 192 do
    cutAt = cutAt - 1
  end
  return s:sub(1, cutAt) .. "..."
end

function ns.Templates_Init()
  -- Merge saved custom texts over builtins
  local saved = ns.db and ns.db.profile and ns.db.profile.customTemplates
  templates = {}
  for id, def in pairs(BUILTIN) do
    templates[id] = {
      name = def.name,
      text = (saved and saved[id]) or def.text,
      builtin = true,
    }
  end
  -- Load user-created templates
  if saved then
    for id, text in pairs(saved) do
      if not BUILTIN[id] and text ~= "" then
        templates[id] = { name = id, text = text, builtin = false }
      end
    end
  end
end

function ns.Templates_All()
  return templates
end

function ns.Templates_GetText(id)
  local tpl = templates[id]
  return tpl and tpl.text or ""
end

function ns.Templates_SetText(id, text)
  if not ns.db or not ns.db.profile then return end
  if not ns.db.profile.customTemplates then
    ns.db.profile.customTemplates = {}
  end
  ns.db.profile.customTemplates[id] = text
  if templates[id] then
    templates[id].text = text
  end
end

function ns.Templates_ResetToDefault(id)
  if BUILTIN[id] then
    ns.Templates_SetText(id, BUILTIN[id].text)
  end
end

function ns.Templates_GetDefault(id)
  return BUILTIN[id] and BUILTIN[id].text or ""
end

function ns.Templates_Render(key, tplId)
  local c = ns.DB_GetContact(key) or { name = key }
  local p = ns.db.profile
  local tpl = templates[tplId] or templates.default

  local map = {
    ["{name}"] = clean(c.name or key),
    ["{guild}"] = clean(p.guildName ~= "" and p.guildName or "notre guilde"),
    ["{discord}"] = clean(p.discord ~= "" and p.discord or "a definir"),
    ["{raidDays}"] = clean(p.raidDays ~= "" and p.raidDays or "a definir"),
    ["{goal}"] = clean(p.goal ~= "" and p.goal or "a definir"),
    ["{inviteKeyword}"] = clean(p.inviteKeyword ~= "" and p.inviteKeyword or "!invite"),
  }

  local out = tpl.text
  for token, value in pairs(map) do
    out = out:gsub(token, function() return value end)
  end
  out = clean(out)
  return truncateWhisper(out)
end
