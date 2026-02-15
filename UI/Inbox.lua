local _, ns = ...
local W = ns.UIWidgets
local C = W.C
local function getRep() return ns.Reputation end

-- =====================================================================
-- CelestialRecruiter  --  Inbox (Boite) Tab  --  Enhanced v3.1
-- Conversation history, quick-reply, hot contact indicators
-- =====================================================================

local ib = {}         -- module state
local ROW_MAIN  = 44  -- main row height (name + preview)
local ROW_REPLY = 28  -- inline reply editbox height
local ROW_CONVO = 180 -- conversation history panel height
local PREVIEW_CHARS = 60

---------------------------------------------------------------------------
-- Sort / Filter state  (local to module, survives refresh)
---------------------------------------------------------------------------
ib.sortMode    = "recent"   -- "recent" | "score" | "hot"
ib.hotOnly     = false
ib.activeReply = nil        -- key of row currently showing reply box

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function truncate(text, maxLen)
    if not text or text == "" then return "" end
    text = text:gsub("%s+", " ")
    if #text <= maxLen then return text end
    return text:sub(1, maxLen) .. "..."
end

local function scoreColor(score)
    if score >= 80 then return C.orange end
    if score >= 60 then return C.green  end
    if score >= 40 then return C.dim    end
    return C.muted
end

local function scoreBadgeText(score)
    local col = scoreColor(score)
    local hex = string.format("%02x%02x%02x", col[1] * 255, col[2] * 255, col[3] * 255)
    return string.format("|cff%s%d|r", hex, score)
end

local function hotBadgeText()
    local hex = string.format("%02x%02x%02x", C.orange[1] * 255, C.orange[2] * 255, C.orange[3] * 255)
    return string.format("|cff%sPRIO|r", hex)
end

local function statusDot(status)
    local r, g, b = W.statusDotColor(status)
    local hex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
    return string.format("|cff%so|r", hex)
end

local function classColoredName(key, classFile)
    if classFile and classFile ~= "" then
        return "|c" .. W.classHex(classFile) .. key .. "|r"
    end
    return "|cff" .. string.format("%02x%02x%02x", C.accent[1] * 255, C.accent[2] * 255, C.accent[3] * 255) .. key .. "|r"
end

local function agoFr(ts)
    return ns.Util_FormatAgo(ts)
end

local function fillConversation(convoScroll, key)
    convoScroll:Clear()
    local msgs = ns.DB_GetMessages(key)
    if #msgs == 0 then
        convoScroll:AddMessage("|cff888888Aucun historique enregistre.|r")
        return
    end
    for _, m in ipairs(msgs) do
        local ago = agoFr(m.t)
        local line
        if m.d == "out" then
            local hex = string.format("%02x%02x%02x", C.accent[1] * 255, C.accent[2] * 255, C.accent[3] * 255)
            line = string.format("|cff%s[%s] Vous :|r %s", hex, ago, m.m)
        else
            local hex = string.format("%02x%02x%02x", C.green[1] * 255, C.green[2] * 255, C.green[3] * 255)
            line = string.format("|cff%s[%s] Eux :|r %s", hex, ago, m.m)
        end
        convoScroll:AddMessage(line)
    end
    convoScroll:ScrollToBottom()
end

