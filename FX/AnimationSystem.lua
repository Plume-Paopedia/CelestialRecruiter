local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Advanced Animation System
-- Shimmer, glow pulse, number counter, progress bar, fade transition,
-- bounce-in, slide reveal, typewriter text, and legacy effects
-- ═══════════════════════════════════════════════════════════════════

ns.AnimationSystem = ns.AnimationSystem or {}
local AS = ns.AnimationSystem

local SOLID = "Interface\\Buttons\\WHITE8x8"
local math_sin   = math.sin
local math_cos   = math.cos
local math_abs   = math.abs
local math_floor = math.floor
local math_min   = math.min
local math_max   = math.max
local math_pow   = math.pow
local math_pi    = math.pi
local GetTime    = GetTime

---------------------------------------------------------------------------
-- Easing Functions
---------------------------------------------------------------------------
local function easeOut(t)
    return 1 - (1 - t) * (1 - t)
end

local function easeInOut(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - (-2 * t + 2) * (-2 * t + 2) / 2
    end
end

local function easeOutCubic(t)
    return 1 - math_pow(1 - t, 3)
end

local function elasticOut(t)
    if t == 0 or t == 1 then return t end
    local p = 0.35
    return math_pow(2, -10 * t) * math_sin((t - p / 4) * (2 * math_pi) / p) + 1
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp01(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    return t
end

---------------------------------------------------------------------------
-- Internal: Create a lightweight driver frame for OnUpdate animations
-- Returns the driver frame. Call driver:Cancel() to stop and clean up.
---------------------------------------------------------------------------
local driverPool = {}

local function AcquireDriver()
    local driver = table.remove(driverPool)
    if not driver then
        driver = CreateFrame("Frame")
    end
    driver._cancelled = false
    driver:Show()
    return driver
end

local function ReleaseDriver(driver)
    driver:SetScript("OnUpdate", nil)
    driver:Hide()
    driver._cancelled = true
    table.insert(driverPool, driver)
end

-- Helper to create a driver with automatic cleanup after duration
local function CreateTimedDriver(duration, onTick, onFinish)
    local driver = AcquireDriver()
    local startTime = GetTime()

    driver.Cancel = function(self)
        if not self._cancelled then
            ReleaseDriver(self)
        end
    end

    driver:SetScript("OnUpdate", function(self, elapsed)
        if self._cancelled then return end
        local now = GetTime()
        local progress = clamp01((now - startTime) / duration)

        onTick(self, progress, elapsed)

        if progress >= 1 then
            ReleaseDriver(self)
            if onFinish then onFinish() end
        end
    end)

    return driver
end

-- Helper to create a driver that runs indefinitely until cancelled
local function CreateLoopingDriver(onTick)
    local driver = AcquireDriver()
    local startTime = GetTime()

    driver.Cancel = function(self)
        if not self._cancelled then
            ReleaseDriver(self)
        end
    end

    driver:SetScript("OnUpdate", function(self, elapsed)
        if self._cancelled then return end
        local now = GetTime()
        onTick(self, now - startTime, elapsed)
    end)

    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 1. SHIMMER EFFECT
--    Subtle diagonal light sweep across a frame, looping every 3s.
-- ═══════════════════════════════════════════════════════════════════
local shimmerPool = {}

local function AcquireShimmerTexture(parent)
    local tex = table.remove(shimmerPool)
    if not tex then
        tex = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:SetTexture(SOLID)
        tex:SetBlendMode("ADD")
    else
        tex:SetParent(parent)
        tex:SetDrawLayer("OVERLAY", 7)
    end
    return tex
end

local function ReleaseShimmerTexture(tex)
    tex:Hide()
    tex:ClearAllPoints()
    table.insert(shimmerPool, tex)
end

function AS:AddShimmer(frame)
    if not frame then return end

    -- Prevent duplicates
    if frame._shimmerDriver then
        frame._shimmerDriver:Cancel()
    end

    local shimmerWidth = 20  -- thin diagonal band width
    local cycleDuration = 3.0

    local tex = AcquireShimmerTexture(frame)
    tex:SetSize(shimmerWidth, frame:GetHeight() * 2)
    tex:SetVertexColor(1, 1, 1, 0.08)
    tex:SetRotation(math_pi / 6)  -- ~30 degree diagonal
    tex:Show()

    -- Clip shimmer to parent bounds
    frame:SetClipsChildren(true)

    local driver = CreateLoopingDriver(function(self, totalElapsed, elapsed)
        if not frame:IsVisible() then return end
        local frameWidth = frame:GetWidth()
        if frameWidth <= 0 then return end

        local cycleTime = totalElapsed % cycleDuration
        local progress = cycleTime / cycleDuration

        -- Sweep from left edge to right edge with overshoot for clean entry/exit
        local startX = -shimmerWidth * 2
        local endX = frameWidth + shimmerWidth * 2
        local currentX = lerp(startX, endX, progress)

        tex:ClearAllPoints()
        tex:SetPoint("CENTER", frame, "LEFT", currentX, 0)

        -- Fade in near edges so it appears/disappears smoothly
        local edgeFade = 1.0
        local entryZone = shimmerWidth * 2
        local exitZone = shimmerWidth * 2
        if currentX < entryZone then
            edgeFade = clamp01(currentX / entryZone)
        elseif currentX > (frameWidth - exitZone) then
            edgeFade = clamp01((frameWidth - currentX) / exitZone)
        end
        -- Never allow negative alpha
        edgeFade = math_max(0, edgeFade)
        tex:SetVertexColor(1, 1, 1, 0.08 * edgeFade)

        -- Update height in case frame resized
        tex:SetHeight(math_max(1, frame:GetHeight() * 2))
    end)

    frame._shimmerDriver = driver
    frame._shimmerTexture = tex

    -- Attach cleanup
    frame:HookScript("OnHide", function()
        -- Pause when hidden (driver auto-skips via IsVisible check)
    end)

    -- Public API to remove
    function frame:RemoveShimmer()
        if self._shimmerDriver then
            self._shimmerDriver:Cancel()
            self._shimmerDriver = nil
        end
        if self._shimmerTexture then
            ReleaseShimmerTexture(self._shimmerTexture)
            self._shimmerTexture = nil
        end
    end

    return frame
end


-- ═══════════════════════════════════════════════════════════════════
-- 2. GLOW PULSE
--    Soft pulsing glow border around a frame.
--    color: "gold", "accent", "green", or {r, g, b}
-- ═══════════════════════════════════════════════════════════════════
local glowTexPool = {}

local function AcquireGlowTexture(parent)
    local tex = table.remove(glowTexPool)
    if not tex then
        tex = parent:CreateTexture(nil, "OVERLAY", nil, 6)
        tex:SetTexture(SOLID)
        tex:SetBlendMode("ADD")
    else
        tex:SetParent(parent)
        tex:SetDrawLayer("OVERLAY", 6)
    end
    return tex
end

local function ReleaseGlowTexture(tex)
    tex:Hide()
    tex:ClearAllPoints()
    table.insert(glowTexPool, tex)
end

local GLOW_COLOR_MAP = {
    gold   = {1.00, 0.84, 0.00},
    accent = {0.00, 0.68, 1.00},
    green  = {0.20, 0.88, 0.48},
    purple = {0.58, 0.40, 1.00},
    orange = {1.00, 0.70, 0.28},
    red    = {1.00, 0.40, 0.40},
}

local function ResolveGlowColor(color)
    if type(color) == "string" then
        return GLOW_COLOR_MAP[color] or GLOW_COLOR_MAP.gold
    elseif type(color) == "table" then
        return color
    end
    return GLOW_COLOR_MAP.gold
end

function AS:AddGlowPulse(frame, color)
    if not frame then return end

    -- Prevent duplicates
    if frame._glowPulseDriver then
        frame._glowPulseDriver:Cancel()
    end
    if frame._glowTextures then
        for _, tex in ipairs(frame._glowTextures) do
            ReleaseGlowTexture(tex)
        end
    end

    local c = ResolveGlowColor(color)
    local thickness = 2

    -- Create four edge glow textures: top, bottom, left, right
    local top    = AcquireGlowTexture(frame)
    local bottom = AcquireGlowTexture(frame)
    local left   = AcquireGlowTexture(frame)
    local right  = AcquireGlowTexture(frame)

    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, thickness)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, thickness)
    top:SetHeight(thickness)

    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -thickness)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -thickness)
    bottom:SetHeight(thickness)

    left:SetPoint("TOPLEFT", frame, "TOPLEFT", -thickness, thickness)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -thickness, -thickness)
    left:SetWidth(thickness)

    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", thickness, thickness)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", thickness, -thickness)
    right:SetWidth(thickness)

    local textures = {top, bottom, left, right}
    frame._glowTextures = textures

    -- Initial state: hidden
    for _, tex in ipairs(textures) do
        tex:SetVertexColor(c[1], c[2], c[3], 0.2)
        tex:Hide()
    end

    -- Pulse driver (sine wave between 0.2 and 0.6 alpha)
    local pulsing = false
    local pulseSpeed = 2.0  -- full cycle in ~pi seconds

    local driver = CreateLoopingDriver(function(self, totalElapsed, elapsed)
        if not pulsing then return end
        if not frame:IsVisible() then return end

        local wave = math_sin(totalElapsed * pulseSpeed * math_pi)
        local alpha = lerp(0.2, 0.6, (wave + 1) / 2)

        for _, tex in ipairs(textures) do
            tex:SetVertexColor(c[1], c[2], c[3], alpha)
        end
    end)

    frame._glowPulseDriver = driver

    -- Public API: StartPulse / StopPulse
    function frame:StartPulse()
        pulsing = true
        for _, tex in ipairs(textures) do
            tex:Show()
        end
    end

    function frame:StopPulse()
        pulsing = false
        for _, tex in ipairs(textures) do
            tex:Hide()
        end
    end

    function frame:SetGlowColor(newColor)
        c = ResolveGlowColor(newColor)
        for _, tex in ipairs(textures) do
            tex:SetVertexColor(c[1], c[2], c[3], 0.2)
        end
    end

    function frame:RemoveGlowPulse()
        if self._glowPulseDriver then
            self._glowPulseDriver:Cancel()
            self._glowPulseDriver = nil
        end
        if self._glowTextures then
            for _, tex in ipairs(self._glowTextures) do
                ReleaseGlowTexture(tex)
            end
            self._glowTextures = nil
        end
        self.StartPulse = nil
        self.StopPulse = nil
        self.SetGlowColor = nil
        self.RemoveGlowPulse = nil
    end

    return frame
