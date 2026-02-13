local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Particle & Visual Effects System
-- Premium visual effects for that "wow factor"
-- ═══════════════════════════════════════════════════════════════════

ns.ParticleSystem = ns.ParticleSystem or {}
local PS = ns.ParticleSystem

local particlePools = {}
local activeParticles = {}
local updateFrame

---------------------------------------------------------------------------
-- Particle Object Pool
---------------------------------------------------------------------------
local function createParticle(parent)
    local p = parent:CreateTexture(nil, "OVERLAY")
    p:SetTexture("Interface\\Buttons\\WHITE8x8")  -- Simple white texture
    p:SetBlendMode("ADD")  -- Glow effect
    p:Hide()

    -- Particle state
    p._active = false
    p._x = 0
    p._y = 0
    p._vx = 0
    p._vy = 0
    p._life = 0
    p._maxLife = 1
    p._size = 1
    p._rotation = 0
    p._rotSpeed = 0
    p._r = 1
    p._g = 1
    p._b = 1
    p._alpha = 1
    p._fadeStart = 0.7

    return p
end

local function getParticle(parent)
    local poolKey = parent:GetName() or tostring(parent)
    if not particlePools[poolKey] then
        particlePools[poolKey] = {}
    end

    -- Try to reuse inactive particle
    for _, p in ipairs(particlePools[poolKey]) do
        if not p._active then
            p._active = true
            p:Show()
            table.insert(activeParticles, p)
            return p
        end
    end

    -- Create new particle
    local p = createParticle(parent)
    table.insert(particlePools[poolKey], p)
    p._active = true
    p:Show()
    table.insert(activeParticles, p)
    return p
end

local function releaseParticle(p)
    p._active = false
    p:Hide()

    -- Remove from active list
    for i = #activeParticles, 1, -1 do
        if activeParticles[i] == p then
            table.remove(activeParticles, i)
            break
        end
    end
end

---------------------------------------------------------------------------
-- Particle Update Loop
---------------------------------------------------------------------------
local function updateParticles(_, elapsed)
    for i = #activeParticles, 1, -1 do
        local p = activeParticles[i]

        -- Update lifetime
        p._life = p._life + elapsed
        if p._life >= p._maxLife then
            releaseParticle(p)
        else
            -- Update position
            p._x = p._x + p._vx * elapsed
            p._y = p._y + p._vy * elapsed

            -- Update rotation
            p._rotation = p._rotation + p._rotSpeed * elapsed

            -- Apply gravity/acceleration
            if p._gravity then
                p._vy = p._vy + p._gravity * elapsed
            end

            -- Fade out near end of life
            local lifeRatio = p._life / p._maxLife
            local alpha = p._alpha
            if lifeRatio > p._fadeStart then
                local fadeRatio = (lifeRatio - p._fadeStart) / (1 - p._fadeStart)
                alpha = p._alpha * (1 - fadeRatio)
            end

            -- Apply transformations
            p:SetPoint("CENTER", p:GetParent(), "BOTTOMLEFT", p._x, p._y)
            p:SetSize(p._size, p._size)
            p:SetRotation(p._rotation)
            p:SetVertexColor(p._r, p._g, p._b, alpha)
        end
    end
end

---------------------------------------------------------------------------
-- Initialize Update Frame
---------------------------------------------------------------------------
function PS:Init()
    if updateFrame then return end

    updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", updateParticles)
end

---------------------------------------------------------------------------
-- Effect Presets
---------------------------------------------------------------------------

