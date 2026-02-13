local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Import/Export System
-- Backup, restore, and share data between characters/accounts
-- ═══════════════════════════════════════════════════════════════════

ns.ImportExport = ns.ImportExport or {}
local IE = ns.ImportExport

-- Serialize table to string (simple JSON-like format)
local function serialize(t, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local result = "{\n"

    for k, v in pairs(t) do
        local key = type(k) == "string" and ('"%s"'):format(k) or tostring(k)
        result = result .. indentStr .. "  " .. key .. " = "

        if type(v) == "table" then
            result = result .. serialize(v, indent + 1)
        elseif type(v) == "string" then
            result = result .. ('"%s"'):format(v:gsub('"', '\\"'))
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        else
            result = result .. tostring(v)
        end

        result = result .. ",\n"
    end

    result = result .. indentStr .. "}"
    return result
end

-- Deserialize string to table (simple eval)
local function deserialize(str)
    if not str or str == "" then return nil end

    -- Create safe environment for evaluation
    local env = {
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        tonumber = tonumber,
        tostring = tostring,
    }

    -- Try to load the string as a chunk
    local func, err = loadstring("return " .. str)
    if not func then
        return nil, "Parse error: " .. tostring(err)
    end

    -- Set environment (for Lua 5.1)
    setfenv(func, env)

    -- Execute and return result
    local success, result = pcall(func)
    if not success then
        return nil, "Execution error: " .. tostring(result)
    end

    return result
end

---------------------------------------------------------------------------
-- Export Functions
---------------------------------------------------------------------------

-- Export all contacts
function IE:ExportContacts()
    local contacts = {}
    for key, contact in pairs(ns.db.global.contacts or {}) do
        contacts[key] = {
            name = contact.name,
            status = contact.status,
            source = contact.source,
            classFile = contact.classFile,
            classLabel = contact.classLabel,
            level = contact.level,
            race = contact.race,
            zone = contact.zone,
            guild = contact.guild,
            crossRealm = contact.crossRealm,
            optedIn = contact.optedIn,
            tags = contact.tags,
            notes = contact.notes,
            firstSeen = contact.firstSeen,
            lastSeen = contact.lastSeen,
        }
    end

    return serialize(contacts)
end

-- Export templates
function IE:ExportTemplates()
    local templates = ns.db.profile.customTemplates or {}
    return serialize(templates)
end

-- Export settings (profile)
function IE:ExportSettings()
    local settings = {
        guildName = ns.db.profile.guildName,
        discord = ns.db.profile.discord,
        raidDays = ns.db.profile.raidDays,
        goal = ns.db.profile.goal,
        keywords = ns.db.profile.keywords,
        inviteKeywordOnly = ns.db.profile.inviteKeywordOnly,
        inviteKeyword = ns.db.profile.inviteKeyword,
        cooldownInvite = ns.db.profile.cooldownInvite,
        cooldownWhisper = ns.db.profile.cooldownWhisper,
        maxActionsPerMinute = ns.db.profile.maxActionsPerMinute,
        maxInvitesPerHour = ns.db.profile.maxInvitesPerHour,
        maxWhispersPerHour = ns.db.profile.maxWhispersPerHour,
        respectAFK = ns.db.profile.respectAFK,
        respectDND = ns.db.profile.respectDND,
        scanLevelMin = ns.db.profile.scanLevelMin,
        scanLevelMax = ns.db.profile.scanLevelMax,
        scanLevelSlice = ns.db.profile.scanLevelSlice,
        scanIncludeGuilded = ns.db.profile.scanIncludeGuilded,
        scanIncludeCrossRealm = ns.db.profile.scanIncludeCrossRealm,
    }

    return serialize(settings)
end

-- Export full backup (everything)
function IE:ExportFullBackup()
    local backup = {
        version = "3.0.0",
        timestamp = ns.Util_Now(),
        realm = GetRealmName(),
        character = UnitName("player"),
        contacts = {},
        templates = ns.db.profile.customTemplates or {},
        settings = {},
        statistics = ns.db.global.statistics,
    }

    -- Copy contacts
    for key, contact in pairs(ns.db.global.contacts or {}) do
        backup.contacts[key] = contact
    end

    -- Copy settings
    backup.settings = {
        guildName = ns.db.profile.guildName,
        discord = ns.db.profile.discord,
        raidDays = ns.db.profile.raidDays,
        goal = ns.db.profile.goal,
        keywords = ns.db.profile.keywords,
        inviteKeywordOnly = ns.db.profile.inviteKeywordOnly,
        inviteKeyword = ns.db.profile.inviteKeyword,
        cooldownInvite = ns.db.profile.cooldownInvite,
        cooldownWhisper = ns.db.profile.cooldownWhisper,
        maxActionsPerMinute = ns.db.profile.maxActionsPerMinute,
        maxInvitesPerHour = ns.db.profile.maxInvitesPerHour,
        maxWhispersPerHour = ns.db.profile.maxWhispersPerHour,
        respectAFK = ns.db.profile.respectAFK,
        respectDND = ns.db.profile.respectDND,
        scanLevelMin = ns.db.profile.scanLevelMin,
        scanLevelMax = ns.db.profile.scanLevelMax,
        scanLevelSlice = ns.db.profile.scanLevelSlice,
        scanIncludeGuilded = ns.db.profile.scanIncludeGuilded,
        scanIncludeCrossRealm = ns.db.profile.scanIncludeCrossRealm,
    }

    return serialize(backup)
end

---------------------------------------------------------------------------
-- Import Functions
---------------------------------------------------------------------------

-- Import contacts (merge or replace)
function IE:ImportContacts(dataStr, mode)
    mode = mode or "merge"  -- "merge" or "replace"

    local data, err = deserialize(dataStr)
    if not data then
        return false, err
    end

    if mode == "replace" then
        ns.db.global.contacts = {}
    end

    local imported = 0
    local skipped = 0

    for key, contact in pairs(data) do
        key = ns.Util_Key(key)
        if key then
            if mode == "merge" and ns.db.global.contacts[key] then
                skipped = skipped + 1
            else
                ns.db.global.contacts[key] = contact
                imported = imported + 1
            end
        end
    end

    ns.UI_Refresh()
    return true, ("Importé: %d, Ignoré: %d"):format(imported, skipped)
end

-- Import templates (merge or replace)
function IE:ImportTemplates(dataStr, mode)
    mode = mode or "merge"

    local data, err = deserialize(dataStr)
    if not data then
        return false, err
    end

    if not ns.db.profile.customTemplates then
        ns.db.profile.customTemplates = {}
    end

    if mode == "replace" then
        ns.db.profile.customTemplates = data
    else
        for id, text in pairs(data) do
            ns.db.profile.customTemplates[id] = text
        end
    end

    ns.Templates_Init()
    ns.UI_Refresh()
    return true, "Templates importés avec succès"
end

-- Import settings
function IE:ImportSettings(dataStr)
    local data, err = deserialize(dataStr)
    if not data then
        return false, err
    end

    for key, value in pairs(data) do
        if ns.db.profile[key] ~= nil then
            ns.db.profile[key] = value
        end
    end

    ns.UI_Refresh()
    return true, "Paramètres importés avec succès"
end

-- Import full backup
function IE:ImportFullBackup(dataStr, options)
    options = options or {
        contacts = true,
        templates = true,
        settings = true,
        statistics = false,
    }

    local backup, err = deserialize(dataStr)
    if not backup then
        return false, err
    end

    local results = {}

    if options.contacts and backup.contacts then
        ns.db.global.contacts = backup.contacts
        results.contacts = "OK"
    end

    if options.templates and backup.templates then
        ns.db.profile.customTemplates = backup.templates
        ns.Templates_Init()
        results.templates = "OK"
    end

    if options.settings and backup.settings then
        for key, value in pairs(backup.settings) do
            if ns.db.profile[key] ~= nil then
                ns.db.profile[key] = value
            end
        end
        results.settings = "OK"
    end

    if options.statistics and backup.statistics then
        ns.db.global.statistics = backup.statistics
        results.statistics = "OK"
    end

    ns.UI_Refresh()
    return true, results
end

---------------------------------------------------------------------------
-- Auto-backup System
---------------------------------------------------------------------------

function IE:CreateAutoBackup()
    local backup = self:ExportFullBackup()
    local timestamp = date("%Y%m%d_%H%M%S")
    local filename = ("CR_Backup_%s_%s"):format(GetRealmName():gsub(" ", ""), timestamp)

    -- Store in saved variables (limited to last 5 backups)
    if not ns.db.global.autoBackups then
        ns.db.global.autoBackups = {}
    end

    table.insert(ns.db.global.autoBackups, 1, {
        timestamp = ns.Util_Now(),
        name = filename,
        data = backup,
    })

    -- Keep only last 5 backups
    while #ns.db.global.autoBackups > 5 do
        table.remove(ns.db.global.autoBackups)
    end

    return filename
end

function IE:GetAutoBackups()
    return ns.db.global.autoBackups or {}
end

function IE:RestoreAutoBackup(index)
    local backups = self:GetAutoBackups()
    local backup = backups[index]
    if not backup then
        return false, "Backup introuvable"
    end

    return self:ImportFullBackup(backup.data, {
        contacts = true,
        templates = true,
        settings = true,
        statistics = true,
    })
end