end


-- ═══════════════════════════════════════════════════════════════════
-- 3. NUMBER COUNTER ANIMATION
--    Smooth animated number counting with ease-out curve.
-- ═══════════════════════════════════════════════════════════════════
function AS:AnimateNumber(fontString, fromVal, toVal, duration)
    if not fontString then return end
    fromVal  = fromVal  or 0
    toVal    = toVal    or 0
    duration = duration or 0.8

    -- Cancel any existing counter on this fontString
    if fontString._counterDriver then
        fontString._counterDriver:Cancel()
    end

    -- If same value, just set it
    if fromVal == toVal then
        fontString:SetText(tostring(math_floor(toVal)))
        return
    end

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local eased = easeOut(progress)
            local current = lerp(fromVal, toVal, eased)
            fontString:SetText(tostring(math_floor(current + 0.5)))
        end,
        function()
            fontString:SetText(tostring(math_floor(toVal + 0.5)))
            fontString._counterDriver = nil
        end
    )

    fontString._counterDriver = driver
    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 4. PROGRESS BAR FILL
--    Smooth width animation with ease-out. Optional color transition.
--    colorFrom / colorTo: {r, g, b} tables or nil to skip coloring.
-- ═══════════════════════════════════════════════════════════════════
function AS:AnimateBar(texture, fromWidth, toWidth, duration, colorFrom, colorTo)
    if not texture then return end
    fromWidth = fromWidth or 0
    toWidth   = toWidth   or 0
    duration  = duration  or 0.5

    -- Ensure minimum width so texture is valid
    fromWidth = math_max(1, fromWidth)
    toWidth   = math_max(1, toWidth)

    -- Cancel any existing bar animation on this texture
    if texture._barDriver then
        texture._barDriver:Cancel()
    end

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local eased = easeOut(progress)
            local currentWidth = lerp(fromWidth, toWidth, eased)
            texture:SetWidth(math_max(1, currentWidth))

            -- Optional color transition
            if colorFrom and colorTo then
                local r = lerp(colorFrom[1], colorTo[1], eased)
                local g = lerp(colorFrom[2], colorTo[2], eased)
                local b = lerp(colorFrom[3], colorTo[3], eased)
                texture:SetVertexColor(r, g, b, 1)
            end
        end,
        function()
            texture:SetWidth(math_max(1, toWidth))
            if colorTo then
                texture:SetVertexColor(colorTo[1], colorTo[2], colorTo[3], 1)
            end
            texture._barDriver = nil
        end
    )

    texture._barDriver = driver
    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 5. FADE TRANSITION
