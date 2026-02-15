local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- =====================================================================
-- CelestialRecruiter  --  Tutorial Overlay
-- Step-by-step interactive tutorial for new users
-- =====================================================================

local td = {}

local STEPS = {
    {
        title = "Bienvenue sur CelestialRecruiter !",
        text = "CelestialRecruiter est ton assistant de recrutement de guilde.\n\n" ..
            "Ce tutoriel rapide va te montrer les fonctionnalit\195\169s principales " ..
            "en quelques \195\169tapes. Tu peux le relancer \195\160 tout moment via le bouton |cffFFD700?|r.",
        icon = "|TInterface\\Icons\\Achievement_GuildPerk_EverybodysFriend:20:20:0:0|t",
    },
    {
        title = "Le Scanner",
        text = "L'onglet |cff00aaffScanner|r te permet de trouver des joueurs sans guilde.\n\n" ..
            "Clique sur |cff00aaffScanner|r pour lancer une recherche /who automatique " ..
            "par tranches de niveaux. Les joueurs trouv\195\169s apparaissent dans la liste.\n\n" ..
            "Tu peux les ajouter \195\160 ta file d'attente avec le bouton |cff00aaff+ Liste|r.",
        icon = "|TInterface\\Icons\\INV_Misc_Spyglass_03:20:20:0:0|t",
        tab = "Scanner",
    },
    {
        title = "La File d'attente",
        text = "L'onglet |cffFFD700File d'attente|r regroupe les joueurs \195\160 contacter.\n\n" ..
            "Choisis un |cffFFD700Mod\195\168le|r de message, puis clique sur |cff33e07aRecruiter|r " ..
            "pour envoyer un message + une invitation de guilde.\n\n" ..
            "Le |cff33e07ascore de r\195\169putation|r t'aide \195\160 prioriser les meilleurs contacts.",
        icon = "|TInterface\\Icons\\Spell_ChargePositive:20:20:0:0|t",
        tab = "Queue",
    },
    {
        title = "La Bo\195\174te de r\195\169ception",
        text = "L'onglet |cff33e07aBo\195\174te|r affiche les r\195\169ponses des joueurs.\n\n" ..
            "Quand un joueur r\195\169pond \195\160 ton message ou tape |cff00aaff!invite|r, " ..
            "il appara\195\174t ici. Tu peux l'inviter directement d'un clic.",
        icon = "|TInterface\\Icons\\INV_Letter_15:20:20:0:0|t",
        tab = "Inbox",
    },
    {
        title = "Les R\195\169glages",
        text = "L'onglet |cff888888R\195\169glages|r te permet de configurer :\n\n" ..
            "  \226\128\162 Les infos de ta guilde (nom, Discord, jours de raid)\n" ..
            "  \226\128\162 Les mod\195\168les de messages d'invitation\n" ..
            "  \226\128\162 Les limites anti-spam (cooldowns, max/heure)\n" ..
            "  \226\128\162 Les options du scanner\n" ..
            "  \226\128\162 Les notifications Discord",
        icon = "|TInterface\\Icons\\Trade_Engineering:20:20:0:0|t",
        tab = "Settings",
    },
    {
        title = "Les Analytiques",
        text = "L'onglet |cffFF69B4Analytiques|r offre un tableau de bord complet :\n\n" ..
            "  \226\128\162 Statistiques (contact\195\169s, invit\195\169s, recrues, conversion)\n" ..
            "  \226\128\162 Entonnoir de conversion\n" ..
            "  \226\128\162 Meilleurs horaires de recrutement\n" ..
            "  \226\128\162 Distribution par classe\n" ..
            "  \226\128\162 Succ\195\168s et progression",
        icon = "|TInterface\\Icons\\INV_Misc_StoneTablet_05:20:20:0:0|t",
        tab = "Analytics",
    },
    {
        title = "C'est parti !",
        text = "Tu es pr\195\170t \195\160 recruter !\n\n" ..
            "|cffFFD700\195\137tape 1|r : Va dans R\195\169glages et v\195\169rifie les infos de ta guilde.\n" ..
            "|cffFFD700\195\137tape 2|r : Lance un scan pour trouver des joueurs.\n" ..
            "|cffFFD700\195\137tape 3|r : Recrute les joueurs depuis la file d'attente.\n\n" ..
            "Consulte l'onglet |cff888888Aide|r pour un guide d\195\169taill\195\169.\n\n" ..
            "|cff888888Bon recrutement ! - plume.pao|r",
        icon = "|TInterface\\Icons\\Achievement_General_StayClassy:20:20:0:0|t",
    },
}