-- Confetti explosion (for when recruit joins!)
function PS:Confetti(parent, x, y, count)
    count = count or 20

    for i = 1, count do
        local p = getParticle(parent)

        -- Random direction and speed
        local angle = math.random() * math.pi * 2
        local speed = 100 + math.random() * 150

        p._x = x
        p._y = y
        p._vx = math.cos(angle) * speed
        p._vy = math.sin(angle) * speed + 100  -- Upward bias
        p._gravity = -400  -- Gravity pulls down

        p._life = 0
        p._maxLife = 1.5 + math.random() * 0.5
        p._size = 8 + math.random() * 8
        p._rotation = math.random() * math.pi * 2
        p._rotSpeed = (math.random() - 0.5) * 10

        -- Random bright colors
        local colors = {
            C.gold,
            C.accent,
            C.purple,
            C.green,
            C.orange,
        }
        local color = colors[math.random(#colors)]
        p._r, p._g, p._b = color[1], color[2], color[3]
        p._alpha = 1
        p._fadeStart = 0.6
    end
end

-- Sparkles (gentle floating particles)
function PS:Sparkles(parent, x, y, count, duration)
    count = count or 10
    duration = duration or 2

    for i = 1, count do
        local p = getParticle(parent)

        -- Slow random drift
        local angle = math.random() * math.pi * 2
        local speed = 20 + math.random() * 30

        p._x = x + (math.random() - 0.5) * 40
        p._y = y + (math.random() - 0.5) * 40
        p._vx = math.cos(angle) * speed
        p._vy = math.sin(angle) * speed + 50  -- Slight upward float
        p._gravity = 0

        p._life = 0
        p._maxLife = duration + math.random() * 0.5
        p._size = 4 + math.random() * 6
        p._rotation = math.random() * math.pi * 2
        p._rotSpeed = (math.random() - 0.5) * 2

        -- Accent color with slight variation
        p._r = C.accent[1] + (math.random() - 0.5) * 0.2
        p._g = C.accent[2] + (math.random() - 0.5) * 0.2
        p._b = C.accent[3] + (math.random() - 0.5) * 0.2
        p._alpha = 0.8
        p._fadeStart = 0.5
    end
end

-- Star burst (radial explosion)
function PS:StarBurst(parent, x, y, count)
    count = count or 12

    for i = 1, count do
        local p = getParticle(parent)

        -- Evenly distributed angles
        local angle = (i / count) * math.pi * 2
        local speed = 150 + math.random() * 50

        p._x = x
        p._y = y
        p._vx = math.cos(angle) * speed
        p._vy = math.sin(angle) * speed
        p._gravity = 0

        p._life = 0
        p._maxLife = 0.8 + math.random() * 0.3
        p._size = 10 + math.random() * 5
        p._rotation = angle
        p._rotSpeed = 0

        -- Gold to white gradient
        p._r = 1
        p._g = 0.84 + math.random() * 0.16
        p._b = math.random() * 0.3
        p._alpha = 1
        p._fadeStart = 0.4
    end
end

-- Shimmer effect (horizontal wave)
function PS:Shimmer(parent, x, y, width)
    width = width or 200
    local count = math.floor(width / 20)

    for i = 1, count do
        local p = getParticle(parent)

        local offsetX = (i / count - 0.5) * width

        p._x = x + offsetX
        p._y = y
        p._vx = 0
        p._vy = 40 + math.random() * 20
        p._gravity = 0

        p._life = 0
        p._maxLife = 1 + (i / count) * 0.3  -- Staggered
        p._size = 6 + math.random() * 4
        p._rotation = 0
        p._rotSpeed = 0

        -- Accent shimmer
        p._r, p._g, p._b = C.accent[1], C.accent[2], C.accent[3]
        p._alpha = 0.6
        p._fadeStart = 0.3
    end
end

-- Glow pulse (expanding ring)
function PS:GlowPulse(parent, x, y, color, maxSize)
    color = color or C.accent
    maxSize = maxSize or 100

    local p = getParticle(parent)

    p._x = x
    p._y = y
    p._vx = 0
    p._vy = 0
    p._gravity = 0

    p._life = 0
    p._maxLife = 0.6
    p._size = 0
    p._rotation = 0
    p._rotSpeed = 0

    p._r, p._g, p._b = color[1], color[2], color[3]
    p._alpha = 0.5
    p._fadeStart = 0

    -- Animate size expansion
    local startTime = GetTime()
    p._customUpdate = function(self, elapsed)
        local ratio = self._life / self._maxLife
        self._size = ratio * maxSize
    end
end

---------------------------------------------------------------------------
-- Convenience Wrappers
---------------------------------------------------------------------------

function PS:PlayRecruitJoinedEffect(frame)
    local x, y = frame:GetWidth() / 2, frame:GetHeight() / 2
    self:Confetti(frame, x, y, 30)
    self:StarBurst(frame, x, y, 16)

    -- Play sound
    PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN)
end

function PS:PlayHoverEffect(frame)
    local x, y = frame:GetWidth() / 2, frame:GetHeight() / 2
    self:Sparkles(frame, x, y, 3, 0.5)
end

function PS:PlayClickEffect(frame)
    local x, y = frame:GetWidth() / 2, frame:GetHeight() / 2
    self:GlowPulse(frame, x, y, C.accent, 60)
end

function PS:PlaySuccessEffect(frame)
    local x, y = frame:GetWidth() / 2, frame:GetHeight() / 2
    self:Shimmer(frame, x, y, frame:GetWidth())
    PlaySound(SOUNDKIT.ACHIEVEMENT_MENU_OPEN)
end

---------------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------------

function PS:ClearAll()
    for i = #activeParticles, 1, -1 do
        releaseParticle(activeParticles[i])
    end
end