--    Full fade-out then fade-in. Callback fires at the midpoint.
-- ═══════════════════════════════════════════════════════════════════
function AS:FadeTransition(frame, callback)
    if not frame then return end

    local fadeOutDuration = 0.10
    local fadeInDuration  = 0.15

    -- Cancel any existing fade on this frame
    if frame._fadeDriver then
        frame._fadeDriver:Cancel()
    end

    -- Phase 1: Fade out
    local driver = CreateTimedDriver(fadeOutDuration,
        function(self, progress, elapsed)
            local alpha = lerp(1, 0, easeOut(progress))
            frame:SetAlpha(math_max(0, alpha))
        end,
        function()
            frame:SetAlpha(0)
            frame._fadeDriver = nil

            -- Fire callback at the midpoint (content is invisible)
            if callback then callback() end

            -- Phase 2: Fade in
            local driver2 = CreateTimedDriver(fadeInDuration,
                function(self, progress, elapsed)
                    local alpha = lerp(0, 1, easeOut(progress))
                    frame:SetAlpha(math_min(1, alpha))
                end,
                function()
                    frame:SetAlpha(1)
                    frame._fadeDriver = nil
                end
            )
            frame._fadeDriver = driver2
        end
    )

    frame._fadeDriver = driver
    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 6. BOUNCE IN
