local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local format = string.format

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Queue (File d'attente) Tab
-- ═══════════════════════════════════════════════════════════════════

local qd = {}
local updatePreview

---------------------------------------------------------------------------
-- Row Factory
---------------------------------------------------------------------------
local function MakeQueueRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(W.ROW_H)
    row:SetBackdrop({bgFile = W.SOLID})
    W.SetRowBG(row, i)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(s)
        s:SetBackdropColor(unpack(C.hover))
        W.ShowPlayerTooltip(s, s._boundKey)
        if updatePreview then updatePreview(s._boundKey) end
    end)
    row:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(s._bgc))
        W.HidePlayerTooltip()
        if updatePreview then updatePreview(nil) end
    end)

    -- Class color bar (left edge)
    row.bar = row:CreateTexture(nil, "OVERLAY")
    row.bar:SetWidth(3)
    row.bar:SetPoint("TOPLEFT")
    row.bar:SetPoint("BOTTOMLEFT")

    -- Player name (class colored)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", 10, 0)
    row.name:SetWidth(210)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Level + class
    row.classInfo = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.classInfo:SetPoint("LEFT", 226, 0)
    row.classInfo:SetWidth(120)
    row.classInfo:SetJustifyH("LEFT")
    row.classInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.classInfo:SetWordWrap(false)

    -- Status / opt-in / source
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.info:SetPoint("LEFT", 350, 0)
    row.info:SetWidth(180)
    row.info:SetJustifyH("LEFT")
    row.info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.info:SetWordWrap(false)

    -- Remove button (rightmost)
    row.removeBtn = W.MakeBtn(row, "Retirer", 62, "d", nil)
    row.removeBtn:SetPoint("RIGHT", -6, 0)

    -- Message-only button
    row.msgBtn = W.MakeBtn(row, "Message", 68, "n", nil)
    row.msgBtn:SetPoint("RIGHT", row.removeBtn, "LEFT", -4, 0)

    -- Recruit button (message + invite combined)
    row.recruitBtn = W.MakeBtn(row, "Recruter", 76, "s", nil)
    row.recruitBtn:SetPoint("RIGHT", row.msgBtn, "LEFT", -4, 0)

    W.AddRowGlow(row)
    return row
end

