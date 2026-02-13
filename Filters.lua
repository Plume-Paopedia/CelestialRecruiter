local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Advanced Filtering System
-- Powerful multi-criteria filtering with save/load presets
-- ═══════════════════════════════════════════════════════════════════

ns.Filters = ns.Filters or {}
local Filters = ns.Filters

-- Active filter state
Filters.active = {
    text = "",           -- Text search
    status = {},         -- {new=true, invited=true, ...}
    classes = {},        -- {WARRIOR=true, MAGE=true, ...}
    levelMin = nil,
    levelMax = nil,
    source = nil,        -- "scanner", "inbox", etc.
    optedIn = nil,       -- nil = all, true = only opted in, false = not opted in
    crossRealm = nil,    -- nil = all, true = only cross-realm, false = same realm
    tags = {},           -- {tag1=true, tag2=true, ...}
    recentDays = nil,    -- Only contacts seen in last N days
}

-- Saved filter presets
Filters.presets = {}

-- Available classes (populated on init)
Filters.availableClasses = {}

function Filters:Init()
    -- Build class list
    self.availableClasses = {}
    local numClasses = GetNumClasses and GetNumClasses() or 0
    if numClasses > 0 then
        for i = 1, numClasses do
            local name, file = GetClassInfo(i)
            if file then
                table.insert(self.availableClasses, {file = file, name = name})
            end
        end
    end
    table.sort(self.availableClasses, function(a, b) return a.name < b.name end)

    -- Load saved presets from DB
    if ns.db and ns.db.profile and ns.db.profile.filterPresets then
        self.presets = ns.db.profile.filterPresets
    end
end

function Filters:Reset()
    self.active = {
        text = "",
        status = {},
        classes = {},
        levelMin = nil,
        levelMax = nil,
        source = nil,
        optedIn = nil,
        crossRealm = nil,
        tags = {},
        recentDays = nil,
    }
end

function Filters:SetText(text)
    self.active.text = ns.Util_Lower(ns.Util_Trim(text or ""))
end

function Filters:ToggleStatus(status)
    self.active.status[status] = not self.active.status[status]
end

function Filters:ToggleClass(classFile)
    self.active.classes[classFile] = not self.active.classes[classFile]
end

function Filters:ToggleTag(tag)
    self.active.tags[tag] = not self.active.tags[tag]
end

function Filters:SetLevelRange(minLevel, maxLevel)
    self.active.levelMin = minLevel
    self.active.levelMax = maxLevel
end

function Filters:SetOptedIn(value)
    self.active.optedIn = value
end

function Filters:SetCrossRealm(value)
    self.active.crossRealm = value
end

function Filters:SetRecentDays(days)
    self.active.recentDays = days
end

-- Check if a contact matches current filters
function Filters:Matches(contact, scanData)
    if not contact then return false end

    -- Text search (name, notes)
    if self.active.text ~= "" then
        local searchText = ns.Util_Lower((contact.name or "") .. " " .. (contact.notes or ""))
        if not searchText:find(self.active.text, 1, true) then
            return false
        end
    end

    -- Status filter
    local hasStatusFilter = false
    for _ in pairs(self.active.status) do hasStatusFilter = true; break end
    if hasStatusFilter then
        if not self.active.status[contact.status or "new"] then
            return false
        end
    end

    -- Class filter
    local hasClassFilter = false
    for _ in pairs(self.active.classes) do hasClassFilter = true; break end
    if hasClassFilter then
        local classFile = (scanData and scanData.classFile) or contact.classFile or ""
        if not self.active.classes[classFile] then
            return false
        end
    end

    -- Level range
    local level = (scanData and scanData.level) or contact.level or 0
    if self.active.levelMin and level < self.active.levelMin then
        return false
    end
    if self.active.levelMax and level > self.active.levelMax then
        return false
    end

    -- Source filter
    if self.active.source and contact.source ~= self.active.source then
        return false
    end

    -- Opted in filter
    if self.active.optedIn ~= nil then
        local optedIn = contact.optedIn and true or false
        if self.active.optedIn ~= optedIn then
            return false
        end
    end

    -- Cross-realm filter
    if self.active.crossRealm ~= nil then
        local isCrossRealm = (scanData and scanData.crossRealm) or contact.crossRealm or false
        if self.active.crossRealm ~= isCrossRealm then
            return false
        end
    end

    -- Tags filter
    local hasTagFilter = false
    for _ in pairs(self.active.tags) do hasTagFilter = true; break end
    if hasTagFilter then
        local contactTags = contact.tags or {}
        local matchedAny = false
        for tag in pairs(self.active.tags) do
            if ns.Util_TableHas(contactTags, tag) then
                matchedAny = true
                break
            end
        end
        if not matchedAny then
            return false
        end
    end

    -- Recent days filter
    if self.active.recentDays then
        local cutoff = ns.Util_Now() - (self.active.recentDays * 24 * 3600)
        local lastSeen = contact.lastSeen or 0
        if lastSeen < cutoff then
            return false
        end
    end

    return true