--    Scale 0.8 → 1.05 → 1.0  with alpha 0 → 1.  0.3s total.
-- ═══════════════════════════════════════════════════════════════════
function AS:BounceIn(frame)
    if not frame then return end

    local duration = 0.3

    -- Cancel any existing bounce
    if frame._bounceDriver then
        frame._bounceDriver:Cancel()
    end

    -- We need a scale-able wrapper; WoW frames don't have direct SetScale
    -- that animates smoothly, so we use the AnimationGroup approach.
    -- But for OnUpdate-driven control, we use frame:SetScale directly.
    local origScale = 1.0
    frame:SetAlpha(0)
    frame:SetScale(0.8)

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            -- Alpha: simple 0 → 1 over first 60% of duration
            local alphaProgress = clamp01(progress / 0.6)
            frame:SetAlpha(easeOut(alphaProgress))

            -- Scale: 0.8 → 1.05 (at ~70%) → 1.0 (at 100%)
            -- Use elasticOut for the bouncy overshoot feel
            local scale
            if progress < 0.7 then
                -- Rise phase: 0.8 to 1.05
                local p = progress / 0.7
                scale = lerp(0.8, 1.05, easeOut(p))
            else
                -- Settle phase: 1.05 to 1.0
                local p = (progress - 0.7) / 0.3
                scale = lerp(1.05, origScale, easeOut(p))
            end
            frame:SetScale(math_max(0.01, scale))
        end,
        function()
            frame:SetAlpha(1)
            frame:SetScale(origScale)
            frame._bounceDriver = nil
        end
    )

    frame._bounceDriver = driver
    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 7. SLIDE REVEAL
