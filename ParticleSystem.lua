local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- =====================================================================
-- CelestialRecruiter  --  Particle & Visual Effects System  v3.0
-- Epic celebration effects with pooled particle management
-- =====================================================================

ns.ParticleSystem = ns.ParticleSystem or {}
local PS = ns.ParticleSystem

---------------------------------------------------------------------------
-- Local references for performance
---------------------------------------------------------------------------
local math_random  = math.random
local math_sin     = math.sin
local math_cos     = math.cos
local math_max     = math.max
local math_min     = math.min
local math_abs     = math.abs
local math_pi      = math.pi
local math_sqrt    = math.sqrt
local tinsert      = table.insert
local tremove      = table.remove

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local SOLID          = "Interface\\Buttons\\WHITE8x8"
local POOL_SIZE      = 60
local TWO_PI         = math_pi * 2

-- Named colors for clarity
local COLOR_GOLD     = {1.00, 0.84, 0.00}
local COLOR_ACCENT   = {0.00, 0.68, 1.00}
local COLOR_GREEN    = {0.20, 0.88, 0.48}
local COLOR_PURPLE   = {0.58, 0.40, 1.00}
local COLOR_ORANGE   = {1.00, 0.70, 0.28}
local COLOR_WHITE    = {1.00, 1.00, 1.00}

---------------------------------------------------------------------------
-- Particle Pool
---------------------------------------------------------------------------
local pool          = {}       -- all particle textures (reusable)
local poolAvail     = {}       -- indices of available (inactive) particles
local activeList    = {}       -- {index, state} pairs for active particles
local activeCount   = 0
local overlayFrames = {}       -- reusable overlay frames for screen flash etc.
local overlayAvail  = {}
local textPool      = {}       -- reusable FontString pool
local textAvail     = {}
local managerFrame               -- single OnUpdate driver

-- Pre-create a hidden parent frame to own all pool textures.
-- Using a dedicated frame prevents texture ownership issues when the
-- anchor frame is destroyed or hidden.
local poolParent

local function ensurePoolParent()
    if poolParent then return end
    poolParent = CreateFrame("Frame", nil, UIParent)
    poolParent:SetAllPoints(UIParent)
    poolParent:SetFrameStrata("HIGH")
    poolParent:SetFrameLevel(50)
    poolParent:Show()
end

local function createPoolTexture()
    ensurePoolParent()
    local t = poolParent:CreateTexture(nil, "OVERLAY")
    t:SetTexture(SOLID)
    t:SetBlendMode("ADD")
    t:Hide()
    return t
end