end

-- Check if any filters are active
function Filters:IsActive()
    if self.active.text ~= "" then return true end
    for _ in pairs(self.active.status) do return true end
    for _ in pairs(self.active.classes) do return true end
    if self.active.levelMin or self.active.levelMax then return true end
    if self.active.source then return true end
    if self.active.optedIn ~= nil then return true end
    if self.active.crossRealm ~= nil then return true end
    for _ in pairs(self.active.tags) do return true end
    if self.active.recentDays then return true end
    return false
end

-- Count active filters
function Filters:CountActive()
    local count = 0
    if self.active.text ~= "" then count = count + 1 end
    for _ in pairs(self.active.status) do count = count + 1 end
    for _ in pairs(self.active.classes) do count = count + 1 end
    if self.active.levelMin or self.active.levelMax then count = count + 1 end
    if self.active.source then count = count + 1 end
    if self.active.optedIn ~= nil then count = count + 1 end
    if self.active.crossRealm ~= nil then count = count + 1 end
    for _ in pairs(self.active.tags) do count = count + 1 end
    if self.active.recentDays then count = count + 1 end
    return count
end

-- Save current filters as a preset
function Filters:SavePreset(name)
    if not name or name == "" then return false end

    -- Deep copy current filters
    local preset = {
        text = self.active.text,
        status = {},
        classes = {},
        levelMin = self.active.levelMin,
        levelMax = self.active.levelMax,
        source = self.active.source,
        optedIn = self.active.optedIn,
        crossRealm = self.active.crossRealm,
        tags = {},
        recentDays = self.active.recentDays,
    }

    for k, v in pairs(self.active.status) do preset.status[k] = v end
    for k, v in pairs(self.active.classes) do preset.classes[k] = v end
    for k, v in pairs(self.active.tags) do preset.tags[k] = v end

    self.presets[name] = preset

    -- Save to DB
    if ns.db and ns.db.profile then
        if not ns.db.profile.filterPresets then
            ns.db.profile.filterPresets = {}
        end
        ns.db.profile.filterPresets[name] = preset
    end

    return true
end

-- Load a preset
function Filters:LoadPreset(name)
    local preset = self.presets[name]
    if not preset then return false end

    -- Deep copy preset to active
    self.active.text = preset.text or ""
    self.active.status = {}
    self.active.classes = {}
    self.active.tags = {}
    self.active.levelMin = preset.levelMin
    self.active.levelMax = preset.levelMax
    self.active.source = preset.source
    self.active.optedIn = preset.optedIn
    self.active.crossRealm = preset.crossRealm
    self.active.recentDays = preset.recentDays

    for k, v in pairs(preset.status or {}) do self.active.status[k] = v end
    for k, v in pairs(preset.classes or {}) do self.active.classes[k] = v end
    for k, v in pairs(preset.tags or {}) do self.active.tags[k] = v end

    return true
end

-- Delete a preset
function Filters:DeletePreset(name)
    self.presets[name] = nil
    if ns.db and ns.db.profile and ns.db.profile.filterPresets then
        ns.db.profile.filterPresets[name] = nil
    end
end

-- Get all preset names
function Filters:GetPresetNames()
    local names = {}
    for name in pairs(self.presets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Get all unique tags from contacts
function Filters:GetAvailableTags()
    local tags = {}
    local seen = {}
    for _, contact in pairs(ns.db.global.contacts or {}) do
        if contact and contact.tags then
            for _, tag in ipairs(contact.tags) do
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