--    Content reveal with slide + fade.
--    direction: "left", "right", "up", "down"  (default "left")
--    0.25s duration
-- ═══════════════════════════════════════════════════════════════════
function AS:SlideReveal(frame, direction)
    if not frame then return end

    direction = direction or "left"
    local duration = 0.25
    local slideDistance = 30

    -- Cancel any existing slide
    if frame._slideDriver then
        frame._slideDriver:Cancel()
    end

    -- Capture original anchor points so we can restore them
    local originalPoints = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        table.insert(originalPoints, {point, relativeTo, relativePoint, x, y})
    end

    -- Determine offset direction
    local offsetX, offsetY = 0, 0
    if direction == "left" then
        offsetX = -slideDistance
    elseif direction == "right" then
        offsetX = slideDistance
    elseif direction == "up" then
        offsetY = slideDistance
    elseif direction == "down" then
        offsetY = -slideDistance
    end

    -- Set initial offset position
    frame:SetAlpha(0)
    frame:ClearAllPoints()
    for _, pd in ipairs(originalPoints) do
        frame:SetPoint(pd[1], pd[2], pd[3], pd[4] + offsetX, pd[5] + offsetY)
    end

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local eased = easeOut(progress)
            frame:SetAlpha(eased)

            local curOffX = lerp(offsetX, 0, eased)
            local curOffY = lerp(offsetY, 0, eased)

            frame:ClearAllPoints()
            for _, pd in ipairs(originalPoints) do
                frame:SetPoint(pd[1], pd[2], pd[3], pd[4] + curOffX, pd[5] + curOffY)
            end
        end,
        function()
            -- Restore exact original points and full alpha
            frame:SetAlpha(1)
            frame:ClearAllPoints()
            for _, pd in ipairs(originalPoints) do
                frame:SetPoint(pd[1], pd[2], pd[3], pd[4], pd[5])
            end
            frame._slideDriver = nil
        end
    )

    frame._slideDriver = driver
    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- 8. TYPEWRITER TEXT
--    Characters appear one by one on a FontString.
--    speed = characters per second (default 30)
--    Returns a cancel function.
-- ═══════════════════════════════════════════════════════════════════
function AS:TypewriterText(fontString, fullText, speed)
    if not fontString or not fullText then return function() end end
    speed = speed or 30

    -- Cancel any existing typewriter on this fontString
    if fontString._typewriterDriver then
        fontString._typewriterDriver:Cancel()
    end

    local textLen = #fullText
    if textLen == 0 then
        fontString:SetText("")
        return function() end
    end

    local duration = textLen / speed
    fontString:SetText("")

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local charCount = math_floor(progress * textLen + 0.5)
            charCount = math_min(charCount, textLen)
            fontString:SetText(fullText:sub(1, charCount))
        end,
        function()
            fontString:SetText(fullText)
            fontString._typewriterDriver = nil
        end
    )

    fontString._typewriterDriver = driver

    -- Return a cancel function
    local function cancel()
        if driver and not driver._cancelled then
            driver:Cancel()
            fontString:SetText(fullText)
            fontString._typewriterDriver = nil
        end
    end

    return cancel
end


-- ═══════════════════════════════════════════════════════════════════
-- LEGACY EFFECTS (preserved from v1 for backwards compatibility)
-- ═══════════════════════════════════════════════════════════════════

---------------------------------------------------------------------------
-- Staggered List Animation (items fade/slide in one by one)
---------------------------------------------------------------------------
function AS:StaggeredFadeIn(frames, delay, offset)
    delay = delay or 0.03
    offset = offset or 20

    for i, frame in ipairs(frames) do
        if frame and frame:IsShown() then
            -- Stop any existing staggered animation
            if frame._staggerAG then
                frame._staggerAG:Stop()
                frame._staggerAG = nil
            end

            frame:SetAlpha(0)
            local originalPoints = {}
            for j = 1, frame:GetNumPoints() do
                local point, relativeTo, relativePoint, x, y = frame:GetPoint(j)
                table.insert(originalPoints, {point, relativeTo, relativePoint, x, y})
            end

            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4] + offset, pointData[5])
            end

            C_Timer.After((i - 1) * delay, function()
                local ag = frame:CreateAnimationGroup()
                frame._staggerAG = ag

                local slide = ag:CreateAnimation("Translation")
                slide:SetOffset(-offset, 0)
                slide:SetDuration(0.3)
                slide:SetSmoothing("OUT")

                local fade = ag:CreateAnimation("Alpha")
                fade:SetFromAlpha(0)
                fade:SetToAlpha(1)
                fade:SetDuration(0.25)
                fade:SetSmoothing("OUT")

                ag:SetScript("OnFinished", function()
                    frame:ClearAllPoints()
                    for _, pointData in ipairs(originalPoints) do
                        frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
                    end
                    frame:SetAlpha(1)
                    frame._staggerAG = nil
                end)

                ag:Play()
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Scale Pop Animation (element pops in with bounce)
---------------------------------------------------------------------------
function AS:ScalePop(frame, fromScale, toScale, duration)
    fromScale = fromScale or 0.8
    toScale = toScale or 1.0
    duration = duration or 0.3

    -- Stop any existing scale pop animation
    if frame._scalePopAG then
        frame._scalePopAG:Stop()
    end

    local ag = frame:CreateAnimationGroup()
    frame._scalePopAG = ag

    local scale = ag:CreateAnimation("Scale")
    scale:SetScaleFrom(fromScale, fromScale)
    scale:SetScaleTo(toScale, toScale)
    scale:SetDuration(duration)
    scale:SetSmoothing("OUT")
    scale:SetOrigin("CENTER", 0, 0)

    local fade = ag:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(duration * 0.8)
    fade:SetSmoothing("OUT")

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(1)
        frame._scalePopAG = nil
    end)

    ag:Play()