---------------------------------------------------------------------------
-- Build template items list (for dropdown)
---------------------------------------------------------------------------
local function getTemplateItems()
    local items = {}
    local all = ns.Templates_All()
    if all then
        for id, obj in pairs(all) do
            items[#items + 1] = { value = id, label = obj.name or id }
        end
    end
    if #items == 0 then
        items[#items + 1] = { value = "default", label = "Par defaut" }
    end
    return items
end

---------------------------------------------------------------------------
-- Enhanced Tooltip (conversation context)
---------------------------------------------------------------------------
local function ShowInboxTooltip(anchor, key)
    if not key or key == "" then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")

    local c = ns.DB_GetContact(key)
    if not c then
        GameTooltip:AddLine(key, C.accent[1], C.accent[2], C.accent[3])
        GameTooltip:Show()
        return
    end

    -- Name with class color
    local classFile = c.classFile
    if classFile and classFile ~= "" then
        GameTooltip:AddLine("|c" .. W.classHex(classFile) .. key .. "|r")
    else
        GameTooltip:AddLine(key, C.accent[1], C.accent[2], C.accent[3])
    end

    -- Level / class info
    local parts = {}
    if (c.level or 0) > 0 then
        parts[#parts + 1] = "Niv " .. c.level
    end
    if c.classFile and c.classFile ~= "" then
        parts[#parts + 1] = c.classFile
    end
    if #parts > 0 then
        GameTooltip:AddLine(table.concat(parts, "  "), C.dim[1], C.dim[2], C.dim[3])
    end

    -- Reputation score
    GameTooltip:AddLine(" ")
    local score = getRep() and getRep():CalculateScore(c) or 0
    local _, scoreLabel, scoreCol
    if getRep() then
        _, scoreLabel, scoreCol = getRep():GetScoreClass(score)
    end
    scoreLabel = scoreLabel or "Neutre"
    scoreCol = scoreCol or C.dim
    GameTooltip:AddDoubleLine("Score reputation :", tostring(score) .. " / 100", C.dim[1], C.dim[2], C.dim[3], scoreCol[1], scoreCol[2], scoreCol[3])
    GameTooltip:AddDoubleLine("Classement :", scoreLabel, C.dim[1], C.dim[2], C.dim[3], scoreCol[1], scoreCol[2], scoreCol[3])

    -- Score breakdown hints
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("-- Facteurs de score --", C.gold[1], C.gold[2], C.gold[3])
    if c.optedIn then
        GameTooltip:AddDoubleLine("  Opt-in:", "+30", C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if c.lastWhisperIn and c.lastWhisperOut and c.lastWhisperIn > c.lastWhisperOut then
        GameTooltip:AddDoubleLine("  A repondu:", "+25", C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if c.source == "inbox" then
        GameTooltip:AddDoubleLine("  Nous a contacte:", "+20", C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end
    if c.status == "ignored" then
        GameTooltip:AddDoubleLine("  Statut ignore:", "-50", C.dim[1], C.dim[2], C.dim[3], C.red[1], C.red[2], C.red[3])
    end

    -- Conversation summary
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("-- Historique --", C.gold[1], C.gold[2], C.gold[3])

    local sr, sg, sb = W.statusDotColor(c.status)
    GameTooltip:AddDoubleLine("Statut:", c.status or "new", C.dim[1], C.dim[2], C.dim[3], sr, sg, sb)

    if c.source and c.source ~= "" then
        GameTooltip:AddDoubleLine("Source:", c.source, C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    end
    if c.optedIn then
        GameTooltip:AddDoubleLine("Opt-in:", "Oui", C.dim[1], C.dim[2], C.dim[3], C.green[1], C.green[2], C.green[3])
    end

    if (c.lastWhisperIn or 0) > 0 then
        GameTooltip:AddDoubleLine("Dernier msg recu:", agoFr(c.lastWhisperIn), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    end
    if (c.lastWhisperOut or 0) > 0 then
        GameTooltip:AddDoubleLine("Dernier msg envoye:", agoFr(c.lastWhisperOut), C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    end
    if (c.lastInviteAt or 0) > 0 then
        GameTooltip:AddDoubleLine("Derni\195\168re invitation:", agoFr(c.lastInviteAt), C.gold[1], C.gold[2], C.gold[3], C.text[1], C.text[2], C.text[3])
    end

    -- Notes
    if c.notes and c.notes ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Notes: " .. c.notes, C.dim[1], C.dim[2], C.dim[3], true)
    end

    -- Tags
    if c.tags and #c.tags > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tags: " .. table.concat(c.tags, ", "), C.purple[1], C.purple[2], C.purple[3], true)
    end

    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Row Factory  (two-line main row: name line + preview line)
---------------------------------------------------------------------------
local function MakeInboxRow(parent, i)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_MAIN)
    row:SetBackdrop({ bgFile = W.SOLID })
    W.SetRowBG(row, i)
    row:EnableMouse(true)

    row:SetScript("OnEnter", function(s)
        s:SetBackdropColor(unpack(C.hover))
        ShowInboxTooltip(s, s._boundKey)
    end)
    row:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(s._bgc))
        W.HidePlayerTooltip()
    end)

    -----------------------------------------------------------------------
    -- Top line:  [score] [HOT?] [name] [status dot] [ago]
    -----------------------------------------------------------------------
    row.scoreBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.scoreBadge:SetPoint("LEFT", 8, 6)
    row.scoreBadge:SetWidth(30)
    row.scoreBadge:SetJustifyH("CENTER")

    row.hotBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hotBadge:SetPoint("LEFT", row.scoreBadge, "RIGHT", 2, 0)
    row.hotBadge:SetWidth(32)
    row.hotBadge:SetJustifyH("LEFT")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.hotBadge, "RIGHT", 2, 0)
    row.name:SetWidth(160)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.statusDot = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.statusDot:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
    row.statusDot:SetWidth(14)

    row.ago = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.ago:SetPoint("LEFT", row.statusDot, "RIGHT", 4, 0)
    row.ago:SetWidth(60)
    row.ago:SetJustifyH("LEFT")
    row.ago:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -----------------------------------------------------------------------
    -- Second line:  preview of last message received (dim)
    -----------------------------------------------------------------------
    row.preview = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.preview:SetPoint("TOPLEFT", row.scoreBadge, "BOTTOMLEFT", 0, -1)
    row.preview:SetPoint("RIGHT", row, "RIGHT", -280, 0)
    row.preview:SetJustifyH("LEFT")
    row.preview:SetWordWrap(false)
    row.preview:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -----------------------------------------------------------------------
    -- Right-side action buttons
    -----------------------------------------------------------------------
    -- Blacklist (rightmost)
    row.blBtn = W.MakeBtn(row, "Bloquer", 68, "d", nil)
    row.blBtn:SetPoint("RIGHT", -6, 6)

    -- Ignorer 7j
    row.ignBtn = W.MakeBtn(row, "Ignorer 7j", 76, "n", nil)
    row.ignBtn:SetPoint("RIGHT", row.blBtn, "LEFT", -3, 0)

    -- + Liste
    row.addBtn = W.MakeBtn(row, "+ Liste", 58, "s", nil)
    row.addBtn:SetPoint("RIGHT", row.ignBtn, "LEFT", -3, 0)

    -- Recruter
    row.recruitBtn = W.MakeBtn(row, "Recruter", 66, "s", nil)
    row.recruitBtn:SetPoint("RIGHT", row.addBtn, "LEFT", -3, 0)

    -- Repondre
    row.replyBtn = W.MakeBtn(row, "Repondre", 70, "p", nil)
    row.replyBtn:SetPoint("RIGHT", row.recruitBtn, "LEFT", -3, 0)

    -----------------------------------------------------------------------
    -- Hot glow (persistent for score >= 70)
    -----------------------------------------------------------------------
    row.hotGlow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.hotGlow:SetTexture(W.SOLID)
    row.hotGlow:SetAllPoints()
    row.hotGlow:SetVertexColor(C.orange[1], C.orange[2], C.orange[3], 0)
    row.hotGlow:Hide()

    -----------------------------------------------------------------------
    -- Standard hover glow
    -----------------------------------------------------------------------
    W.AddRowGlow(row)

    -----------------------------------------------------------------------
    -- Conversation panel (hidden by default, shown below main row)
    -----------------------------------------------------------------------
    row.convoFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row.convoFrame:SetHeight(ROW_CONVO)
    row.convoFrame:SetBackdrop({ bgFile = W.SOLID, edgeFile = W.EDGE,
        edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    row.convoFrame:SetBackdropColor(0.04, 0.05, 0.10, 0.95)
    row.convoFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.3)
    row.convoFrame:Hide()

    -- Scrolling message frame for conversation history
    row.convoScroll = CreateFrame("ScrollingMessageFrame", nil, row.convoFrame)
    row.convoScroll:SetPoint("TOPLEFT", 8, -6)
    row.convoScroll:SetPoint("BOTTOMRIGHT", -8, ROW_REPLY + 4)
    row.convoScroll:SetFontObject(GameFontHighlightSmall)
    row.convoScroll:SetJustifyH("LEFT")
    row.convoScroll:SetFading(false)
    row.convoScroll:SetMaxLines(200)
    row.convoScroll:SetInsertMode("BOTTOM")
    row.convoScroll:EnableMouseWheel(true)
    row.convoScroll:SetHyperlinksEnabled(false)
    row.convoScroll:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        else
            self:ScrollDown()
        end
    end)

    -- Reply editbox at the bottom of the convo frame
    row.replyFrame = CreateFrame("Frame", nil, row.convoFrame)
    row.replyFrame:SetHeight(ROW_REPLY)
    row.replyFrame:SetPoint("BOTTOMLEFT", 0, 0)
    row.replyFrame:SetPoint("BOTTOMRIGHT", 0, 0)

    row.replyEB = CreateFrame("EditBox", nil, row.replyFrame, "BackdropTemplate")
    row.replyEB:SetPoint("TOPLEFT", 8, -3)
    row.replyEB:SetPoint("BOTTOMRIGHT", -80, 3)
    row.replyEB:SetBackdrop({
        bgFile = W.SOLID, edgeFile = W.EDGE,
        edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    row.replyEB:SetBackdropColor(0.04, 0.05, 0.10, 0.90)
    row.replyEB:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    row.replyEB:SetFontObject(GameFontHighlightSmall)
    row.replyEB:SetTextInsets(6, 6, 0, 0)
    row.replyEB:SetAutoFocus(false)

    -- Send button inside reply area
    row.sendBtn = W.MakeBtn(row.replyFrame, "Envoyer", 66, "p", nil)
    row.sendBtn:SetPoint("RIGHT", -6, 0)

    return row
end

---------------------------------------------------------------------------
-- Build (called once from UI.lua)
---------------------------------------------------------------------------
function ns.UI_BuildInbox(parent)
    -----------------------------------------------------------------------
    -- Top controls bar: sort dropdown + hot only toggle
    -----------------------------------------------------------------------
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(28)
    bar:SetPoint("TOPLEFT", 8, -8)
    bar:SetPoint("TOPRIGHT", -8, -8)
    ib.bar = bar

    -- Sort dropdown
    local sortItems = {
        { value = "recent", label = "Recent" },
        { value = "score",  label = "Score" },
        { value = "hot",    label = "Prioritaires d'abord" },
    }
    ib.sortDD = W.MakeDropdown(bar, 130, sortItems, ib.sortMode, function(v)
        ib.sortMode = v
        ns.UI_RefreshInbox()
    end)
    ib.sortDD:SetPoint("LEFT", 0, 0)
    W.AddTooltip(ib.sortDD, "Tri", "Changer l'ordre d'affichage des contacts.")

    -- "Hot leads" toggle checkbox
    ib.hotCheck = W.MakeCheck(bar, "Prioritaires uniquement", function() return ib.hotOnly end, function(v)
        ib.hotOnly = v
        ns.UI_RefreshInbox()
    end)
    ib.hotCheck:SetPoint("LEFT", ib.sortDD, "RIGHT", 14, 0)
    W.AddTooltip(ib.hotCheck, "Prioritaires", "N'afficher que les contacts avec un score >= 70.")

    -- "Filtres" button + active filter badge
    ib.filterBtn = W.MakeBtn(bar, "Filtres", 70, "n", function()
        if ib.filterBar then
            ib.filterBar:Toggle()
            local h = ib.filterBar:GetEffectiveHeight()
            ib.scroll.frame:SetPoint("TOPLEFT", 8, -(40 + h))
            local cnt = ns.Filters:CountActive()
            ib.filterBadge:SetText(cnt > 0 and string.format("[%d]", cnt) or "")
        end
    end)
    ib.filterBtn:SetPoint("LEFT", ib.hotCheck.label, "RIGHT", 14, 0)
    W.AddTooltip(ib.filterBtn, "Filtres", "Affiche ou masque le panneau de filtres avances.")

    ib.filterBadge = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ib.filterBadge:SetPoint("LEFT", ib.filterBtn, "RIGHT", 3, 0)
    ib.filterBadge:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    ib.filterBadge:SetText("")

    -- Filter bar (animated panel)
    ib.filterBar = W.MakeFilterBar(parent, "inbox", function(h, isFilterChange)
        ib.scroll.frame:SetPoint("TOPLEFT", 8, -(40 + h))
        if isFilterChange then
            ns.UI_RefreshInbox()
        end
    end)
    -- Anchor filter bar below the inbox control bar
    ib.filterBar.container:ClearAllPoints()
    ib.filterBar.container:SetPoint("TOPLEFT", 8, -40)
    ib.filterBar.container:SetPoint("TOPRIGHT", -8, -40)

    -----------------------------------------------------------------------
    -- Scroll area (below control bar)
    -----------------------------------------------------------------------
    ib.scroll = W.MakeScroll(parent)
    ib.scroll.frame:SetPoint("TOPLEFT", 8, -40)
    ib.scroll.frame:SetPoint("BOTTOMRIGHT", -8, 8)
end

---------------------------------------------------------------------------
-- Sorting comparators
---------------------------------------------------------------------------
local function sortFiltered(filtered)
    local mode = ib.sortMode or "recent"
    if mode == "recent" then
        table.sort(filtered, function(a, b)
            local ta = a.contact.lastWhisperIn or 0
            local tb = b.contact.lastWhisperIn or 0
            if ta == tb then return a.key < b.key end
            return ta > tb
        end)
    elseif mode == "score" then
        table.sort(filtered, function(a, b)
            if a.score == b.score then return a.key < b.key end
            return a.score > b.score
        end)
    elseif mode == "hot" then
        table.sort(filtered, function(a, b)
            local aHot = a.score >= 70
            local bHot = b.score >= 70
            if aHot ~= bHot then return aHot end
            if a.score == b.score then
                local ta = a.contact.lastWhisperIn or 0
                local tb = b.contact.lastWhisperIn or 0
                if ta == tb then return a.key < b.key end
                return ta > tb
            end
            return a.score > b.score
        end)
    end
end

---------------------------------------------------------------------------
-- Wire a single row to a contact entry
---------------------------------------------------------------------------
local function BindRow(row, key, c, score, now, tplItems)
    local ignored = c.status == "ignored" and (c.ignoredUntil or 0) > now

    -----------------------------------------------------------------------
    -- Score badge
    -----------------------------------------------------------------------
    row.scoreBadge:SetText(scoreBadgeText(score))

    -- HOT badge
    if score >= 80 then
        row.hotBadge:SetText(hotBadgeText())
        row.hotBadge:Show()
    else
        row.hotBadge:SetText("")
        row.hotBadge:Hide()
    end

    -- Hot glow for score >= 70
    if score >= 70 then
        row.hotGlow:SetVertexColor(C.orange[1], C.orange[2], C.orange[3], 0.06)
        row.hotGlow:Show()
    else
        row.hotGlow:Hide()
    end

    -----------------------------------------------------------------------
    -- Name in class color
    -----------------------------------------------------------------------
    row.name:SetText(classColoredName(key, c.classFile))

    -- Status dot
    row.statusDot:SetText(statusDot(c.status))

    -- Time ago
    if (c.lastWhisperIn or 0) > 0 then
        row.ago:SetText(agoFr(c.lastWhisperIn))
    else
        row.ago:SetText("")
    end

    -----------------------------------------------------------------------
    -- Preview: show last message text, or fallback to metadata
    -----------------------------------------------------------------------
    local msgs = ns.DB_GetMessages(key)
    local lastMsg = msgs[#msgs]
    local previewStr
    if lastMsg then
        local prefix = lastMsg.d == "out" and "Vous: " or "Eux: "
        previewStr = prefix .. lastMsg.m
    else
        local previewParts = {}
        if c.optedIn then previewParts[#previewParts + 1] = "|cff33e07a[opt-in]|r" end
        if c.source and c.source ~= "" then previewParts[#previewParts + 1] = c.source end
        if ignored then previewParts[#previewParts + 1] = "|cffffb347[ignore]|r" end
        if (c.lastWhisperOut or 0) > 0 then
            previewParts[#previewParts + 1] = "envoye: " .. agoFr(c.lastWhisperOut)
        end
        previewStr = table.concat(previewParts, "  ")
    end
    row.preview:SetText(truncate(previewStr, PREVIEW_CHARS))

    -----------------------------------------------------------------------
    -- Button labels
    -----------------------------------------------------------------------
    row.replyBtn:SetLabel(ib.activeReply == key and "Fermer" or "Repondre")
    row.ignBtn:SetLabel(ignored and "Restaurer" or "Ignorer 7j")

    -----------------------------------------------------------------------
    -- Wire buttons (only if key changed to avoid redundant closures)
    -----------------------------------------------------------------------
    if row._boundKey ~= key then
        row._boundKey = key

        -- + Liste
        row.addBtn:SetScript("OnClick", function()
            if ns.DB_QueueAdd(key) then
                ns.DB_Log("QUEUE", "Ajout file: " .. key)
            end
            ns.UI_Refresh()
        end)

        -- Blacklist
        row.blBtn:SetScript("OnClick", function()
            ns.DB_SetBlacklisted(key, true)
            ns.DB_QueueRemove(key)
            ns.DB_Log("BL", "Blacklist: " .. key)
            ns.UI_Refresh()
        end)

        -- Recruter (message + invite via current template)
        row.recruitBtn:SetScript("OnClick", function()
            local tplId = ns._ui_tpl or "default"
            ns.Queue_Recruit(key, tplId)
        end)

        -- Repondre toggle (shows conversation history)
        row.replyBtn:SetScript("OnClick", function()
            if ib.activeReply == key then
                row.convoFrame:Hide()
                ib.activeReply = nil
                ns.UI_RefreshInbox()
            else
                ib.activeReply = key
                ns.UI_RefreshInbox()
                fillConversation(row.convoScroll, key)
                row.replyEB:SetText("")
                row.replyEB:SetFocus()
            end
        end)

        -- Reply EditBox: Enter = send whisper
        row.replyEB:SetScript("OnEnterPressed", function(s)
            local msg = s:GetText()
            if msg and msg ~= "" then
                local sendOk = pcall(SendChatMessage, msg, "WHISPER", nil, key)
                if sendOk then
                    ns.DB_UpsertContact(key, {
                        status = "contacted",
                        lastWhisperOut = ns.Util_Now(),
                    })
                    ns.DB_Log("OUT", "Reponse manuelle a " .. key .. ": " .. truncate(msg, 80))
                end
            end
            s:SetText("")
            -- Refresh conversation in-place (don't close panel)
            C_Timer.After(0.1, function()
                fillConversation(row.convoScroll, key)
            end)
        end)

        row.replyEB:SetScript("OnEscapePressed", function(s)
            s:SetText("")
            s:ClearFocus()
            row.convoFrame:Hide()
            ib.activeReply = nil
            ns.UI_RefreshInbox()
        end)

        -- Send button inside reply area
        row.sendBtn:SetScript("OnClick", function()
            local msg = row.replyEB:GetText()
            if msg and msg ~= "" then
                local sendOk = pcall(SendChatMessage, msg, "WHISPER", nil, key)
                if sendOk then
                    ns.DB_UpsertContact(key, {
                        status = "contacted",
                        lastWhisperOut = ns.Util_Now(),
                    })
                    ns.DB_Log("OUT", "Reponse manuelle a " .. key .. ": " .. truncate(msg, 80))
                end
            end
            row.replyEB:SetText("")
            -- Refresh conversation in-place
            C_Timer.After(0.1, function()
                fillConversation(row.convoScroll, key)
            end)
        end)
    end

    -- Ignore button always rewired (depends on current ignored state)
    row.ignBtn:SetScript("OnClick", function()
        if ignored then
            ns.DB_UpsertContact(key, { status = "new", ignoredUntil = 0 })
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

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function ns.UI_RefreshInbox()
    if not ib.scroll then return end

    local search = ns._ui_search or ""
    local now    = ns.Util_Now()

    -- Sync search text into Filters
    ns.Filters:SetText(search)

    -----------------------------------------------------------------------
    -- 1.  Gather & filter contacts
    -----------------------------------------------------------------------
    local allKeys  = ns.DB_ListContactsForInbox()
    local filtered = {}

    for _, key in ipairs(allKeys) do
        local c = ns.DB_GetContact(key)
        if c and not ns.DB_IsBlacklisted(key)
           and (c.lastWhisperIn or 0) > 0
           and ns.Filters:Matches(c)
        then
            local score = getRep() and getRep():CalculateScore(c) or 0

            -- hot-only filter
            if not ib.hotOnly or score >= 70 then
                filtered[#filtered + 1] = {
                    key     = key,
                    contact = c,
                    score   = score,
                }
            end
        end
    end

    -----------------------------------------------------------------------
    -- 2.  Sort
    -----------------------------------------------------------------------
    sortFiltered(filtered)

    -- Update filter badge
    if ib.filterBadge then
        local cnt = ns.Filters:CountActive()
        ib.filterBadge:SetText(cnt > 0 and string.format("[%d]", cnt) or "")
    end

    -- Sync filter bar visuals
    if ib.filterBar and ib.filterBar.expanded then
        ib.filterBar:SyncFromFilters()
    end

    -----------------------------------------------------------------------
    -- 3.  Template items (for future dropdown per-row if needed)
    -----------------------------------------------------------------------
    local tplItems = getTemplateItems()

    -----------------------------------------------------------------------
    -- 4.  Render rows
    -----------------------------------------------------------------------
    local scroll = ib.scroll
    local rows   = scroll.rows

    if #filtered == 0 then
        scroll:ShowEmpty("|TInterface\\Icons\\INV_Letter_15:14:14:0:0|t", "Aucun message recu. Les reponses a tes messages apparaitront ici.")
        for _, r in ipairs(rows) do
            r:Hide()
            if r.convoFrame then r.convoFrame:Hide() end
        end
        scroll:SetH(scroll.sf:GetHeight())
        return
    end
    scroll:HideEmpty()

    local yOff = 0  -- cumulative Y offset for variable-height rows

    for i, item in ipairs(filtered) do
        local key, c, score = item.key, item.contact, item.score

        -- Ensure row exists
        if not rows[i] then rows[i] = MakeInboxRow(scroll.child, i) end
        local row = rows[i]
        row:Show()

        -- Position main row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -yOff)
        row:SetPoint("RIGHT", scroll.child, "RIGHT")
        yOff = yOff + ROW_MAIN

        -- Bind data to row
        BindRow(row, key, c, score, now, tplItems)

        -- Conversation panel positioning
        if ib.activeReply == key then
            row.convoFrame:ClearAllPoints()
            row.convoFrame:SetPoint("TOPLEFT", scroll.child, "TOPLEFT", 0, -yOff)
            row.convoFrame:SetPoint("RIGHT", scroll.child, "RIGHT")
            row.convoFrame:Show()
            fillConversation(row.convoScroll, key)
            yOff = yOff + ROW_CONVO
        else
            row.convoFrame:Hide()
        end
    end

    -- Hide unused rows
    for i = #filtered + 1, #rows do
        rows[i]:Hide()
        if rows[i].convoFrame then rows[i].convoFrame:Hide() end
    end

    scroll:SetH(yOff)
end

---------------------------------------------------------------------------
-- Badge (unread count for tab label)
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
