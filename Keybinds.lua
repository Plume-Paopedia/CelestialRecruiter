local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Keybind System
-- Quick keyboard shortcuts for common actions
-- ═══════════════════════════════════════════════════════════════════

-- Register keybindings with WoW's binding system
_G.BINDING_HEADER_CELESTIALRECRUITER = "CelestialRecruiter"

_G.BINDING_NAME_CR_TOGGLE = "Ouvrir/Fermer l'interface"
_G.BINDING_NAME_CR_SCAN = "Lancer un scan"
_G.BINDING_NAME_CR_NEXT_RECRUIT = "Recruter suivant dans la file"
_G.BINDING_NAME_CR_NEXT_INVITE = "Inviter suivant dans la file"
_G.BINDING_NAME_CR_NEXT_WHISPER = "Message suivant dans la file"
_G.BINDING_NAME_CR_AUTO_TOGGLE = "Démarrer/Arrêter auto-recrutement"
_G.BINDING_NAME_CR_TAB_SCANNER = "Aller à l'onglet Scanner"
_G.BINDING_NAME_CR_TAB_QUEUE = "Aller à l'onglet File d'attente"
_G.BINDING_NAME_CR_TAB_INBOX = "Aller à l'onglet Boîte"
_G.BINDING_NAME_CR_TAB_SETTINGS = "Aller à l'onglet Réglages"

-- Keybind handler functions
function CR_ToggleUI()
    if ns.UI_Toggle then
        ns.UI_Toggle()
    end
end

function CR_Scan()
    if ns.Scanner_ScanStep then
        local ok, why = ns.Scanner_ScanStep(false)
        if not ok and why then
            ns.Util_Print("Scan: " .. (ns.UIWidgets and ns.UIWidgets.reasonFr and ns.UIWidgets.reasonFr(why) or tostring(why)))
        end
    end
end

function CR_RecruitNext()
    if not ns.DB_QueueList then return end
    local queue = ns.DB_QueueList()
    if #queue == 0 then
        if ns.Util_Print then ns.Util_Print("File d'attente vide") end
        return
    end

    local key = queue[1]
    if ns.Queue_Recruit then
        local template = (ns.db and ns.db.profile and ns._ui_tpl) or "default"
        local ok, why = ns.Queue_Recruit(key, template)
        if not ok then
            if ns.Util_Print then ns.Util_Print("Échec : " .. tostring(why)) end
        elseif ns.DB_QueueRemove then
            ns.DB_QueueRemove(key)
        end
    end
end

function CR_InviteNext()
    if not ns.DB_QueueList then return end
    local queue = ns.DB_QueueList()
    if #queue == 0 then
        if ns.Util_Print then ns.Util_Print("File d'attente vide") end
        return
    end

    local key = queue[1]
    if ns.Queue_Invite then
        local ok, why = ns.Queue_Invite(key)
        if not ok then
            if ns.Util_Print then ns.Util_Print("Échec : " .. tostring(why)) end
        end
    end
end

function CR_WhisperNext()
    if not ns.DB_QueueList then return end
    local queue = ns.DB_QueueList()
    if #queue == 0 then
        if ns.Util_Print then ns.Util_Print("File d'attente vide") end
        return
    end

    local key = queue[1]
    if ns.Queue_Whisper then
        local template = (ns.db and ns.db.profile and ns._ui_tpl) or "default"
        local ok, why = ns.Queue_Whisper(key, template)
        if not ok then
            if ns.Util_Print then ns.Util_Print("Échec : " .. tostring(why)) end
        end
    end
end

function CR_AutoToggle()
    if ns.AutoRecruiter then
        ns.AutoRecruiter:Toggle()
    end
end

function CR_TabScanner()
    if ns.UI_Toggle and ns.UI and ns.UI.mainFrame then
        if not ns.UI.mainFrame:IsShown() then
            ns.UI.mainFrame:Show()
        end
        -- Switch to Scanner tab (assuming SwitchTab exists in UI.lua scope)
        if ns.UI.active ~= "Scanner" then
            -- We need to expose a public API for tab switching
            ns.UI_SwitchTab("Scanner")
        end
    end
end

function CR_TabQueue()
    if ns.UI_Toggle and ns.UI and ns.UI.mainFrame then
        if not ns.UI.mainFrame:IsShown() then
            ns.UI.mainFrame:Show()
        end
        if ns.UI.active ~= "Queue" then
            ns.UI_SwitchTab("Queue")
        end
    end
end

function CR_TabInbox()
    if ns.UI_Toggle and ns.UI and ns.UI.mainFrame then
        if not ns.UI.mainFrame:IsShown() then
            ns.UI.mainFrame:Show()
        end
        if ns.UI.active ~= "Inbox" then
            ns.UI_SwitchTab("Inbox")
        end
    end
end

function CR_TabSettings()
    if ns.UI_Toggle and ns.UI and ns.UI.mainFrame then
        if not ns.UI.mainFrame:IsShown() then
            ns.UI.mainFrame:Show()
        end
        if ns.UI.active ~= "Settings" then
            ns.UI_SwitchTab("Settings")
        end
    end
end

-- Public API for tab switching (expose the internal SwitchTab function)
function ns.UI_SwitchTab(tabKey)
    -- This will be called from UI.lua's SwitchTab function
    -- We'll add this hook in UI.lua
end