end

---------------------------------------------------------------------------
-- Shake Animation (for errors or emphasis)
---------------------------------------------------------------------------
function AS:Shake(frame, intensity, duration)
    intensity = intensity or 5
    duration = duration or 0.3

    local originalPoints = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        table.insert(originalPoints, {point, relativeTo, relativePoint, x, y})
    end

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local damping = 1 - progress
            local t = progress * duration
            local offsetX = math_sin(t * 20 * math_pi) * intensity * damping
            local offsetY = math_cos(t * 20 * math_pi * 1.3) * intensity * 0.5 * damping

            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4] + offsetX, pointData[5] + offsetY)
            end
        end,
        function()
            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
            end
        end
    )
    return driver
end

---------------------------------------------------------------------------
-- Bounce Animation (elastic bounce effect)
---------------------------------------------------------------------------
function AS:Bounce(frame, height, duration)
    height = height or 20
    duration = duration or 0.6

    local originalPoints = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        table.insert(originalPoints, {point, relativeTo, relativePoint, x, y})
    end

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local damping = 1 - progress
            local offsetY = math_abs(math_sin(progress * math_pi * 3)) * height * damping

            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5] + offsetY)
            end
        end,
        function()
            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
            end
        end
    )
    return driver
end

---------------------------------------------------------------------------
-- Number Count-Up Animation (for stat displays) — legacy wrapper
---------------------------------------------------------------------------
function AS:CountUp(fontString, targetValue, duration, formatFunc)
    duration = duration or 1.0
    formatFunc = formatFunc or tostring

    local startValue = tonumber(fontString:GetText()) or 0

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local eased = easeOutCubic(progress)
            local currentValue = lerp(startValue, targetValue, eased)
            fontString:SetText(formatFunc(math_floor(currentValue)))
        end,
        function()
            fontString:SetText(formatFunc(targetValue))
        end
    )
    return driver
end

---------------------------------------------------------------------------
-- Color Transition Animation (smooth color changes)
---------------------------------------------------------------------------
function AS:ColorTransition(texture, fromColor, toColor, duration)
    duration = duration or 0.3

    local driver = CreateTimedDriver(duration,
        function(self, progress, elapsed)
            local r = lerp(fromColor[1], toColor[1], progress)
            local g = lerp(fromColor[2], toColor[2], progress)
            local b = lerp(fromColor[3], toColor[3], progress)
            local a = lerp(fromColor[4] or 1, toColor[4] or 1, progress)
            texture:SetVertexColor(r, g, b, a)
        end,
        function()
            texture:SetVertexColor(toColor[1], toColor[2], toColor[3], toColor[4] or 1)
        end
    )
    return driver
end

