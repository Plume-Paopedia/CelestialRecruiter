local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Import/Export System
-- Backup, restore, and share data between characters/accounts
-- ═══════════════════════════════════════════════════════════════════

ns.ImportExport = ns.ImportExport or {}
local IE = ns.ImportExport

-- Escape a string for safe Lua table constructor syntax
local function escapeStr(s)
    return s:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("%z", "")
end

-- Serialize table to string (valid Lua table constructor)
local function serialize(t, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local result = "{\n"

    for k, v in pairs(t) do
        local key
        if type(k) == "string" then
            key = '["' .. escapeStr(k) .. '"]'
        else
            key = "[" .. tostring(k) .. "]"
        end
        result = result .. indentStr .. "  " .. key .. " = "

        if type(v) == "table" then
            result = result .. serialize(v, indent + 1)
        elseif type(v) == "string" then
            result = result .. '"' .. escapeStr(v) .. '"'
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

-- Maximum import size (1 MB) to prevent memory issues
local MAX_IMPORT_SIZE = 1048576

-- Deserialize string to table (safe eval with sandboxed environment)
local function deserialize(str)
    if not str or str == "" then return nil end

    -- Reject oversized input
    if #str > MAX_IMPORT_SIZE then
        return nil, "Donnees trop volumineuses (max 1 Mo)"
    end

    -- Basic structure validation: must start with a table constructor
    local trimmed = str:match("^%s*(.-)%s*$")
    if not trimmed or trimmed:sub(1, 1) ~= "{" then
        return nil, "Format invalide : les donnees doivent commencer par '{'"
    end

    -- Create safe environment (no I/O, no OS, no dangerous functions)
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
        return nil, "Erreur d'analyse : " .. tostring(err)
    end

    -- Set environment (for Lua 5.1)
    setfenv(func, env)

    -- Execute and return result
    local success, result = pcall(func)
    if not success then
        return nil, "Erreur d'execution : " .. tostring(result)
    end

    if type(result) ~= "table" then
        return nil, "Format invalide : resultat attendu de type table"
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
        return false, "Sauvegarde introuvable"
    end

    return self:ImportFullBackup(backup.data, {
        contacts = true,
        templates = true,
        settings = true,
        statistics = true,
    })
end

---------------------------------------------------------------------------
-- Web Export (for website dashboard)
---------------------------------------------------------------------------

-- Export data in a format optimized for the web dashboard
function IE:ExportForWeb()
    local backup = {
        version = "web-1.0",
        timestamp = ns.Util_Now(),
        realm = GetRealmName(),
        character = UnitName("player"),
        contacts = {},
        queue = {},
        statistics = ns.db.global.statistics,
        templates = ns.db.profile.customTemplates or {},
        settings = {
            guildName = ns.db.profile.guildName,
            discord = ns.db.profile.discord,
            raidDays = ns.db.profile.raidDays,
            goal = ns.db.profile.goal,
            keywords = ns.db.profile.keywords,
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
        },
        campaigns = ns.db.global.campaigns or {},
        discordNotify = {
            enabled = ns.db.profile.discordNotify and ns.db.profile.discordNotify.enabled or false,
            summaryMode = ns.db.profile.discordNotify and ns.db.profile.discordNotify.summaryMode ~= false,
            autoFlush = ns.db.profile.discordNotify and ns.db.profile.discordNotify.autoFlush ~= false,
            flushDelay = ns.db.profile.discordNotify and ns.db.profile.discordNotify.flushDelay or 30,
            events = ns.db.profile.discordNotify and ns.db.profile.discordNotify.events or {},
            webhookConfigured = (ns.db.profile.discordNotify and ns.db.profile.discordNotify.webhookUrl and ns.db.profile.discordNotify.webhookUrl ~= "") and true or false,
        },
        discordQueue = ns.db.global.discordQueue or {},
        blacklist = ns.db.global.blacklist or {},
    }

    -- Copy contacts with relevant fields
    for key, contact in pairs(ns.db.global.contacts or {}) do
        backup.contacts[key] = {
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
            lastWhisperIn = contact.lastWhisperIn,
            lastWhisperOut = contact.lastWhisperOut,
            lastInviteAt = contact.lastInviteAt,
        }
    end

    -- Copy queue
    for _, key in ipairs(ns.db.global.queue or {}) do
        table.insert(backup.queue, key)
    end

    return serialize(backup)
end

-- Reusable export dialog frame (persisted to avoid recreation)
local exportFrame = nil

-- Open a copy dialog with web export data
function IE:ShowWebExportDialog()
    -- Tier gate: web export requires Recruteur+
    if ns.Tier and not ns.Tier:CanUse("web_export") then
        ns.Tier:ShowUpgrade("web_export")
        return
    end

    local data = self:ExportForWeb()

    if not data or data == "" then
        ns.Util_Print("|cffff0000[Web Export]|r Erreur : aucune donnee a exporter.")
        return
    end

    local W = ns.UIWidgets
    local C = W and W.C or {}
    local SOLID = W and W.SOLID or "Interface\\Buttons\\WHITE8x8"
    local EDGE = W and W.EDGE or "Interface\\Tooltips\\UI-Tooltip-Border"

    -- Create frame once, reuse afterwards
    if not exportFrame then
        local f = CreateFrame("Frame", "CRWebExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(640, 480)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        -- Backdrop
        f:SetBackdrop({
            bgFile = SOLID, edgeFile = EDGE,
            edgeSize = 14,
            insets = {left = 3, right = 3, top = 3, bottom = 3},
        })
        local bg = C.bg or {0.05, 0.06, 0.11, 0.97}
        local border = C.border or {0.20, 0.26, 0.46, 0.60}
        f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        f:SetBackdropBorderColor(border[1], border[2], border[3], 0.8)

        -- Title bar
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("|cffC9AA71CelestialRecruiter|r — Web Export")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Instructions
        local instrText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instrText:SetPoint("TOPLEFT", 16, -38)
        instrText:SetPoint("TOPRIGHT", -16, -38)
        instrText:SetJustifyH("LEFT")
        instrText:SetText("|cffC9AA71Le texte est deja selectionne.|r Appuyez sur |cff00d1ffCtrl+C|r pour copier, puis collez sur le dashboard web.")
        instrText:SetWordWrap(true)
        f.instrText = instrText

        -- Data size label
        local sizeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sizeLabel:SetPoint("TOPLEFT", 16, -62)
        local dim = C.dim or {0.55, 0.58, 0.66}
        sizeLabel:SetTextColor(dim[1], dim[2], dim[3])
        f.sizeLabel = sizeLabel

        -- ScrollFrame + EditBox for the export data
        local scrollFrame = CreateFrame("ScrollFrame", "CRWebExportScroll", f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 16, -82)
        scrollFrame:SetPoint("BOTTOMRIGHT", -36, 52)

        -- Scroll background
        local scrollBg = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
        scrollBg:SetPoint("TOPLEFT", -4, 4)
        scrollBg:SetPoint("BOTTOMRIGHT", 24, -4)
        scrollBg:SetFrameLevel(scrollFrame:GetFrameLevel() - 1)
        scrollBg:SetBackdrop({
            bgFile = SOLID,
            edgeFile = EDGE,
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        local panelC = C.panel or {0.08, 0.09, 0.16, 0.90}
        scrollBg:SetBackdropColor(panelC[1], panelC[2], panelC[3], panelC[4])
        scrollBg:SetBackdropBorderColor(0.15, 0.15, 0.25, 0.5)

        local editBox = CreateFrame("EditBox", "CRWebExportEditBox", scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetWidth(scrollFrame:GetWidth() - 10)
        editBox:SetTextColor(0.82, 0.84, 0.88)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
        -- Prevent editing: revert any changes
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput and f._exportData then
                self:SetText(f._exportData)
                C_Timer.After(0.05, function()
                    self:HighlightText()
                end)
            end
        end)

        scrollFrame:SetScrollChild(editBox)
        f.editBox = editBox
        f.scrollFrame = scrollFrame

        -- Bottom buttons
        local copyHint = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        copyHint:SetPoint("BOTTOMLEFT", 16, 18)
        copyHint:SetText("|cff00d1ffCtrl+A|r tout selectionner  |cff00d1ffCtrl+C|r copier  |cff00d1ffEchap|r fermer")
        local dimC = C.dim or {0.55, 0.58, 0.66}
        copyHint:SetTextColor(dimC[1], dimC[2], dimC[3])

        local closeBtn2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn2:SetSize(100, 24)
        closeBtn2:SetPoint("BOTTOMRIGHT", -16, 14)
        closeBtn2:SetText("Fermer")
        closeBtn2:SetScript("OnClick", function() f:Hide() end)

        -- ESC to close
        tinsert(UISpecialFrames, "CRWebExportFrame")

        exportFrame = f
    end

    -- Update content
    exportFrame._exportData = data
    exportFrame.editBox:SetText(data)

    -- Size info
    local sizeKB = string.format("%.1f KB", #data / 1024)
    exportFrame.sizeLabel:SetText("Taille: " .. sizeKB .. " | Version: web-1.0")

    -- Update editbox width to match scroll frame
    exportFrame.editBox:SetWidth(exportFrame.scrollFrame:GetWidth() - 10)

    exportFrame:Show()

    -- Auto-select all text after a short delay (ensures rendering is done)
    C_Timer.After(0.1, function()
        if exportFrame and exportFrame:IsShown() and exportFrame.editBox then
            exportFrame.editBox:SetFocus()
            exportFrame.editBox:HighlightText()
        end
    end)

    ns.Util_Print("|cffC9AA71[Web Export]|r Fenetre ouverte. Appuyez sur Ctrl+C pour copier les donnees.")
end

---------------------------------------------------------------------------
-- Web Import (apply patches from website dashboard)
---------------------------------------------------------------------------

-- Whitelisted settings keys that can be patched from web
local PATCH_SETTINGS_WHITELIST = {
    guildName = "string",
    discord = "string",
    raidDays = "string",
    goal = "string",
    cooldownInvite = "number",
    cooldownWhisper = "number",
    maxActionsPerMinute = "number",
    maxInvitesPerHour = "number",
    maxWhispersPerHour = "number",
    respectAFK = "boolean",
    respectDND = "boolean",
    scanLevelMin = "number",
    scanLevelMax = "number",
    scanLevelSlice = "number",
    scanIncludeGuilded = "boolean",
    scanIncludeCrossRealm = "boolean",
}

-- Validate a web patch without applying it
-- Returns: success (bool), result (table: summary or {error=string})
function IE:ValidateWebPatch(dataStr)
    if not dataStr or dataStr == "" then
        return false, {error = "Aucune donnee a importer."}
    end

    local patch, err = deserialize(dataStr)
    if not patch then
        return false, {error = "Erreur d'analyse : " .. (err or "inconnu")}
    end

    if patch._patchVersion ~= "web-patch-1.0" then
        return false, {error = "Version de patch incompatible (attendu: web-patch-1.0)"}
    end

    local summary = {
        templatesCount = 0,
        settingsCount = 0,
        blacklistCount = 0,
        errors = {},
    }

    -- Validate templates
    if patch.templates then
        if type(patch.templates) ~= "table" then
            table.insert(summary.errors, "templates: doit etre une table")
        else
            for id, text in pairs(patch.templates) do
                if type(id) ~= "string" then
                    table.insert(summary.errors, "templates: cle invalide (" .. tostring(id) .. ")")
                elseif type(text) ~= "string" then
                    table.insert(summary.errors, "templates[" .. id .. "]: doit etre une chaine")
                elseif #text > 500 then
                    table.insert(summary.errors, "templates[" .. id .. "]: trop long (" .. #text .. " > 500)")
                else
                    summary.templatesCount = summary.templatesCount + 1
                end
            end
        end
    end

    -- Validate settings
    if patch.settings then
        if type(patch.settings) ~= "table" then
            table.insert(summary.errors, "settings: doit etre une table")
        else
            for key, value in pairs(patch.settings) do
                local expectedType = PATCH_SETTINGS_WHITELIST[key]
                if not expectedType then
                    table.insert(summary.errors, "settings[" .. tostring(key) .. "]: cle inconnue (ignoree)")
                elseif type(value) ~= expectedType then
                    table.insert(summary.errors, "settings[" .. key .. "]: type invalide (attendu " .. expectedType .. ", recu " .. type(value) .. ")")
                else
                    summary.settingsCount = summary.settingsCount + 1
                end
            end
        end
    end

    -- Validate blacklist
    if patch.blacklist then
        if type(patch.blacklist) ~= "table" then
            table.insert(summary.errors, "blacklist: doit etre une table")
        else
            for key, val in pairs(patch.blacklist) do
                if type(key) ~= "string" then
                    table.insert(summary.errors, "blacklist: cle invalide (" .. tostring(key) .. ")")
                elseif val ~= true then
                    table.insert(summary.errors, "blacklist[" .. key .. "]: valeur doit etre true")
                else
                    summary.blacklistCount = summary.blacklistCount + 1
                end
            end
        end
    end

    -- If there are blocking errors (type errors), reject
    local hasBlockingErrors = false
    for _, e in ipairs(summary.errors) do
        if not e:find("ignoree") then
            hasBlockingErrors = true
            break
        end
    end

    if hasBlockingErrors then
        return false, {error = table.concat(summary.errors, "\n")}
    end

    local totalChanges = summary.templatesCount + summary.settingsCount + summary.blacklistCount
    if totalChanges == 0 then
        return false, {error = "Le patch ne contient aucune modification."}
    end

    return true, summary
end

-- Apply a validated web patch
function IE:ApplyWebPatch(dataStr)
    local success, result = self:ValidateWebPatch(dataStr)
    if not success then
        return false, result.error
    end

    local patch = deserialize(dataStr)
    local applied = {}

    -- Apply templates
    if patch.templates then
        ns.db.profile.customTemplates = patch.templates
        if ns.Templates_Init then
            ns.Templates_Init()
        end
        table.insert(applied, result.templatesCount .. " templates")
    end

    -- Apply settings (only whitelisted keys)
    if patch.settings then
        for key, value in pairs(patch.settings) do
            if PATCH_SETTINGS_WHITELIST[key] and type(value) == PATCH_SETTINGS_WHITELIST[key] then
                ns.db.profile[key] = value
            end
        end
        table.insert(applied, result.settingsCount .. " parametres")
    end

    -- Apply blacklist
    if patch.blacklist then
        ns.db.global.blacklist = patch.blacklist
        table.insert(applied, result.blacklistCount .. " joueurs en blacklist")
    end

    -- Refresh UI
    if ns.UI_Refresh then
        ns.UI_Refresh()
    end

    local msg = "Patch applique : " .. table.concat(applied, ", ")
    ns.Util_Print("|cff4ade80[Web Import]|r " .. msg)
    return true, msg
end

-- Reusable import dialog frame
local importFrame = nil

-- Open a paste dialog for web import
function IE:ShowWebImportDialog()
    local W = ns.UIWidgets
    local C = W and W.C or {}
    local SOLID = W and W.SOLID or "Interface\\Buttons\\WHITE8x8"
    local EDGE = W and W.EDGE or "Interface\\Tooltips\\UI-Tooltip-Border"

    if not importFrame then
        local f = CreateFrame("Frame", "CRWebImportFrame", UIParent, "BackdropTemplate")
        f:SetSize(640, 520)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        f:SetBackdrop({
            bgFile = SOLID, edgeFile = EDGE,
            edgeSize = 14,
            insets = {left = 3, right = 3, top = 3, bottom = 3},
        })
        local bg = C.bg or {0.05, 0.06, 0.11, 0.97}
        local border = C.border or {0.20, 0.26, 0.46, 0.60}
        f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        f:SetBackdropBorderColor(border[1], border[2], border[3], 0.8)

        -- Title
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("|cffC9AA71CelestialRecruiter|r — Web Import")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Instructions
        local instrText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instrText:SetPoint("TOPLEFT", 16, -38)
        instrText:SetPoint("TOPRIGHT", -16, -38)
        instrText:SetJustifyH("LEFT")
        instrText:SetText("Collez le patch genere par le dashboard web ci-dessous, puis cliquez |cff00d1ffValider|r.")
        instrText:SetWordWrap(true)

        -- Status text (for results/errors)
        local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("TOPLEFT", 16, -62)
        statusText:SetPoint("TOPRIGHT", -16, -62)
        statusText:SetJustifyH("LEFT")
        statusText:SetWordWrap(true)
        statusText:SetText("")
        f.statusText = statusText

        -- ScrollFrame + EditBox for pasting
        local scrollFrame = CreateFrame("ScrollFrame", "CRWebImportScroll", f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 16, -90)
        scrollFrame:SetPoint("BOTTOMRIGHT", -36, 56)

        local scrollBg = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
        scrollBg:SetPoint("TOPLEFT", -4, 4)
        scrollBg:SetPoint("BOTTOMRIGHT", 24, -4)
        scrollBg:SetFrameLevel(scrollFrame:GetFrameLevel() - 1)
        scrollBg:SetBackdrop({
            bgFile = SOLID, edgeFile = EDGE,
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2},
        })
        local panelC = C.panel or {0.08, 0.09, 0.16, 0.90}
        scrollBg:SetBackdropColor(panelC[1], panelC[2], panelC[3], panelC[4])
        scrollBg:SetBackdropBorderColor(0.15, 0.15, 0.25, 0.5)

        local editBox = CreateFrame("EditBox", "CRWebImportEditBox", scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(0) -- 0 = unlimited (default 255 truncates pasted data!)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetWidth(scrollFrame:GetWidth() - 10)
        editBox:SetTextColor(0.82, 0.84, 0.88)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
        editBox:SetScript("OnTextChanged", function()
            -- Reset status when user edits
            f.statusText:SetText("")
            if f.applyBtn then
                f.applyBtn:Disable()
                f.applyBtn:SetText("Appliquer")
            end
            if f.applyReloadBtn then
                f.applyReloadBtn:Disable()
            end
        end)

        scrollFrame:SetScrollChild(editBox)
        f.editBox = editBox
        f.scrollFrame = scrollFrame

        -- Validate button
        local validateBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        validateBtn:SetSize(120, 26)
        validateBtn:SetPoint("BOTTOMLEFT", 16, 16)
        validateBtn:SetText("Valider")
        validateBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            if not text or text == "" then
                f.statusText:SetText("|cffff4444Collez d'abord les donnees du patch.|r")
                return
            end

            local ok, res = IE:ValidateWebPatch(text)
            if ok then
                local parts = {}
                if res.templatesCount > 0 then table.insert(parts, res.templatesCount .. " templates") end
                if res.settingsCount > 0 then table.insert(parts, res.settingsCount .. " parametres") end
                if res.blacklistCount > 0 then table.insert(parts, res.blacklistCount .. " blacklist") end
                f.statusText:SetText("|cff4ade80Patch valide :|r " .. table.concat(parts, ", ") .. ". Cliquez |cff00d1ffAppliquer|r pour confirmer.")
                f.applyBtn:Enable()
                if f.applyReloadBtn then f.applyReloadBtn:Enable() end
            else
                f.statusText:SetText("|cffff4444" .. (res.error or "Erreur inconnue") .. "|r")
                f.applyBtn:Disable()
                if f.applyReloadBtn then f.applyReloadBtn:Disable() end
            end
        end)
        f.validateBtn = validateBtn

        -- Apply button
        local applyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        applyBtn:SetSize(120, 26)
        applyBtn:SetPoint("LEFT", validateBtn, "RIGHT", 10, 0)
        applyBtn:SetText("Appliquer")
        applyBtn:Disable()
        applyBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            local ok, msg = IE:ApplyWebPatch(text)
            if ok then
                f.statusText:SetText("|cff4ade80" .. msg .. "|r")
                applyBtn:Disable()
                applyBtn:SetText("Applique !")
            else
                f.statusText:SetText("|cffff4444" .. (msg or "Erreur") .. "|r")
            end
        end)
        f.applyBtn = applyBtn

        -- Apply & Reload button
        local applyReloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        applyReloadBtn:SetSize(160, 26)
        applyReloadBtn:SetPoint("LEFT", applyBtn, "RIGHT", 10, 0)
        applyReloadBtn:SetText("Appliquer et Reload")
        applyReloadBtn:Disable()
        applyReloadBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            local ok, msg = IE:ApplyWebPatch(text)
            if ok then
                f.statusText:SetText("|cff4ade80" .. msg .. "|r Rechargement...")
                C_Timer.After(0.5, function()
                    ReloadUI()
                end)
            else
                f.statusText:SetText("|cffff4444" .. (msg or "Erreur") .. "|r")
            end
        end)
        f.applyReloadBtn = applyReloadBtn

        -- Close button (bottom)
        local closeBtn2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn2:SetSize(100, 26)
        closeBtn2:SetPoint("BOTTOMRIGHT", -16, 16)
        closeBtn2:SetText("Fermer")
        closeBtn2:SetScript("OnClick", function() f:Hide() end)

        -- ESC to close
        tinsert(UISpecialFrames, "CRWebImportFrame")

        importFrame = f
    end

    -- Reset state
    importFrame.editBox:SetText("")
    importFrame.statusText:SetText("")
    importFrame.applyBtn:Disable()
    importFrame.applyBtn:SetText("Appliquer")
    if importFrame.applyReloadBtn then importFrame.applyReloadBtn:Disable() end
    importFrame.editBox:SetWidth(importFrame.scrollFrame:GetWidth() - 10)

    importFrame:Show()
    importFrame.editBox:SetFocus()

    ns.Util_Print("|cffC9AA71[Web Import]|r Collez le patch du dashboard web et cliquez Valider.")
end