---------------------------------------------------------------------------
-- Build the tutorial overlay (created once, reused)
---------------------------------------------------------------------------
function ns.UI_BuildTutorial(mainFrame)
    if td.overlay then return end

    -- Semi-transparent overlay covering the main frame
    local overlay = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    overlay:SetAllPoints()
    overlay:SetFrameStrata("DIALOG")
    overlay:SetBackdrop({bgFile = W.SOLID})
    overlay:SetBackdropColor(0, 0, 0, 0.85)
    overlay:EnableMouse(true) -- block clicks through
    overlay:Hide()

    -- Card panel (centered)
    local card = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    card:SetSize(520, 320)
    card:SetPoint("CENTER", 0, 20)
    card:SetBackdrop({
        bgFile = W.SOLID, edgeFile = W.EDGE,
        edgeSize = 12, insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    card:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 0.95)
    card:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

    -- Top accent bar
    local accent = card:CreateTexture(nil, "OVERLAY")
    accent:SetTexture(W.SOLID)
    accent:SetHeight(3)
    accent:SetPoint("TOPLEFT", 4, -4)
    accent:SetPoint("TOPRIGHT", -4, -4)
    accent:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)

    -- Step counter
    td.stepText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    td.stepText:SetPoint("TOPRIGHT", -14, -14)
    td.stepText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -- Icon
    td.icon = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    td.icon:SetPoint("TOPLEFT", 20, -20)

    -- Title
    td.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    td.title:SetPoint("TOPLEFT", 50, -22)
    td.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    -- Body text
    td.body = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    td.body:SetPoint("TOPLEFT", 20, -56)
    td.body:SetPoint("TOPRIGHT", -20, -56)
    td.body:SetJustifyH("LEFT")
    td.body:SetJustifyV("TOP")
    td.body:SetSpacing(3)
    td.body:SetTextColor(C.text[1], C.text[2], C.text[3])

    -- Navigation buttons
    td.prevBtn = W.MakeBtn(card, "Pr\195\169c\195\169dent", 100, "n", function()
        td.currentStep = math.max(1, td.currentStep - 1)
        ns.UI_RefreshTutorial()
    end)
    td.prevBtn:SetPoint("BOTTOMLEFT", 16, 16)

    td.skipBtn = W.MakeBtn(card, "Passer", 80, "n", function()
        ns.UI_HideTutorial()
    end)
    td.skipBtn:SetPoint("BOTTOM", 0, 16)

    td.nextBtn = W.MakeBtn(card, "Suivant", 100, "p", function()
        if td.currentStep >= #STEPS then
            ns.UI_HideTutorial()
        else
            td.currentStep = td.currentStep + 1
            ns.UI_RefreshTutorial()
        end
    end)
    td.nextBtn:SetPoint("BOTTOMRIGHT", -16, 16)

    -- Progress dots
    td.dots = {}
    local dotSize = 8
    local dotSpacing = 14
    local totalDotsW = #STEPS * dotSpacing - (dotSpacing - dotSize)
    for i = 1, #STEPS do
        local dot = card:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(W.SOLID)
        dot:SetSize(dotSize, dotSize)
        dot:SetPoint("BOTTOM", card, "BOTTOM", -(totalDotsW / 2) + (i - 1) * dotSpacing + dotSize / 2, 50)
        td.dots[i] = dot
    end

    td.overlay = overlay
    td.card = card
    td.currentStep = 1
end

---------------------------------------------------------------------------
-- Refresh tutorial card content
---------------------------------------------------------------------------
function ns.UI_RefreshTutorial()
    if not td.overlay then return end

    local step = STEPS[td.currentStep]
    if not step then return end

    td.stepText:SetText(td.currentStep .. " / " .. #STEPS)
    td.icon:SetText(step.icon or "")
    td.title:SetText(step.title or "")
    td.body:SetText(step.text or "")

    -- Update navigation
    if td.currentStep <= 1 then
        td.prevBtn:Hide()
    else
        td.prevBtn:Show()
    end

    if td.currentStep >= #STEPS then
        td.nextBtn:SetLabel("Terminer")
    else
        td.nextBtn:SetLabel("Suivant")
    end

    -- Update progress dots
    for i, dot in ipairs(td.dots) do
        if i == td.currentStep then
            dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        elseif i < td.currentStep then
            dot:SetVertexColor(C.green[1], C.green[2], C.green[3], 0.6)
        else
            dot:SetVertexColor(C.muted[1], C.muted[2], C.muted[3], 0.3)
        end
    end

    -- Highlight the associated tab if defined
    if step.tab and ns.UI_SelectTab then
        ns.UI_SelectTab(step.tab)
    end
end

---------------------------------------------------------------------------
-- Show / Hide
---------------------------------------------------------------------------
function ns.UI_ShowTutorial()
    if not td.overlay and ns.UI and ns.UI.mainFrame then
        ns.UI_BuildTutorial(ns.UI.mainFrame)
    end
    if not td.overlay then return end

    td.currentStep = 1
    td.overlay:Show()
    ns.UI_RefreshTutorial()
end

function ns.UI_HideTutorial()
    if not td.overlay then return end
    td.overlay:Hide()
    -- Mark tutorial as seen
    if ns.db and ns.db.profile then
        ns.db.profile.tutorialSeen = true
    end
end