---------------------------------------------------------------------------
-- Pulsing Glow Effect (for attention-grabbing) — legacy version
---------------------------------------------------------------------------
function AS:PulseGlow(frame, color, duration, loops)
    color = color or {1, 1, 0}
    duration = duration or 1.5
    loops = loops or 3

    -- Clean up previous pulse glow on this frame
    if frame._pulseGlowTex then
        frame._pulseGlowTex:SetAlpha(0)
        frame._pulseGlowTex:Hide()
    end
    if frame._pulseGlowAG then
        frame._pulseGlowAG:Stop()
    end

    local glow = frame._pulseGlowTex
    if not glow then
        glow = frame:CreateTexture(nil, "OVERLAY")
        glow:SetTexture(SOLID)
        glow:SetBlendMode("ADD")
        frame._pulseGlowTex = glow
    end
    glow:SetAllPoints(frame)
    glow:SetVertexColor(color[1], color[2], color[3], 0)
    glow:Show()

    local ag = frame._pulseGlowAG
    if not ag then
        ag = glow:CreateAnimationGroup()
        frame._pulseGlowAG = ag
    end
    ag:Stop()
    ag:SetLooping("BOUNCE")

    -- Clear old animations and create new
    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(0.4)
    alpha:SetDuration(duration / 2)
    alpha:SetSmoothing("IN_OUT")

    ag:SetScript("OnFinished", function()
        glow:SetAlpha(0)
        glow:Hide()
    end)

    ag:Play()

    C_Timer.After(duration * loops, function()
        ag:Stop()
        glow:SetAlpha(0)
        glow:Hide()
    end)
end

---------------------------------------------------------------------------
-- Progress Bar Fill Animation — legacy wrapper
---------------------------------------------------------------------------
function AS:FillProgressBar(bar, fillTexture, targetPercent, duration)
    duration = duration or 0.5
    targetPercent = math_max(0, math_min(1, targetPercent))

    local barWidth = bar:GetWidth()
    local startWidth = fillTexture:GetWidth()
    local targetWidth = barWidth * targetPercent

    return self:AnimateBar(fillTexture, startWidth, targetWidth, duration)
end

---------------------------------------------------------------------------
-- Rotation Animation (spinning effect)
---------------------------------------------------------------------------
function AS:Spin(texture, duration, loops)
    duration = duration or 1.0
    loops = loops or 1

    -- Stop any existing spin animation
    if texture._spinAG then
        texture._spinAG:Stop()
    end

    local ag = texture:CreateAnimationGroup()
    texture._spinAG = ag

    if loops > 1 then
        ag:SetLooping("REPEAT")
    end

    local rotation = ag:CreateAnimation("Rotation")
    rotation:SetDegrees(360)
    rotation:SetDuration(duration)
    rotation:SetSmoothing("NONE")

    ag:Play()

    if loops > 1 then
        C_Timer.After(duration * loops, function()
            ag:Stop()
            texture._spinAG = nil
        end)
    else
        ag:SetScript("OnFinished", function()
            texture._spinAG = nil
        end)
    end
end

---------------------------------------------------------------------------
-- Flash Effect (quick attention grab)
---------------------------------------------------------------------------
function AS:Flash(frame, color, count)
    color = color or {1, 1, 1}
    count = count or 3

    local originalR, originalG, originalB, originalA
    if frame.SetBackdropColor then
        originalR, originalG, originalB, originalA = frame:GetBackdropColor()
    end

    local currentFlash = 0
    local flashInterval = 0.15

    local driver = AcquireDriver()
    driver.elapsed = 0

    driver:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= flashInterval then
            self.elapsed = 0
            currentFlash = currentFlash + 1

            if currentFlash > count * 2 then
                if frame.SetBackdropColor and originalR then
                    frame:SetBackdropColor(originalR, originalG, originalB, originalA)
                end
                ReleaseDriver(self)
                return
            end

            if currentFlash % 2 == 1 then
                if frame.SetBackdropColor then
                    frame:SetBackdropColor(color[1], color[2], color[3], 0.5)
                end
            else
                if frame.SetBackdropColor and originalR then
                    frame:SetBackdropColor(originalR, originalG, originalB, originalA)
                end
            end
        end
    end)

    return driver
end


-- ═══════════════════════════════════════════════════════════════════
-- PUBLIC UTILITY: Expose easing functions for external use
-- ═══════════════════════════════════════════════════════════════════
AS.Easing = {
    easeOut      = easeOut,
    easeInOut    = easeInOut,
    easeOutCubic = easeOutCubic,
    elasticOut   = elasticOut,
    lerp         = lerp,
    clamp01      = clamp01,
}
