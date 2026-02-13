local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Bulk Operations System
-- Multi-select and batch processing for efficient workflow
-- ═══════════════════════════════════════════════════════════════════

ns.BulkOps = ns.BulkOps or {}
local BulkOps = ns.BulkOps

-- Selected contacts storage
local selectedContacts = {}

---------------------------------------------------------------------------
-- Selection Management
---------------------------------------------------------------------------
function BulkOps:ToggleSelection(key)
    if selectedContacts[key] then
        selectedContacts[key] = nil
    else
        selectedContacts[key] = true
    end
end

function BulkOps:IsSelected(key)
    return selectedContacts[key] == true
end

function BulkOps:SelectAll(keys)
    for _, key in ipairs(keys) do
        selectedContacts[key] = true
    end
end

function BulkOps:DeselectAll()
    selectedContacts = {}
end

function BulkOps:GetSelected()
    local selected = {}
    for key, _ in pairs(selectedContacts) do
        table.insert(selected, key)
    end
    return selected
end

function BulkOps:GetSelectedCount()
    local count = 0
    for _, _ in pairs(selectedContacts) do
        count = count + 1
    end
    return count
end

---------------------------------------------------------------------------
-- Bulk Operations
---------------------------------------------------------------------------

-- Bulk Whisper
function BulkOps:BulkWhisper(keys, templateId, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    local total = #keys
    local success = 0
    local failed = 0
    local skipped = 0

    -- Confirmation dialog
    local confirmText = string.format(
        "Envoyer un message à %d contact(s) avec le template '%s'?",
        total,
        templateId or "default"
    )

    -- Show progress
    ns.Notifications_Info("Message en masse", string.format("Traitement de %d contacts...", total))

    -- Process sequentially with delays
    local index = 1
    local processNext
    processNext = function()
        if index > total then
            -- Finished
            ns.Notifications_Success(
                "Message en masse terminé",
                string.format("Succès: %d, Échec: %d, Ignoré: %d", success, failed, skipped)
            )
            if callback then callback(success, failed, skipped) end
            return
        end

        local key = keys[index]
        local ok, reason = ns.Queue_Whisper(key, templateId)

        if ok then
            success = success + 1
        elseif reason == "cooldown" or reason == "afk/dnd" or reason == "rate limit" then
            skipped = skipped + 1
        else
            failed = failed + 1
        end

        index = index + 1

        -- Continue after delay (to avoid spam)
        C_Timer.After(0.5, processNext)
    end

    -- Start processing
    processNext()
end

-- Bulk Invite
function BulkOps:BulkInvite(keys, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    local total = #keys
    local success = 0
    local failed = 0
    local skipped = 0

    ns.Notifications_Info("Invitation en masse", string.format("Traitement de %d contacts...", total))

    local index = 1
    local processNext
    processNext = function()
        if index > total then
            ns.Notifications_Success(
                "Invitation en masse terminée",
                string.format("Succès: %d, Échec: %d, Ignoré: %d", success, failed, skipped)
            )
            if callback then callback(success, failed, skipped) end
            return
        end

        local key = keys[index]
        local ok, reason = ns.Queue_Invite(key)

        if ok then
            success = success + 1
        elseif reason == "cooldown" or reason == "rate limit" then
            skipped = skipped + 1
        else
            failed = failed + 1
        end

        index = index + 1
        C_Timer.After(0.5, processNext)
    end

    processNext()
end

-- Bulk Tag Add
function BulkOps:BulkAddTag(keys, tag, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    if not tag or tag == "" then
        ns.Notifications_Error("Tag invalide", "Le tag ne peut pas être vide")
        return
    end

    local count = 0
    for _, key in ipairs(keys) do
        if ns.DB_AddTag then
            ns.DB_AddTag(key, tag)
            count = count + 1
        end
    end

    ns.Notifications_Success("Tags ajoutés", string.format("Tag '%s' ajouté à %d contact(s)", tag, count))
    ns.UI_Refresh()

    if callback then callback(count) end
end

-- Bulk Tag Remove
function BulkOps:BulkRemoveTag(keys, tag, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    if not tag or tag == "" then
        ns.Notifications_Error("Tag invalide", "Le tag ne peut pas être vide")
        return
    end

    local count = 0
    for _, key in ipairs(keys) do
        if ns.DB_RemoveTag then
            ns.DB_RemoveTag(key, tag)
            count = count + 1
        end
    end

    ns.Notifications_Success("Tags supprimés", string.format("Tag '%s' supprimé de %d contact(s)", tag, count))
    ns.UI_Refresh()

    if callback then callback(count) end
end

-- Bulk Status Change
function BulkOps:BulkSetStatus(keys, status, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    local validStatuses = {
        new = true,
        contacted = true,
        invited = true,
        joined = true,
        ignored = true
    }

    if not validStatuses[status] then
        ns.Notifications_Error("Statut invalide", "Statut non reconnu: " .. tostring(status))
        return
    end

    local count = 0
    for _, key in ipairs(keys) do
        ns.DB_UpsertContact(key, {status = status})
        count = count + 1
    end

    ns.Notifications_Success("Statuts mis à jour", string.format("%d contact(s) marqué(s) comme '%s'", count, status))
    ns.UI_Refresh()

    if callback then callback(count) end
end

-- Bulk Delete from Queue
function BulkOps:BulkRemoveFromQueue(keys, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    local count = 0
    for _, key in ipairs(keys) do
        if ns.DB_QueueRemove then
            ns.DB_QueueRemove(key)
            count = count + 1
        end
    end

    ns.Notifications_Success("Suppression de la file", string.format("%d contact(s) supprimé(s)", count))
    ns.UI_Refresh()

    if callback then callback(count) end
end

-- Bulk Blacklist
function BulkOps:BulkBlacklist(keys, callback)
    if not keys or #keys == 0 then
        ns.Notifications_Warning("Aucune sélection", "Sélectionnez au moins un contact")
        return
    end

    local count = 0
    for _, key in ipairs(keys) do
        if ns.DB_SetBlacklisted then
            ns.DB_SetBlacklisted(key, true)
            count = count + 1
        end
    end

    ns.Notifications_Success("Blacklist", string.format("%d contact(s) blacklisté(s)", count))
    ns.UI_Refresh()

    if callback then callback(count) end
end

---------------------------------------------------------------------------
-- Undo System (simple one-level undo)
---------------------------------------------------------------------------
local undoStack = {}

function BulkOps:SaveUndo(operation, data)
    -- Keep only last undo
    undoStack = {
        operation = operation,
        data = data,
        timestamp = time()
    }
end

function BulkOps:CanUndo()
    return undoStack.operation ~= nil
end

function BulkOps:GetUndoDescription()
    if not undoStack.operation then
        return nil
    end
    return string.format("Annuler: %s", undoStack.operation)
end

function BulkOps:Undo()
    if not undoStack.operation then
        ns.Notifications_Warning("Undo", "Rien à annuler")
        return
    end

    local op = undoStack.operation
    local data = undoStack.data

    if op == "status_change" then
        for _, item in ipairs(data) do
            ns.DB_UpsertContact(item.key, {status = item.oldStatus})
        end
        ns.Notifications_Info("Annulé", "Statuts restaurés")
    elseif op == "add_tag" then
        for _, item in ipairs(data) do
            ns.DB_RemoveTag(item.key, item.tag)
        end
        ns.Notifications_Info("Annulé", "Tags supprimés")
    elseif op == "blacklist" then
        for _, key in ipairs(data) do
            ns.DB_SetBlacklisted(key, false)
        end
        ns.Notifications_Info("Annulé", "Blacklist annulée")
    end

    -- Clear undo stack
    undoStack = {}
    ns.UI_Refresh()
end