---------------------------------------------------------------------------
-- Live Message Preview
---------------------------------------------------------------------------
updatePreview = function(key)
    if not qd.previewText then return end
    local tplId = ns._ui_tpl or "default"
    if key and key ~= "" then
        local rendered = ns.Templates_Render(key, tplId)
        qd.previewText:SetText("|cff888888Apercu:|r  " .. rendered)
    else
        local rendered = ns.Templates_Render("Joueur-Exemple", tplId)
        qd.previewText:SetText("|cff888888Apercu:|r  |cff555555" .. rendered .. "|r")
    end
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function ns.UI_BuildQueue(parent)
    -- Controls bar
    local controls = CreateFrame("Frame", nil, parent)
    controls:SetHeight(30)
    controls:SetPoint("TOPLEFT", 8, -8)
    controls:SetPoint("TOPRIGHT", -8, -8)

    -- Template dropdown
    local tplItems = {}
    for id, obj in pairs(ns.Templates_All()) do
        tplItems[#tplItems + 1] = {value = id, label = obj.name}
    end
    qd.tplDD = W.MakeDropdown(controls, 160, tplItems, "default", function(v)
        ns._ui_tpl = v
        updatePreview(nil)
    end)
    qd.tplDD:SetPoint("LEFT", 0, 0)

    local tplLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tplLabel:SetPoint("RIGHT", qd.tplDD, "LEFT", -6, 0)
    tplLabel:SetText("Modele:")
    tplLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Sort dropdown
    local sortLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("LEFT", qd.tplDD, "RIGHT", 16, 0)
    sortLabel:SetText("Tri:")
    sortLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    local sortItems = {
        {value = "class", label = "Classe"},
        {value = "lvl_desc", label = "Niv \226\134\147"},
        {value = "lvl_asc", label = "Niv \226\134\145"},
        {value = "name", label = "Nom"},
    }
    ns._ui_queueSort = ns._ui_queueSort or "class"
    qd.sortDD = W.MakeDropdown(controls, 100, sortItems, ns._ui_queueSort, function(v)
        ns._ui_queueSort = v
        ns.UI_Refresh()
    end)
    qd.sortDD:SetPoint("LEFT", sortLabel, "RIGHT", 6, 0)

    -- Count label
    qd.countText = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qd.countText:SetPoint("LEFT", qd.sortDD, "RIGHT", 16, 0)
    qd.countText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- Preview bar
    local prevBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    prevBar:SetHeight(30)
    prevBar:SetPoint("BOTTOMLEFT", 8, 4)
    prevBar:SetPoint("BOTTOMRIGHT", -8, 4)
    prevBar:SetBackdrop({bgFile = W.SOLID})
    prevBar:SetBackdropColor(0.08, 0.09, 0.15, 0.75)

    -- Accent left border bar
    local prevAccent = prevBar:CreateTexture(nil, "OVERLAY")
    prevAccent:SetTexture(W.SOLID)
    prevAccent:SetWidth(2)
    prevAccent:SetPoint("TOPLEFT")
    prevAccent:SetPoint("BOTTOMLEFT")
    prevAccent:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

    -- Top border line
    local prevTopLine = prevBar:CreateTexture(nil, "OVERLAY")
    prevTopLine:SetTexture(W.SOLID)
    prevTopLine:SetHeight(1)
    prevTopLine:SetPoint("TOPLEFT")
    prevTopLine:SetPoint("TOPRIGHT")
    prevTopLine:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.15)

    qd.previewText = prevBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qd.previewText:SetPoint("LEFT", 12, 0)
    qd.previewText:SetPoint("RIGHT", -8, 0)
    qd.previewText:SetJustifyH("LEFT")
    qd.previewText:SetTextColor(C.text[1], C.text[2], C.text[3])
    qd.previewText:SetWordWrap(false)

    -- Scroll area
    qd.scroll = W.MakeScroll(parent)
    qd.scroll.frame:SetPoint("TOPLEFT", 8, -44)
    qd.scroll.frame:SetPoint("BOTTOMRIGHT", -8, 38)
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshQueue()
    if not qd.scroll then return end

    local search = ns._ui_search or ""
    local tplId = ns._ui_tpl or "default"

    local keys = ns.DB_QueueList()
    local filtered = {}
    for _, key in ipairs(keys) do
        local c = ns.DB_GetContact(key)
        if c then
            local st = c.status
            if st == "invited" or st == "joined" or st == "ignored" then
                -- skip already processed
            elseif (c.lastInviteAt or 0) > 0 then
                -- skip: already invited at some point
            elseif W.matchSearch(search,
                key, st or "", c.notes or "",
                c.optedIn and "optin" or "", c.source or ""
            ) then
                filtered[#filtered + 1] = {key = key, contact = c}
            end
        end
    end

    -- Sort filtered list
    local sortMode = ns._ui_queueSort or "class"
    if sortMode == "class" then
        table.sort(filtered, function(a, b)
            local ca = (a.contact.classLabel or ""):lower()
            local cb = (b.contact.classLabel or ""):lower()
            if ca ~= cb then return ca < cb end
            local la = tonumber(a.contact.level) or 0
            local lb = tonumber(b.contact.level) or 0
            return la > lb
        end)
    elseif sortMode == "lvl_desc" then
        table.sort(filtered, function(a, b)
            local la = tonumber(a.contact.level) or 0
            local lb = tonumber(b.contact.level) or 0
            if la ~= lb then return la > lb end
            return (a.key or "") < (b.key or "")
        end)
    elseif sortMode == "lvl_asc" then
        table.sort(filtered, function(a, b)
            local la = tonumber(a.contact.level) or 0
            local lb = tonumber(b.contact.level) or 0
            if la ~= lb then return la < lb end
            return (a.key or "") < (b.key or "")
        end)
    elseif sortMode == "name" then
        table.sort(filtered, function(a, b)
            return (a.key or "") < (b.key or "")
        end)
    end

    qd.countText:SetText(("%d joueur(s) en attente"):format(#filtered))

    local scroll = qd.scroll
    local rows = scroll.rows

    if #filtered == 0 then
        scroll:ShowEmpty("|cffFFD700*|r", "File d'attente vide")
        for _, r in ipairs(rows) do r:Hide() end
        scroll:SetH(scroll.sf:GetHeight())
        return
    end
    scroll:HideEmpty()

    for i, item in ipairs(filtered) do
        local key, c = item.key, item.contact
        if not rows[i] then rows[i] = MakeQueueRow(scroll.child, i) end
        local row = rows[i]
        row:Show()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -(i - 1) * W.ROW_H)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")

        -- Class color bar
        local cf = c.classFile or ""
        local cr, cg, cb = W.classRGB(cf)
        row.bar:SetVertexColor(cr, cg, cb)

        -- Name (class colored)
        if cf ~= "" then
            row.name:SetText("|c" .. W.classHex(cf) .. key .. "|r")
        else
            row.name:SetText("|cff00aaff" .. key .. "|r")
        end

        -- Level + class
        local lvl = tonumber(c.level) or 0
        local clsLabel = c.classLabel or ""
        if lvl > 0 and clsLabel ~= "" then
            row.classInfo:SetText(format("Niv %d  %s", lvl, clsLabel))
        elseif lvl > 0 then
            row.classInfo:SetText(format("Niv %d", lvl))
        elseif clsLabel ~= "" then
            row.classInfo:SetText(clsLabel)
        else
            row.classInfo:SetText("|cff555555?|r")
        end

        -- Info line (status, opt-in, source)
        local parts = {c.status or "new"}
        if c.optedIn then
            parts[#parts + 1] = "|cff33e07aopt-in|r"
        end
        parts[#parts + 1] = "src:" .. (c.source or "boite")
        row.info:SetText(table.concat(parts, "  "))

        -- Only rewire buttons if the bound key changed
        if row._boundKey ~= key then
            row._boundKey = key
            row.recruitBtn:SetScript("OnClick", function()
                local ok, why = ns.Queue_Recruit(key, tplId)
                if not ok and why then
                    ns.Util_Print("Recrutement: " .. W.reasonFr(why))
                end
                ns.UI_Refresh()
            end)
            row.msgBtn:SetScript("OnClick", function()
                local ok, why = ns.Queue_Whisper(key, tplId)
                if not ok and why then
                    ns.Util_Print("Message: " .. W.reasonFr(why))
                end
                ns.UI_Refresh()
            end)
            row.removeBtn:SetScript("OnClick", function()
                ns.DB_QueueRemove(key)
                ns.DB_Log("QUEUE", "Retrait liste: " .. key)
                ns.UI_Refresh()
            end)
        end
    end

    for i = #filtered + 1, #rows do rows[i]:Hide() end
    scroll:SetH(#filtered * W.ROW_H)
    updatePreview(nil)
end

---------------------------------------------------------------------------
-- Badge
---------------------------------------------------------------------------
function ns.UI_QueueBadge()
    local keys = ns.DB_QueueList()
    local n = 0
    for _, key in ipairs(keys) do
        local c = ns.DB_GetContact(key)
        if c then
            local st = c.status
            if st ~= "invited" and st ~= "joined" and st ~= "ignored"
                and (c.lastInviteAt or 0) <= 0 then
                n = n + 1
            end
        end
    end
    return n > 0 and tostring(n) or ""
end
