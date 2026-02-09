local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Logs (Journaux) Tab
-- ═══════════════════════════════════════════════════════════════════

local ld = {}
local LOG_ROW_H = 20

local LOG_ORDER = {
    "ALL", "ERR", "SKIP", "IN", "QUEUE", "BL",
    "IGNORE", "INV", "OUT", "AFK", "DND", "SCAN",
}
local LOG_LABELS = {
    ALL = "Tous",      ERR = "Erreurs",  SKIP = "Bloques",
    IN  = "Entrants",  QUEUE = "Liste",  BL   = "Blacklist",
    IGNORE = "Ignore", INV = "Invitations",
    OUT = "Sortants",  AFK = "AFK", DND = "DND", SCAN = "Scan",
}

---------------------------------------------------------------------------
-- Row Factory
---------------------------------------------------------------------------
local function MakeLogRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(LOG_ROW_H)
    row:SetBackdrop({bgFile = W.SOLID})
    local bgc = (i % 2 == 0) and C.row2 or C.row1
    row._bgc = bgc
    row:SetBackdropColor(unpack(bgc))

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", 8, 0)
    row.text:SetPoint("RIGHT", -8, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    return row
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function ns.UI_BuildLogs(parent)
    local controls = CreateFrame("Frame", nil, parent)
    controls:SetHeight(30)
    controls:SetPoint("TOPLEFT", 8, -8)
    controls:SetPoint("TOPRIGHT", -8, -8)

    -- Filter dropdown
    local filterItems = {}
    for _, k in ipairs(LOG_ORDER) do
        filterItems[#filterItems + 1] = {value = k, label = LOG_LABELS[k]}
    end
    ld.filterDD = W.MakeDropdown(controls, 140, filterItems, "ALL", function(v)
        ns._ui_logFilter = v
        ns.UI_Refresh()
    end)
    ld.filterDD:SetPoint("LEFT", 0, 0)

    -- Clear button
    ld.clearBtn = W.MakeBtn(controls, "Vider logs", 88, "d", function()
        ns.DB_ClearLogs()
        ns.UI_Refresh()
    end)
    ld.clearBtn:SetPoint("LEFT", ld.filterDD, "RIGHT", 8, 0)

    -- Summary text
    ld.summary = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ld.summary:SetPoint("LEFT", ld.clearBtn, "RIGHT", 14, 0)
    ld.summary:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Scroll area
    ld.scroll = W.MakeScroll(parent)
    ld.scroll.frame:SetPoint("TOPLEFT", 8, -44)
    ld.scroll.frame:SetPoint("BOTTOMRIGHT", -8, 8)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshLogs()
    if not ld.scroll then return end

    local filter = ns._ui_logFilter or "ALL"
    local logs = ns.db.global.logs or {}

    -- Summary stats
    local total = #logs
    local errs, skips = 0, 0
    for _, e in ipairs(logs) do
        if e.kind == "ERR"  then errs  = errs  + 1 end
        if e.kind == "SKIP" then skips = skips + 1 end
    end
    ld.summary:SetText(("Total: %d  |  Erreurs: %d  |  Bloques: %d"):format(total, errs, skips))

    -- Filter entries
    local filtered = {}
    for _, e in ipairs(logs) do
        if filter == "ALL" or e.kind == filter then
            filtered[#filtered + 1] = e
        end
    end

    local scroll = ld.scroll
    local rows = scroll.rows

    if #filtered == 0 then
        scroll:ShowEmpty("", "Aucun log")
        for _, r in ipairs(rows) do r:Hide() end
        scroll:SetH(scroll.sf:GetHeight())
        return
    end
    scroll:HideEmpty()

    for i, e in ipairs(filtered) do
        if not rows[i] then rows[i] = MakeLogRow(scroll.child, i) end
        local row = rows[i]
        row:Show()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -(i - 1) * LOG_ROW_H)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")
        row.text:SetText(("[%s]  |cff888888%s|r  |cff%s%s|r"):format(
            date("%H:%M:%S", e.t),
            e.kind,
            W.logColor(e.kind),
            e.text or ""
        ))
    end

    for i = #filtered + 1, #rows do rows[i]:Hide() end
    scroll:SetH(#filtered * LOG_ROW_H)
end
