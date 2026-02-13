local _, ns = ...

function ns.Util_Print(msg)
  local text = tostring(msg or "")
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00d1ff[CR]|r " .. text)
  end
end

function ns.Util_Trim(s)
  return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function ns.Util_Lower(s)
  return (s and s:lower()) or ""
end

function ns.Util_EscapePattern(s)
  s = tostring(s or "")
  return s:gsub("([^%w])", "%%%1")
end

function ns.Util_ToNumber(v, fallback, minValue, maxValue)
  local n = tonumber(v)
  if not n then
    return fallback
  end
  if minValue and n < minValue then
    n = minValue
  end
  if maxValue and n > maxValue then
    n = maxValue
  end
  return n
end

function ns.Util_SplitComma(s)
  local seen = {}
  local out = {}
  s = s or ""
  for token in s:gmatch("([^,]+)") do
    token = ns.Util_Trim(token)
    local key = token:lower()
    if token ~= "" and not seen[key] then
      seen[key] = true
      table.insert(out, token)
    end
  end
  return out
end

function ns.Util_Now()
  return time()
end

function ns.Util_Key(name)
  -- WoW often gives Name-Realm for cross-realm players.
  name = ns.Util_Trim(name or "")
  name = name:gsub("%s*%-%s*", "-")
  name = name:gsub("%s+", "")
  if name == "" then return nil end
  return name
end

function ns.Util_RealmSlug(realmName)
  local realm = ns.Util_Trim(realmName or "")
  if realm == "" then
    realm = GetRealmName() or ""
  end
  realm = realm:gsub("%s+", "")
  realm = realm:gsub("[']", "")
  realm = realm:gsub("[\226\128\153]", "") -- UTF-8 apostrophe
  return realm
end

function ns.Util_EnsurePlayerRealm(name, realmName)
  local key = ns.Util_Key(name)
  if not key then return nil end
  if key:find("-", 1, true) then
    return key
  end
  local realm = ns.Util_RealmSlug(realmName)
  if realm == "" then
    return key
  end
  return key .. "-" .. realm
end

function ns.Util_IsSameRealmPlayer(name)
  local key = ns.Util_Key(name)
  if not key then return false end
  local suffix = key:match("%-(.+)$")
  if not suffix then
    return true
  end
  return ns.Util_RealmSlug(suffix) == ns.Util_RealmSlug(GetRealmName())
end

function ns.Util_FormatAgo(ts)
  ts = tonumber(ts) or 0
  if ts <= 0 then return "n/d" end
  local d = time() - ts
  if d < 0 then d = 0 end
  if d < 60 then return d .. "s" end
  if d < 3600 then return math.floor(d/60) .. "m" end
  if d < 86400 then return math.floor(d/3600) .. "h" end
  return math.floor(d/86400) .. "j"
end

function ns.Util_TableHas(t, v)
  if type(t) ~= "table" then return false end
  for _,x in ipairs(t) do if x == v then return true end end
  return false
end

function ns.Util_SortKeysByRecent(list, getTs)
  table.sort(list, function(a, b)
    local ta = tonumber(getTs(a)) or 0
    local tb = tonumber(getTs(b)) or 0
    if ta == tb then
      return tostring(a) < tostring(b)
    end
    return ta > tb
  end)
end
