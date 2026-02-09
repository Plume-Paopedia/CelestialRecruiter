local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Inbox (Boite) Tab
-- ═══════════════════════════════════════════════════════════════════

local id = {}

---------------------------------------------------------------------------
-- Row Factory
---------------------------------------------------------------------------
local function MakeInboxRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(W.ROW_H)
    row:SetBackdrop({bgFile = W.SOLID})
    W.SetRowBG(row, i)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(s)
        s:SetBackdropColor(unpack(C.hover))
        W.ShowPlayerTooltip(s, s._boundKey)
    end)
    row:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(s._bgc))
        W.HidePlayerTooltip()
    end)

    -- Player name
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", 10, 0)
    row.name:SetWidth(200)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Info (status, flags, time)
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.info:SetPoint("LEFT", 218, 0)
    row.info:SetWidth(310)
    row.info:SetJustifyH("LEFT")
    row.info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.info:SetWordWrap(false)

    -- Blacklist button (rightmost)
    row.blBtn = W.MakeBtn(row, "Blacklist", 72, "d", nil)
    row.blBtn:SetPoint("RIGHT", -6, 0)

    -- Ignore button
    row.ignBtn = W.MakeBtn(row, "Ignorer 7j", 80, "n", nil)
    row.ignBtn:SetPoint("RIGHT", row.blBtn, "LEFT", -4, 0)

    -- Add to queue button
    row.addBtn = W.MakeBtn(row, "+ Liste", 66, "s", nil)
    row.addBtn:SetPoint("RIGHT", row.ignBtn, "LEFT", -4, 0)

    W.AddRowGlow(row)
    return row
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function ns.UI_BuildInbox(parent)
    id.scroll = W.MakeScroll(parent)
    id.scroll.frame:SetPoint("TOPLEFT", 8, -8)
    id.scroll.frame:SetPoint("BOTTOMRIGHT", -8, 8)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshInbox()
    if not id.scroll then return end

    local search = ns._ui_search or ""
    local now = ns.Util_Now()

    local allKeys = ns.DB_ListContactsForInbox()
    local filtered = {}
    for _, key in ipairs(allKeys) do
        local c = ns.DB_GetContact(key)
        if c and not ns.DB_IsBlacklisted(key)
            and (c.lastWhisperIn or 0) > 0
            and W.matchSearch(search,
                key, c.status or "", c.notes or "",
                c.optedIn and "optin" or "", c.source or ""
            )
        then
            filtered[#filtered + 1] = {key = key, contact = c}
        end
    end

    local scroll = id.scroll
    local rows = scroll.rows

    if #filtered == 0 then
        scroll:ShowEmpty("|cff8bc5ff*|r", "Aucun message entrant")
        for _, r in ipairs(rows) do r:Hide() end
        scroll:SetH(scroll.sf:GetHeight())
        return
    end
    scroll:HideEmpty()

    for i, item in ipairs(filtered) do
        local key, c = item.key, item.contact
        if not rows[i] then rows[i] = MakeInboxRow(scroll.child, i) end
        local row = rows[i]
        row:Show()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -(i - 1) * W.ROW_H)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")

        -- Name
        row.name:SetText("|cff00aaff" .. key .. "|r")

        -- Flags + time
        local flags = {}
        if c.optedIn then flags[#flags + 1] = "|cff33e07aopt-in|r" end
        if c.source == "scanner" then flags[#flags + 1] = "scanner" end
        local ignored = c.status == "ignored" and (c.ignoredUntil or 0) > now
        if ignored then flags[#flags + 1] = "|cffffb347ignore|r" end
        local flagStr = #flags > 0 and ("  " .. table.concat(flags, " ")) or ""
        row.info:SetText(("[%s]%s  dernier: %s"):format(
            c.status or "new", flagStr, ns.Util_FormatAgo(c.lastWhisperIn)
        ))

        -- Update ignore button label (always needed since state can change)
        row.ignBtn:SetLabel(ignored and "Retirer ign." or "Ignorer 7j")

        -- Only rewire buttons if the bound key changed
        if row._boundKey ~= key then
            row._boundKey = key
            row.addBtn:SetScript("OnClick", function()
                if ns.DB_QueueAdd(key) then
                    ns.DB_Log("QUEUE", "Ajout liste: " .. key)
                end
                ns.UI_Refresh()
            end)
            row.blBtn:SetScript("OnClick", function()
                ns.DB_SetBlacklisted(key, true)
                ns.DB_QueueRemove(key)
                ns.DB_Log("BL", "Blacklist: " .. key)
                ns.UI_Refresh()
            end)
        end

        -- Ignore button always rewired (depends on ignored state which changes)
        row.ignBtn:SetScript("OnClick", function()
            if ignored then
                ns.DB_UpsertContact(key, {status = "new", ignoredUntil = 0})
                ns.DB_Log("IGNORE", "Retrait ignore: " .. key)
            else
                ns.DB_UpsertContact(key, {
                    status = "ignored",
                    ignoredUntil = ns.Util_Now() + 7 * 86400,
                })
                ns.DB_QueueRemove(key)
                ns.DB_Log("IGNORE", "Ignore 7j: " .. key)
            end
            ns.UI_Refresh()
        end)
    end

    for i = #filtered + 1, #rows do rows[i]:Hide() end
    scroll:SetH(#filtered * W.ROW_H)
end

---------------------------------------------------------------------------
-- Badge
---------------------------------------------------------------------------
function ns.UI_InboxBadge()
    local n = 0
    for _, key in ipairs(ns.DB_ListContactsForInbox()) do
        local c = ns.DB_GetContact(key)
        if c and not ns.DB_IsBlacklisted(key) and (c.lastWhisperIn or 0) > 0 then
            n = n + 1
        end
    end
    return n > 0 and tostring(n) or ""
end
