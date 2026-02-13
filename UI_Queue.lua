local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local format = string.format
local Rep = ns.Reputation

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Queue (File d'attente) Tab
-- Enhanced with reputation scores, badges, sort-by-score & actions
-- ═══════════════════════════════════════════════════════════════════

local qd = {}
local updatePreview

-- Reputation class to left-edge color mapping
local REP_BAR_COLORS = {
    hot       = {1.00, 0.55, 0.10},  -- orange
    promising = {0.20, 0.88, 0.48},  -- green
    neutral   = {0.55, 0.58, 0.66},  -- gray
    cold      = {0.40, 0.60, 0.90},  -- blue
    ignore    = {1.00, 0.40, 0.40},  -- red
}

---------------------------------------------------------------------------
-- Score cache (rebuilt each refresh to avoid stale data)
---------------------------------------------------------------------------
local scoreCache = {}

local function getScore(contact)
    if not contact then return 0 end
    local key = contact.key or contact.name or ""
    if scoreCache[key] then return scoreCache[key] end
    local score = Rep:CalculateScore(contact)
    scoreCache[key] = score
    return score
end

---------------------------------------------------------------------------
-- Reputation tooltip section
---------------------------------------------------------------------------
local function addReputationTooltip(contact, score)
    if not contact or not score then return end

    local class, label, color = Rep:GetScoreClass(score)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("-- Score de reputation --", C.gold[1], C.gold[2], C.gold[3])
    GameTooltip:AddDoubleLine("Score :", format("%d / 100", score),
        C.dim[1], C.dim[2], C.dim[3], color[1], color[2], color[3])
    GameTooltip:AddDoubleLine("Classement :", label,
        C.dim[1], C.dim[2], C.dim[3], color[1], color[2], color[3])

    -- Breakdown hints
    if contact.optedIn then
        GameTooltip:AddDoubleLine("  Opt-in :", "+30",
            C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    local level = contact.level or 0
    if level >= 70 then
        GameTooltip:AddDoubleLine("  Niv max :", "+15",
            C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    elseif level >= 60 then
        GameTooltip:AddDoubleLine("  Niv 60+ :", "+10",
            C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if contact.source == "inbox" then
        GameTooltip:AddDoubleLine("  Source boite :", "+20",
            C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if contact.lastWhisperIn and contact.lastWhisperOut
        and contact.lastWhisperIn > contact.lastWhisperOut then
        GameTooltip:AddDoubleLine("  A repondu :", "+25",
            C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if contact.crossRealm then
        GameTooltip:AddDoubleLine("  Cross-realm :", "-10",
            C.dim[1], C.dim[2], C.dim[3], C.red[1], C.red[2], C.red[3])
    end

    -- Conversion probability
    if Rep.PredictConversion then
        local prob = Rep:PredictConversion(contact)
        local pct = math.floor(prob * 100 + 0.5)
        local probColor
        if pct >= 60 then
            probColor = {C.green[1], C.green[2], C.green[3]}
        elseif pct >= 30 then
            probColor = {C.orange[1], C.orange[2], C.orange[3]}
        else
            probColor = {C.red[1], C.red[2], C.red[3]}
        end
        GameTooltip:AddDoubleLine("Prob. conversion :", format("%d%%", pct),
            C.dim[1], C.dim[2], C.dim[3], probColor[1], probColor[2], probColor[3])
    end
end

---------------------------------------------------------------------------
-- Row Factory (enhanced with score badge, rep bar, last seen, status dot)
---------------------------------------------------------------------------
local function MakeQueueRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(W.ROW_H)
    row:SetBackdrop({bgFile = W.SOLID})
    W.SetRowBG(row, i)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(s)
        s:SetBackdropColor(unpack(C.hover))
        -- Enhanced tooltip with reputation breakdown
        W.ShowPlayerTooltip(s, s._boundKey)
        local c = s._boundContact
        if c and s._boundScore then
            addReputationTooltip(c, s._boundScore)
            GameTooltip:Show()
        end
        if updatePreview then updatePreview(s._boundKey) end
    end)
    row:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(s._bgc))
        W.HidePlayerTooltip()
        if updatePreview then updatePreview(nil) end
    end)

    -- Reputation color bar (left edge, 3px, colored by score class)
    row.repBar = row:CreateTexture(nil, "OVERLAY")
    row.repBar:SetWidth(3)
    row.repBar:SetPoint("TOPLEFT")
    row.repBar:SetPoint("BOTTOMLEFT")

    -- Score badge (colored number left of name)
    row.scoreBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.scoreBadge:SetPoint("LEFT", 8, 0)
    row.scoreBadge:SetWidth(32)
    row.scoreBadge:SetJustifyH("CENTER")
    row.scoreBadge:SetWordWrap(false)

    -- Class color bar (thin vertical bar after score badge)
    row.bar = row:CreateTexture(nil, "OVERLAY")
    row.bar:SetWidth(3)
    row.bar:SetPoint("TOPLEFT", 42, 0)
    row.bar:SetPoint("BOTTOMLEFT", 42, 0)

    -- Player name (class colored)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", 50, 0)
    row.name:SetWidth(170)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Level + class
    row.classInfo = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.classInfo:SetPoint("LEFT", 224, 0)
    row.classInfo:SetWidth(100)
    row.classInfo:SetJustifyH("LEFT")
    row.classInfo:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.classInfo:SetWordWrap(false)

    -- Status dot
    row.statusDot = row:CreateTexture(nil, "OVERLAY")
    row.statusDot:SetSize(8, 8)
    row.statusDot:SetTexture(W.SOLID)
    row.statusDot:SetPoint("LEFT", 328, 0)

    -- Info / status / source
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.info:SetPoint("LEFT", 340, 0)
    row.info:SetWidth(100)
    row.info:SetJustifyH("LEFT")
    row.info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    row.info:SetWordWrap(false)

    -- Last seen (dim text, far right area)
    row.lastSeen = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.lastSeen:SetPoint("LEFT", 442, 0)
    row.lastSeen:SetWidth(80)
    row.lastSeen:SetJustifyH("LEFT")
    row.lastSeen:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    row.lastSeen:SetWordWrap(false)

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
-- Batch Recruit All (throttled)
---------------------------------------------------------------------------
local batchRunning = false

local function batchRecruitAll()
    if batchRunning then
        ns.Util_Print("Recrutement en masse deja en cours...")
        return
    end

    local tplId = ns._ui_tpl or "default"
    local keys = ns.DB_QueueList()
    local search = ns._ui_search or ""

    -- Build filtered list matching current view
    local targets = {}
    for _, key in ipairs(keys) do
        local c = ns.DB_GetContact(key)
        if c then
            local st = c.status
            if st ~= "invited" and st ~= "joined" and st ~= "ignored"
                and (c.lastInviteAt or 0) <= 0
                and W.matchSearch(search, key, st or "", c.notes or "",
                    c.optedIn and "optin" or "", c.source or "") then
                targets[#targets + 1] = key
            end
        end
    end

    if #targets == 0 then
        ns.Util_Print("Aucun joueur disponible dans la file.")
        return
    end

    -- Sort by reputation score descending (best first)
    table.sort(targets, function(a, b)
        local ca = ns.DB_GetContact(a)
        local cb = ns.DB_GetContact(b)
        local sa = ca and Rep:CalculateScore(ca) or 0
        local sb = cb and Rep:CalculateScore(cb) or 0
        return sa > sb
    end)

    batchRunning = true
    local idx = 0
    local total = #targets
    local successCount = 0
    local failCount = 0

    ns.Util_Print(format("Recrutement en masse: %d joueur(s)...", total))

    local function processNext()
        idx = idx + 1
        if idx > total then
            batchRunning = false
            ns.Util_Print(format(
                "Recrutement termine: %d/%d envoyes, %d en echec.",
                successCount, total, failCount))
            ns.UI_Refresh()
            return
        end

        local key = targets[idx]
        local ok, why = ns.Queue_Recruit(key, tplId)
        if ok then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end

        -- Throttle: 1.5s between each action to respect anti-spam
        C_Timer.After(1.5, processNext)
    end

    processNext()
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

    -- Sort dropdown (with score option added)
    local sortLabel = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("LEFT", qd.tplDD, "RIGHT", 16, 0)
    sortLabel:SetText("Tri:")
    sortLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    local sortItems = {
        {value = "class",    label = "Classe"},
        {value = "lvl_desc", label = "Niv \226\134\147"},
        {value = "lvl_asc",  label = "Niv \226\134\145"},
        {value = "name",     label = "Nom"},
        {value = "score",    label = "Score Rep"},
    }
    ns._ui_queueSort = ns._ui_queueSort or "class"
    qd.sortDD = W.MakeDropdown(controls, 110, sortItems, ns._ui_queueSort, function(v)
        ns._ui_queueSort = v
        ns.UI_Refresh()
    end)
    qd.sortDD:SetPoint("LEFT", sortLabel, "RIGHT", 6, 0)

    -- Count label
    qd.countText = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qd.countText:SetPoint("LEFT", qd.sortDD, "RIGHT", 12, 0)
    qd.countText:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- "Meilleur d'abord" button (sort by score shortcut)
    qd.bestFirstBtn = W.MakeBtn(controls, "Meilleur d'abord", 120, "p", function()
        ns._ui_queueSort = "score"
        qd.sortDD:SetVal("score")
        ns.UI_Refresh()
    end)
    qd.bestFirstBtn:SetPoint("LEFT", qd.countText, "RIGHT", 12, 0)

    -- "Recruter tout" button (batch recruit)
    qd.recruitAllBtn = W.MakeBtn(controls, "Recruter tout", 110, "s", function()
        batchRecruitAll()
    end)
    qd.recruitAllBtn:SetPoint("LEFT", qd.bestFirstBtn, "RIGHT", 6, 0)

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

    -- Reset score cache each refresh
    scoreCache = {}

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
                local score = getScore(c)
                filtered[#filtered + 1] = {key = key, contact = c, score = score}
            end
        end
    end

    -- Sort filtered list
    local sortMode = ns._ui_queueSort or "class"
    if sortMode == "score" then
        table.sort(filtered, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            return (a.key or "") < (b.key or "")
        end)
    elseif sortMode == "class" then
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

    -- Update count label with avg score
    local avgScore = 0
    if #filtered > 0 then
        local total = 0
        for _, item in ipairs(filtered) do total = total + item.score end
        avgScore = math.floor(total / #filtered + 0.5)
    end
    qd.countText:SetText(format("%d joueur(s)  |cff888888score moy: %d|r", #filtered, avgScore))

    -- Disable batch button when running or empty
    if qd.recruitAllBtn then
        qd.recruitAllBtn:SetOff(batchRunning or #filtered == 0)
    end

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
        local key, c, score = item.key, item.contact, item.score
        if not rows[i] then rows[i] = MakeQueueRow(scroll.child, i) end
        local row = rows[i]
        row:Show()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -(i - 1) * W.ROW_H)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")

        -- Store contact + score on row for tooltip
        row._boundContact = c
        row._boundScore = score

        -- Reputation score badge (colored)
        local repClass, repLabel, repColor = Rep:GetScoreClass(score)
        row.scoreBadge:SetText(Rep:GetBadge(score))

        -- Reputation color bar (left edge)
        local repBarC = REP_BAR_COLORS[repClass] or REP_BAR_COLORS.neutral
        row.repBar:SetTexture(W.SOLID)
        row.repBar:SetVertexColor(repBarC[1], repBarC[2], repBarC[3])

        -- Class color bar (thin vertical after score badge)
        local cf = c.classFile or ""
        local cr, cg, cb = W.classRGB(cf)
        row.bar:SetTexture(W.SOLID)
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

        -- Status dot
        local sr, sg, sb = W.statusDotColor(c.status)
        row.statusDot:SetVertexColor(sr, sg, sb)

        -- Info line (status, opt-in, source)
        local parts = {c.status or "new"}
        if c.optedIn then
            parts[#parts + 1] = "|cff33e07aopt-in|r"
        end
        parts[#parts + 1] = "src:" .. (c.source or "scan")
        row.info:SetText(table.concat(parts, "  "))

        -- Last seen / last interaction (dim text)
        local lastTs = c.lastSeen or c.lastWhisperIn or c.lastWhisperOut or 0
        if lastTs > 0 then
            row.lastSeen:SetText(ns.Util_FormatAgo(lastTs))
        else
            row.lastSeen:SetText("")
        end

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
                ns.DB_Log("QUEUE", "Retrait file: " .. key)
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