local function initPool()
    for i = 1, POOL_SIZE do
        pool[i] = createPoolTexture()
        poolAvail[#poolAvail + 1] = i
    end
end

--- Acquire a particle from the pool. Returns (texture, poolIndex) or nil.
local function acquireParticle()
    local idx
    if #poolAvail > 0 then
        idx = poolAvail[#poolAvail]
        poolAvail[#poolAvail] = nil
    else
        -- Grow the pool dynamically
        idx = #pool + 1
        pool[idx] = createPoolTexture()
    end
    local t = pool[idx]
    t:Show()
    return t, idx
end

--- Release a particle back to the pool.
local function releaseParticle(tex, idx)
    tex:Hide()
    tex:ClearAllPoints()
    tex:SetRotation(0)
    poolAvail[#poolAvail + 1] = idx
end

---------------------------------------------------------------------------
-- Active Particle State
-- Each entry in activeList: { idx=poolIndex, ... state fields }
---------------------------------------------------------------------------

local function spawnParticle(anchor, cfg)
    local tex, idx = acquireParticle()
    if not tex then return nil end

    -- Build state table
    local s = {
        idx      = idx,
        tex      = tex,
        anchor   = anchor,
        x        = cfg.x or 0,
        y        = cfg.y or 0,
        vx       = cfg.vx or 0,
        vy       = cfg.vy or 0,
        life     = 0,
        maxLife  = cfg.maxLife or 1,
        size     = cfg.size or 4,
        r        = cfg.r or 1,
        g        = cfg.g or 1,
        b        = cfg.b or 1,
        a        = cfg.a or 1,
        gravity  = cfg.gravity or 0,
        rotation = cfg.rotation or 0,
        rotSpeed = cfg.rotSpeed or 0,
        custom   = cfg.custom or nil,  -- function(state, elapsed) for special logic
    }

    -- Initial placement
    tex:SetSize(math_max(1, s.size), math_max(1, s.size))
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", anchor, "CENTER", s.x, s.y)
    tex:SetVertexColor(s.r, s.g, s.b, s.a)
    tex:SetRotation(s.rotation)

    activeCount = activeCount + 1
    activeList[activeCount] = s
    return s
end

---------------------------------------------------------------------------
-- Overlay Frame Pool (for screen flash, expanding rings, etc.)
---------------------------------------------------------------------------
local function acquireOverlay(parent, strata, level)
    local f
    if #overlayAvail > 0 then
        f = overlayAvail[#overlayAvail]
        overlayAvail[#overlayAvail] = nil
    else
        ensurePoolParent()
        f = CreateFrame("Frame", nil, UIParent)
    end
    f:SetParent(parent or UIParent)
    f:SetFrameStrata(strata or "HIGH")
    f:SetFrameLevel(level or 60)
    f:SetAllPoints(parent or UIParent)
    f:Show()
    return f
end

local function releaseOverlay(f)
    f:Hide()
    f:SetScript("OnUpdate", nil)
    -- Clear child textures created on the fly
    overlayAvail[#overlayAvail + 1] = f
end

---------------------------------------------------------------------------
-- Text Pool (floating FontStrings)
---------------------------------------------------------------------------
local function acquireText(parent)
    ensurePoolParent()
    local fs
    if #textAvail > 0 then
        fs = textAvail[#textAvail]
        textAvail[#textAvail] = nil
    else
        fs = poolParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    end
    fs:SetParent(parent or poolParent)
    fs:Show()
    return fs
end

local function releaseText(fs)
    fs:Hide()
    fs:ClearAllPoints()
    textAvail[#textAvail + 1] = fs
end

---------------------------------------------------------------------------
-- Master Update Loop
---------------------------------------------------------------------------
local function masterUpdate(self, elapsed)
    if elapsed <= 0 then return end

    local write = 0
    for i = 1, activeCount do
        local s = activeList[i]
        if s then
            s.life = s.life + elapsed

            if s.life >= s.maxLife then
                -- Expired: release
                releaseParticle(s.tex, s.idx)
                -- don't write back, effectively removing from list
            else
                -- Run custom behaviour if present
                if s.custom then
                    s.custom(s, elapsed)
                end

                -- Physics
                s.vy = s.vy + s.gravity * elapsed
                s.x  = s.x + s.vx * elapsed
                s.y  = s.y + s.vy * elapsed
                s.rotation = s.rotation + s.rotSpeed * elapsed

                -- Easing: smooth fade  alpha = 1 - (life/maxLife)^2
                local ratio = s.life / s.maxLife
                local alpha = s.a * (1 - ratio * ratio)

                -- Apply to texture
                local tex = s.tex
                tex:ClearAllPoints()
                tex:SetPoint("CENTER", s.anchor, "CENTER", s.x, s.y)
                local sz = math_max(1, s.size)
                tex:SetSize(sz, sz)
                tex:SetRotation(s.rotation)
                tex:SetVertexColor(s.r, s.g, s.b, math_max(0, alpha))

                -- Compact: keep in list
                write = write + 1
                activeList[write] = s
            end
        end
    end
    -- Nil out leftover slots
    for i = write + 1, activeCount do
        activeList[i] = nil
    end
    activeCount = write
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
function PS:Init()
    if managerFrame then return end
    initPool()
    managerFrame = CreateFrame("Frame")
    managerFrame:SetScript("OnUpdate", masterUpdate)
end

---------------------------------------------------------------------------
-- Utility: random float in [lo, hi]
---------------------------------------------------------------------------
local function randf(lo, hi)
    return lo + math_random() * (hi - lo)
end

-- Pick a random entry from a color list
local function randColor(list)
    return list[math_random(#list)]
end

---------------------------------------------------------------------------
-- ========================  EFFECT 1  ========================
-- PlayRecruitJoinedEffect(anchorFrame)
-- The BIG celebration: confetti + sparkle ring + screen flash
--                      + starburst + floating stars
---------------------------------------------------------------------------
function PS:PlayRecruitJoinedEffect(frame)
    if not frame then return end

    local cx = 0  -- center relative to anchor CENTER
    local cy = 0

    ---------------------------------------------------------------
    -- (A) Golden Confetti Burst  --  45 particles, upward + gravity
    ---------------------------------------------------------------
    local confettiColors = {
        COLOR_GOLD,
        {1.00, 0.92, 0.30},
        {1.00, 0.78, 0.10},
        COLOR_ORANGE,
        COLOR_ACCENT,
        COLOR_PURPLE,
    }
    for i = 1, 45 do
        local angle = math_random() * TWO_PI
        local speed = randf(120, 280)
        local col   = randColor(confettiColors)
        spawnParticle(frame, {
            x        = cx + randf(-10, 10),
            y        = cy + randf(-5, 5),
            vx       = math_cos(angle) * speed,
            vy       = math_sin(angle) * speed + randf(80, 180),
            gravity  = randf(-350, -500),
            maxLife  = randf(1.4, 2.2),
            size     = randf(3, 8),
            r        = col[1], g = col[2], b = col[3],
            a        = 1,
            rotation = math_random() * TWO_PI,
            rotSpeed = randf(-8, 8),
        })
    end

    ---------------------------------------------------------------
    -- (B) Sparkle Ring  --  12 particles expanding in a circle
    ---------------------------------------------------------------
    for i = 1, 12 do
        local angle  = (i / 12) * TWO_PI
        local speed  = randf(60, 90)
        local bright = randf(0.85, 1.0)
        spawnParticle(frame, {
            x        = cx,
            y        = cy,
            vx       = math_cos(angle) * speed,
            vy       = math_sin(angle) * speed,
            gravity  = 0,
            maxLife  = randf(0.6, 0.9),
            size     = randf(2, 4),
            r        = bright, g = bright, b = bright,
            a        = 1,
            rotation = 0,
            rotSpeed = randf(-3, 3),
        })
    end

    ---------------------------------------------------------------
    -- (C) Screen Flash  --  golden overlay 0.3s: alpha 0 -> 0.4 -> 0
    ---------------------------------------------------------------
    local flashFrame = acquireOverlay(frame, "HIGH", 70)
    local flashTex = flashFrame:CreateTexture(nil, "BACKGROUND")
    flashTex:SetAllPoints(flashFrame)
    flashTex:SetTexture(SOLID)
    flashTex:SetVertexColor(COLOR_GOLD[1], COLOR_GOLD[2], COLOR_GOLD[3], 0)
    flashTex:Show()

    local flashTime = 0
    local flashDuration = 0.3
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        flashTime = flashTime + elapsed
        if flashTime >= flashDuration then
            flashTex:Hide()
            flashTex:SetParent(nil)  -- detach so it can be GC'd
            releaseOverlay(flashFrame)
            return
        end
        -- Triangle wave: ramp up first half, ramp down second half
        local ratio = flashTime / flashDuration
        local alpha
        if ratio < 0.35 then
            alpha = (ratio / 0.35) * 0.4
        else
            alpha = 0.4 * (1 - (ratio - 0.35) / 0.65)
        end
        flashTex:SetVertexColor(COLOR_GOLD[1], COLOR_GOLD[2], COLOR_GOLD[3], math_max(0, alpha))
    end)

    ---------------------------------------------------------------
    -- (D) Starburst  --  8 radiating lines from center, then fade
    --     Each line = 5 particles staggered along the ray
    ---------------------------------------------------------------
    for ray = 1, 8 do
        local angle = (ray / 8) * TWO_PI
        for step = 1, 5 do
            local dist  = step * 14
            local speed = randf(100, 160) + step * 20
            spawnParticle(frame, {
                x        = cx + math_cos(angle) * dist,
                y        = cy + math_sin(angle) * dist,
                vx       = math_cos(angle) * speed,
                vy       = math_sin(angle) * speed,
                gravity  = 0,
                maxLife  = randf(0.5, 0.8),
                size     = randf(2, 5),
                r        = 1, g = 0.92, b = 0.40,
                a        = 0.9,
                rotation = angle,
                rotSpeed = 0,
            })
        end
    end

    ---------------------------------------------------------------
    -- (E) Floating Stars  --  star characters rising and fading
    ---------------------------------------------------------------
    for i = 1, 8 do
        C_Timer.After(randf(0, 0.4), function()
            if not frame:IsVisible() then return end
            local fs = acquireText(poolParent)
            fs:SetText("\226\152\133")  -- UTF-8 for the star symbol
            fs:SetTextColor(COLOR_GOLD[1], COLOR_GOLD[2], COLOR_GOLD[3], 1)
            local startX = randf(-80, 80)
            local startY = randf(-30, 30)
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", frame, "CENTER", startX, startY)

            local starLife = 0
            local starMax  = randf(1.2, 2.0)
            local driftX   = randf(-15, 15)
            local riseSpeed = randf(30, 55)

            local starFrame = acquireOverlay(frame, "HIGH", 75)
            starFrame:SetScript("OnUpdate", function(self, elapsed)
                starLife = starLife + elapsed
                if starLife >= starMax then
                    releaseText(fs)
                    releaseOverlay(starFrame)
                    return
                end
                local ratio = starLife / starMax
                local alpha = 1 - ratio * ratio
                fs:SetTextColor(COLOR_GOLD[1], COLOR_GOLD[2], COLOR_GOLD[3], math_max(0, alpha))
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", frame, "CENTER",
                    startX + driftX * ratio,
                    startY + riseSpeed * starLife)
            end)
        end)
    end

    -- Sound cue (safe in case SOUNDKIT key missing)
    if SOUNDKIT and SOUNDKIT.UI_70_ARTIFACT_FORGE_APPEARANCE_APPEARANCE_CHANGE then
        PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_APPEARANCE_APPEARANCE_CHANGE)
    else
        PlaySound(888) -- level-up fallback
    end
end

---------------------------------------------------------------------------
-- ========================  EFFECT 2  ========================
-- PlayHoverEffect(buttonFrame)
-- Subtle sparkle on button hover: 3-5 tiny bright particles drifting up
---------------------------------------------------------------------------
function PS:PlayHoverEffect(frame)
    if not frame then return end

    local w = frame:GetWidth()
    local h = frame:GetHeight()
    local count = math_random(3, 5)

    for i = 1, count do
        local xOff = randf(-w * 0.4, w * 0.4)
        local yOff = randf(-h * 0.3, h * 0.3)
        local bright = randf(0.7, 1.0)
        spawnParticle(frame, {
            x        = xOff,
            y        = yOff,
            vx       = randf(-8, 8),
            vy       = randf(25, 50),
            gravity  = 0,
            maxLife  = randf(0.3, 0.5),
            size     = randf(1, 3),
            r        = COLOR_ACCENT[1] * bright + (1 - bright),
            g        = COLOR_ACCENT[2] * bright + (1 - bright),
            b        = COLOR_ACCENT[3] * bright + (1 - bright),
            a        = 0.8,
            rotation = 0,
            rotSpeed = 0,
        })
    end
end

---------------------------------------------------------------------------
-- ========================  EFFECT 3  ========================
-- PlayClickEffect(buttonFrame)
-- Satisfying click: 8 particles burst outward + expanding ring
---------------------------------------------------------------------------
function PS:PlayClickEffect(frame)
    if not frame then return end

    -- (A) Outward particle burst
    local burstCount = math_random(6, 8)
    for i = 1, burstCount do
        local angle = (i / burstCount) * TWO_PI + randf(-0.2, 0.2)
        local speed = randf(60, 120)
        spawnParticle(frame, {
            x        = 0,
            y        = 0,
            vx       = math_cos(angle) * speed,
            vy       = math_sin(angle) * speed,
            gravity  = 0,
            maxLife  = randf(0.25, 0.45),
            size     = randf(2, 4),
            r        = COLOR_ACCENT[1],
            g        = COLOR_ACCENT[2],
            b        = COLOR_ACCENT[3],
            a        = 1,
            rotation = angle,
            rotSpeed = 0,
        })
    end

    -- (B) Quick expanding ring
    -- A single particle that grows via custom update
    spawnParticle(frame, {
        x        = 0,
        y        = 0,
        vx       = 0,
        vy       = 0,
        gravity  = 0,
        maxLife  = 0.35,
        size     = 2,
        r        = COLOR_ACCENT[1],
        g        = COLOR_ACCENT[2],
        b        = COLOR_ACCENT[3],
        a        = 0.6,
        rotation = 0,
        rotSpeed = 0,
        custom   = function(s, elapsed)
            local ratio = s.life / s.maxLife
            s.size = 2 + ratio * 50
        end,
    })
end

---------------------------------------------------------------------------
-- ========================  EFFECT 4  ========================
-- PlayScanCompleteEffect(anchorFrame)
-- Scanner beam: sweeping line of green particles left to right
---------------------------------------------------------------------------
function PS:PlayScanCompleteEffect(frame)
    if not frame then return end

    local fw = frame:GetWidth()
    local fh = frame:GetHeight()
    local halfW = fw * 0.5
    local halfH = fh * 0.5
    local sweepDuration = 0.6
    local particlesPerWave = 18

    -- Spawn particles in staggered waves across the width
    for i = 1, particlesPerWave do
        local delay = (i / particlesPerWave) * sweepDuration
        C_Timer.After(delay, function()
            if not frame:IsVisible() then return end
            -- Each wave column: 3 particles vertically distributed
            for j = 1, 3 do
                local yPos = randf(-halfH * 0.7, halfH * 0.7)
                local xStart = -halfW + (i / particlesPerWave) * fw
                local bright = randf(0.6, 1.0)
                spawnParticle(frame, {
                    x        = xStart,
                    y        = yPos,
                    vx       = randf(15, 35),
                    vy       = randf(-10, 10),
                    gravity  = 0,
                    maxLife  = randf(0.4, 0.7),
                    size     = randf(2, 5),
                    r        = COLOR_GREEN[1] * bright,
                    g        = COLOR_GREEN[2] * bright + (1 - bright) * 0.3,
                    b        = COLOR_GREEN[3] * bright,
                    a        = 0.9,
                    rotation = 0,
                    rotSpeed = randf(-2, 2),
                })
            end
        end)
    end

    -- Trailing sweep line (a bright bar moving left to right)
    local sweepTex
    local sweepOverlay = acquireOverlay(frame, "HIGH", 65)
    sweepTex = sweepOverlay:CreateTexture(nil, "OVERLAY")
    sweepTex:SetTexture(SOLID)
    sweepTex:SetSize(3, fh * 0.8)
    sweepTex:SetVertexColor(COLOR_GREEN[1], COLOR_GREEN[2], COLOR_GREEN[3], 0.7)
    sweepTex:SetBlendMode("ADD")
    sweepTex:Show()

    local sweepTime = 0
    sweepOverlay:SetScript("OnUpdate", function(self, elapsed)
        sweepTime = sweepTime + elapsed
        if sweepTime >= sweepDuration then
            sweepTex:Hide()
            sweepTex:SetParent(nil)
            releaseOverlay(sweepOverlay)
            return
        end
        local ratio = sweepTime / sweepDuration
        -- Ease-out: decelerate near the end
        local eased = 1 - (1 - ratio) * (1 - ratio)
        local xPos = -halfW + eased * fw
        sweepTex:ClearAllPoints()
        sweepTex:SetPoint("CENTER", frame, "CENTER", xPos, 0)
        -- Fade out in last 30%
        local alpha = 0.7
        if ratio > 0.7 then
            alpha = 0.7 * (1 - (ratio - 0.7) / 0.3)
        end
        sweepTex:SetVertexColor(COLOR_GREEN[1], COLOR_GREEN[2], COLOR_GREEN[3], math_max(0, alpha))
    end)

    -- Finishing flash
    C_Timer.After(sweepDuration * 0.8, function()
        if not frame:IsVisible() then return end
        -- Subtle green flash
        local finishOverlay = acquireOverlay(frame, "HIGH", 66)
        local finishTex = finishOverlay:CreateTexture(nil, "BACKGROUND")
        finishTex:SetAllPoints(finishOverlay)
        finishTex:SetTexture(SOLID)
        finishTex:SetVertexColor(COLOR_GREEN[1], COLOR_GREEN[2], COLOR_GREEN[3], 0)
        finishTex:Show()

        local ft = 0
        finishOverlay:SetScript("OnUpdate", function(self, elapsed)
            ft = ft + elapsed
            if ft >= 0.25 then
                finishTex:Hide()
                finishTex:SetParent(nil)
                releaseOverlay(finishOverlay)
                return
            end
            local r = ft / 0.25
            local a = (r < 0.3) and (r / 0.3 * 0.15) or (0.15 * (1 - (r - 0.3) / 0.7))
            finishTex:SetVertexColor(COLOR_GREEN[1], COLOR_GREEN[2], COLOR_GREEN[3], math_max(0, a))
        end)
    end)
end

-- Keep backwards compat: PlaySuccessEffect maps to scan complete
function PS:PlaySuccessEffect(frame)
    self:PlayScanCompleteEffect(frame)
end

---------------------------------------------------------------------------
-- ========================  EFFECT 5  ========================
-- PlayAchievementEffect(anchorFrame)
-- Purple/gold starburst + floating icon shimmer
---------------------------------------------------------------------------
function PS:PlayAchievementEffect(frame)
    if not frame then return end

    local cx = 0
    local cy = 0

    ---------------------------------------------------------------
    -- (A) Purple/Gold Starburst  --  10 rays, 4 particles each
    ---------------------------------------------------------------
    local achieveColors = {
        COLOR_PURPLE,
        {0.70, 0.50, 1.00},
        COLOR_GOLD,
        {1.00, 0.92, 0.50},
    }
    for ray = 1, 10 do
        local angle = (ray / 10) * TWO_PI
        for step = 1, 4 do
            local col   = achieveColors[((ray + step) % #achieveColors) + 1]
            local speed = randf(80, 150) + step * 25
            spawnParticle(frame, {
                x        = cx + math_cos(angle) * step * 8,
                y        = cy + math_sin(angle) * step * 8,
                vx       = math_cos(angle) * speed,
                vy       = math_sin(angle) * speed,
                gravity  = 0,
                maxLife  = randf(0.5, 0.9),
                size     = randf(3, 6),
                r        = col[1], g = col[2], b = col[3],
                a        = 1,
                rotation = angle,
                rotSpeed = randf(-2, 2),
            })
        end
    end

    ---------------------------------------------------------------
    -- (B) Expanding Purple Ring
    ---------------------------------------------------------------
    spawnParticle(frame, {
        x = cx, y = cy,
        vx = 0, vy = 0,
        gravity  = 0,
        maxLife  = 0.5,
        size     = 4,
        r        = COLOR_PURPLE[1],
        g        = COLOR_PURPLE[2],
        b        = COLOR_PURPLE[3],
        a        = 0.7,
        rotation = 0,
        rotSpeed = 0,
        custom   = function(s, elapsed)
            local ratio = s.life / s.maxLife
            s.size = 4 + ratio * 80
        end,
    })

    ---------------------------------------------------------------
    -- (C) Sparkle Orbit  --  8 particles orbiting briefly
    ---------------------------------------------------------------
    for i = 1, 8 do
        local startAngle = (i / 8) * TWO_PI
        local orbitRadius = randf(30, 50)
        local orbitSpeed  = randf(4, 7) * (math_random() > 0.5 and 1 or -1)
        spawnParticle(frame, {
            x        = cx + math_cos(startAngle) * orbitRadius,
            y        = cy + math_sin(startAngle) * orbitRadius,
            vx       = 0,
            vy       = 0,
            gravity  = 0,
            maxLife  = randf(0.8, 1.2),
            size     = randf(2, 4),
            r        = 1.0, g = 0.95, b = 0.80,
            a        = 1,
            rotation = 0,
            rotSpeed = 0,
            custom   = function(s, elapsed)
                local angle = startAngle + s.life * orbitSpeed
                local expandRadius = orbitRadius + s.life * 30
                s.x = cx + math_cos(angle) * expandRadius
                s.y = cy + math_sin(angle) * expandRadius
                -- Override velocity so physics doesn't fight the orbit
                s.vx = 0
                s.vy = 0
            end,
        })
    end

    ---------------------------------------------------------------
    -- (D) Screen Flash (purple tint)
    ---------------------------------------------------------------
    local flashFrame = acquireOverlay(frame, "HIGH", 70)
    local flashTex = flashFrame:CreateTexture(nil, "BACKGROUND")
    flashTex:SetAllPoints(flashFrame)
    flashTex:SetTexture(SOLID)
    flashTex:SetVertexColor(COLOR_PURPLE[1], COLOR_PURPLE[2], COLOR_PURPLE[3], 0)
    flashTex:Show()

    local flashTime = 0
    local flashDur  = 0.35
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        flashTime = flashTime + elapsed
        if flashTime >= flashDur then
            flashTex:Hide()
            flashTex:SetParent(nil)
            releaseOverlay(flashFrame)
            return
        end
        local ratio = flashTime / flashDur
        local alpha
        if ratio < 0.3 then
            alpha = (ratio / 0.3) * 0.3
        else
            alpha = 0.3 * (1 - (ratio - 0.3) / 0.7)
        end
        flashTex:SetVertexColor(COLOR_PURPLE[1], COLOR_PURPLE[2], COLOR_PURPLE[3], math_max(0, alpha))
    end)

    ---------------------------------------------------------------
    -- (E) Floating Achievement Text
    ---------------------------------------------------------------
    for i = 1, 5 do
        C_Timer.After(randf(0, 0.3), function()
            if not frame:IsVisible() then return end
            local fs = acquireText(poolParent)
            fs:SetText("\226\152\133")  -- star symbol
            local col = (math_random() > 0.5) and COLOR_PURPLE or COLOR_GOLD
            fs:SetTextColor(col[1], col[2], col[3], 1)
            local startX = randf(-60, 60)
            local startY = randf(-20, 20)
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", frame, "CENTER", startX, startY)

            local sLife = 0
            local sMax  = randf(1.0, 1.6)
            local drift = randf(-12, 12)
            local rise  = randf(35, 55)

            local sFrame = acquireOverlay(frame, "HIGH", 75)
            sFrame:SetScript("OnUpdate", function(self, elapsed)
                sLife = sLife + elapsed
                if sLife >= sMax then
                    releaseText(fs)
                    releaseOverlay(sFrame)
                    return
                end
                local r = sLife / sMax
                local alpha = 1 - r * r
                fs:SetTextColor(col[1], col[2], col[3], math_max(0, alpha))
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", frame, "CENTER",
                    startX + drift * r,
                    startY + rise * sLife)
            end)
        end)
    end

    -- Sound (safe in case SOUNDKIT key missing)
    if SOUNDKIT and SOUNDKIT.UI_70_ARTIFACT_FORGE_APPEARANCE_APPEARANCE_CHANGE then
        PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_APPEARANCE_APPEARANCE_CHANGE)
    else
        PlaySound(888) -- level-up fallback
    end
end

---------------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------------
function PS:ClearAll()
    -- Release all active particles
    for i = 1, activeCount do
        local s = activeList[i]
        if s then
            releaseParticle(s.tex, s.idx)
        end
        activeList[i] = nil
    end
    activeCount = 0

    -- Release overlays
    for _, f in ipairs(overlayAvail) do
        f:Hide()
    end
end
