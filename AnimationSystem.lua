local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Advanced Animation System
-- Smooth list animations, transitions, and micro-interactions
-- ═══════════════════════════════════════════════════════════════════

ns.AnimationSystem = ns.AnimationSystem or {}
local AS = ns.AnimationSystem

---------------------------------------------------------------------------
-- Staggered List Animation (items fade/slide in one by one)
---------------------------------------------------------------------------
function AS:StaggeredFadeIn(frames, delay, offset)
    delay = delay or 0.03  -- delay between each frame
    offset = offset or 20   -- slide offset in pixels

    for i, frame in ipairs(frames) do
        if frame and frame:IsShown() then
            -- Initial state: invisible and offset
            frame:SetAlpha(0)
            local originalPoints = {}
            for j = 1, frame:GetNumPoints() do
                local point, relativeTo, relativePoint, x, y = frame:GetPoint(j)
                table.insert(originalPoints, {point, relativeTo, relativePoint, x, y})
            end

            -- Offset to the right
            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4] + offset, pointData[5])
            end

            -- Animate after delay
            C_Timer.After((i - 1) * delay, function()
                -- Slide animation
                local ag = frame:CreateAnimationGroup()

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
                    -- Restore original points
                    frame:ClearAllPoints()
                    for _, pointData in ipairs(originalPoints) do
                        frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
                    end
                    frame:SetAlpha(1)
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

    local ag = frame:CreateAnimationGroup()

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

    local startTime = GetTime()
    local shakeFrame = CreateFrame("Frame")
    shakeFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            -- Restore original position
            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
            end
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Oscillating shake
        local progress = elapsed / duration
        local damping = 1 - progress  -- reduces over time
        local frequency = 20
        local offsetX = math.sin(elapsed * frequency * math.pi) * intensity * damping
        local offsetY = math.cos(elapsed * frequency * math.pi * 1.3) * intensity * 0.5 * damping

        frame:ClearAllPoints()
        for _, pointData in ipairs(originalPoints) do
            frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4] + offsetX, pointData[5] + offsetY)
        end
    end)
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

    local startTime = GetTime()
    local bounceFrame = CreateFrame("Frame")
    bounceFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            -- Restore original position
            frame:ClearAllPoints()
            for _, pointData in ipairs(originalPoints) do
                frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
            end
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Bouncing motion (sine wave with damping)
        local progress = elapsed / duration
        local damping = 1 - progress
        local offsetY = math.abs(math.sin(progress * math.pi * 3)) * height * damping

        frame:ClearAllPoints()
        for _, pointData in ipairs(originalPoints) do
            frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5] + offsetY)
        end
    end)
end

---------------------------------------------------------------------------
-- Number Count-Up Animation (for stat displays)
---------------------------------------------------------------------------
function AS:CountUp(fontString, targetValue, duration, formatFunc)
    duration = duration or 1.0
    formatFunc = formatFunc or tostring

    local startValue = tonumber(fontString:GetText()) or 0
    local startTime = GetTime()

    local countFrame = CreateFrame("Frame")
    countFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            fontString:SetText(formatFunc(targetValue))
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Easing function (ease-out)
        local progress = elapsed / duration
        local eased = 1 - math.pow(1 - progress, 3)
        local currentValue = startValue + (targetValue - startValue) * eased

        fontString:SetText(formatFunc(math.floor(currentValue)))
    end)
end

---------------------------------------------------------------------------
-- Color Transition Animation (smooth color changes)
---------------------------------------------------------------------------
function AS:ColorTransition(texture, fromColor, toColor, duration)
    duration = duration or 0.3

    local startTime = GetTime()
    local colorFrame = CreateFrame("Frame")

    colorFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            texture:SetVertexColor(toColor[1], toColor[2], toColor[3], toColor[4] or 1)
            self:SetScript("OnUpdate", nil)
            return
        end

        local progress = elapsed / duration
        local r = fromColor[1] + (toColor[1] - fromColor[1]) * progress
        local g = fromColor[2] + (toColor[2] - fromColor[2]) * progress
        local b = fromColor[3] + (toColor[3] - fromColor[3]) * progress
        local a = (fromColor[4] or 1) + ((toColor[4] or 1) - (fromColor[4] or 1)) * progress

        texture:SetVertexColor(r, g, b, a)
    end)
end

---------------------------------------------------------------------------
-- Pulsing Glow Effect (for attention-grabbing)
---------------------------------------------------------------------------
function AS:PulseGlow(frame, color, duration, loops)
    color = color or {1, 1, 0}  -- Gold by default
    duration = duration or 1.5
    loops = loops or 3

    local glow = frame:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\WHITE8x8")
    glow:SetBlendMode("ADD")
    glow:SetAllPoints(frame)
    glow:SetVertexColor(color[1], color[2], color[3], 0)

    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")

    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(0.4)
    alpha:SetDuration(duration / 2)
    alpha:SetSmoothing("IN_OUT")

    ag:Play()

    -- Stop after N loops
    C_Timer.After(duration * loops, function()
        ag:Stop()
        glow:Hide()
    end)
end

---------------------------------------------------------------------------
-- Progress Bar Fill Animation
---------------------------------------------------------------------------
function AS:FillProgressBar(bar, fillTexture, targetPercent, duration)
    duration = duration or 0.5
    targetPercent = math.max(0, math.min(1, targetPercent))

    local startPercent = fillTexture:GetWidth() / bar:GetWidth()
    local startTime = GetTime()

    local fillFrame = CreateFrame("Frame")
    fillFrame:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            fillTexture:SetWidth(bar:GetWidth() * targetPercent)
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Ease-out
        local progress = elapsed / duration
        local eased = 1 - math.pow(1 - progress, 2)
        local currentPercent = startPercent + (targetPercent - startPercent) * eased

        fillTexture:SetWidth(bar:GetWidth() * currentPercent)
    end)
end

---------------------------------------------------------------------------
-- Rotation Animation (spinning effect)
---------------------------------------------------------------------------
function AS:Spin(texture, duration, loops)
    duration = duration or 1.0
    loops = loops or 1

    local ag = texture:CreateAnimationGroup()
    if loops > 1 then
        ag:SetLooping("REPEAT")
    end

    local rotation = ag:CreateAnimation("Rotation")
    rotation:SetDegrees(360)
    rotation:SetDuration(duration)
    rotation:SetSmoothing("NONE")  -- Linear rotation

    ag:Play()

    if loops > 1 then
        C_Timer.After(duration * loops, function()
            ag:Stop()
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

    local flashFrame = CreateFrame("Frame")
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= flashInterval then
            self.elapsed = 0
            currentFlash = currentFlash + 1

            if currentFlash > count * 2 then
                -- Restore original color
                if frame.SetBackdropColor and originalR then
                    frame:SetBackdropColor(originalR, originalG, originalB, originalA)
                end
                self:SetScript("OnUpdate", nil)
                return
            end

            -- Toggle between flash color and original
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
end
