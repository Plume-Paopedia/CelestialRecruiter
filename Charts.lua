local _, ns = ...
local W = ns.UIWidgets
local C = W.C

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Interactive Charts System
-- Beautiful data visualizations for statistics
-- ═══════════════════════════════════════════════════════════════════

ns.Charts = ns.Charts or {}
local Charts = ns.Charts

---------------------------------------------------------------------------
-- Line Chart (for trends over time)
---------------------------------------------------------------------------
function Charts:CreateLineChart(parent, width, height, data, options)
    options = options or {}
    local color = options.color or C.accent
    local showPoints = options.showPoints ~= false
    local showGrid = options.showGrid ~= false
    local animate = options.animate ~= false

    local chart = CreateFrame("Frame", nil, parent)
    chart:SetSize(width, height)

    -- Background
    local bg = chart:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(W.SOLID)
    bg:SetAllPoints()
    bg:SetVertexColor(C.panel[1], C.panel[2], C.panel[3], 0.5)

    -- Grid lines
    if showGrid then
        for i = 0, 4 do
            local line = chart:CreateTexture(nil, "ARTWORK")
            line:SetTexture(W.SOLID)
            line:SetHeight(1)
            line:SetPoint("LEFT", 0, 0)
            line:SetPoint("RIGHT", 0, 0)
            line:SetPoint("BOTTOM", 0, (height / 4) * i)
            line:SetVertexColor(C.border[1], C.border[2], C.border[3], 0.2)
        end
    end

    -- Find min/max values
    local minVal, maxVal = math.huge, -math.huge
    for _, point in ipairs(data) do
        minVal = math.min(minVal, point.value)
        maxVal = math.max(maxVal, point.value)
    end

    -- Add padding
    local range = maxVal - minVal
    if range == 0 then range = 1 end
    minVal = minVal - range * 0.1
    maxVal = maxVal + range * 0.1
    range = maxVal - minVal

    -- Draw line segments
    local segments = {}
    local dataSpan = math.max(1, #data - 1)
    for i = 1, #data - 1 do
        local x1 = (i - 1) / dataSpan * width
        local y1 = ((data[i].value - minVal) / range) * height
        local x2 = i / dataSpan * width
        local y2 = ((data[i + 1].value - minVal) / range) * height

        -- Calculate line angle and length
        local dx = x2 - x1
        local dy = y2 - y1
        local angle = math.atan2(dy, dx)
        local length = math.sqrt(dx * dx + dy * dy)

        local segment = chart:CreateTexture(nil, "ARTWORK")
        segment:SetTexture(W.SOLID)
        segment:SetSize(length, 2)
        segment:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", x1, y1)
        segment:SetRotation(angle)
        segment:SetVertexColor(color[1], color[2], color[3], 0.8)

        table.insert(segments, segment)
    end

    -- Draw points
    if showPoints then
        for i, point in ipairs(data) do
            local x = (i - 1) / dataSpan * width
            local y = ((point.value - minVal) / range) * height

            local dot = CreateFrame("Frame", nil, chart)
            dot:SetSize(8, 8)
            dot:SetPoint("CENTER", chart, "BOTTOMLEFT", x, y)

            local dotTex = dot:CreateTexture(nil, "OVERLAY")
            dotTex:SetTexture(W.SOLID)
            dotTex:SetAllPoints()
            dotTex:SetVertexColor(color[1], color[2], color[3], 1)

            -- Tooltip on hover
            dot:EnableMouse(true)
            dot:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(point.label or ("Donnee " .. i))
                GameTooltip:AddLine(tostring(point.value), 1, 1, 1)
                GameTooltip:Show()

                -- Highlight effect
                dotTex:SetSize(12, 12)
                dotTex:SetVertexColor(color[1] * 1.3, color[2] * 1.3, color[3] * 1.3, 1)
            end)
            dot:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                dotTex:SetSize(8, 8)
                dotTex:SetVertexColor(color[1], color[2], color[3], 1)
            end)

            -- Animation: scale up
            if animate then
                C_Timer.After(i * 0.05, function()
                    if ns.AnimationSystem then
                        ns.AnimationSystem:ScalePop(dot, 0, 1, 0.3)
                    end
                end)
            end
        end
    end

    return chart
end

---------------------------------------------------------------------------
-- Bar Chart (vertical bars)
---------------------------------------------------------------------------
function Charts:CreateBarChart(parent, width, height, data, options)
    options = options or {}
    local animate = options.animate ~= false

    local chart = CreateFrame("Frame", nil, parent)
    chart:SetSize(width, height)

    -- Background
    local bg = chart:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(W.SOLID)
    bg:SetAllPoints()
    bg:SetVertexColor(C.panel[1], C.panel[2], C.panel[3], 0.5)

    -- Find max value
    local maxVal = 0
    for _, bar in ipairs(data) do
        maxVal = math.max(maxVal, bar.value)
    end
    if maxVal == 0 then maxVal = 1 end

    -- Draw bars
    local barWidth = (width / #data) * 0.7
    local spacing = (width / #data) * 0.3

    for i, bar in ipairs(data) do
        local barHeight = (bar.value / maxVal) * height
        local x = (i - 1) * (width / #data) + spacing / 2

        local barFrame = CreateFrame("Frame", nil, chart)
        barFrame:SetSize(barWidth, 0)  -- Start at height 0 for animation
        barFrame:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", x, 0)

        local barTex = barFrame:CreateTexture(nil, "ARTWORK")
        barTex:SetTexture(W.SOLID)
        barTex:SetAllPoints()
        barTex:SetGradient("VERTICAL",
            CreateColor(bar.color[1], bar.color[2], bar.color[3], 1),
            CreateColor(bar.color[1] * 0.7, bar.color[2] * 0.7, bar.color[3] * 0.7, 1)
        )

        -- Label
        local label = chart:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOM", barFrame, "TOP", 0, 2)
        label:SetText(tostring(bar.value))
        label:SetTextColor(C.text[1], C.text[2], C.text[3])
        label:SetAlpha(0)

        -- X-axis label
        if bar.label then
            local xLabel = chart:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            xLabel:SetPoint("TOP", barFrame, "BOTTOM", 0, -2)
            xLabel:SetText(bar.label)
            xLabel:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        end

        -- Hover effect
        barFrame:EnableMouse(true)
        barFrame:SetScript("OnEnter", function(self)
            barTex:SetGradient("VERTICAL",
                CreateColor(bar.color[1] * 1.2, bar.color[2] * 1.2, bar.color[3] * 1.2, 1),
                CreateColor(bar.color[1] * 0.9, bar.color[2] * 0.9, bar.color[3] * 0.9, 1)
            )

            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(bar.label or ("Barre " .. i))
            GameTooltip:AddLine(tostring(bar.value), 1, 1, 1)
            if bar.tooltip then
                GameTooltip:AddLine(bar.tooltip, C.dim[1], C.dim[2], C.dim[3], true)
            end
            GameTooltip:Show()
        end)
        barFrame:SetScript("OnLeave", function(self)
            barTex:SetGradient("VERTICAL",
                CreateColor(bar.color[1], bar.color[2], bar.color[3], 1),
                CreateColor(bar.color[1] * 0.7, bar.color[2] * 0.7, bar.color[3] * 0.7, 1)
            )
            GameTooltip:Hide()
        end)

        -- Animate bar growth
        if animate then
            C_Timer.After(i * 0.05, function()
                local startTime = GetTime()
                local duration = 0.5
                local animFrame = CreateFrame("Frame")
                animFrame:SetScript("OnUpdate", function(self)
                    local elapsed = GetTime() - startTime
                    if elapsed >= duration then
                        barFrame:SetHeight(barHeight)
                        label:SetAlpha(1)
                        self:SetScript("OnUpdate", nil)
                        return
                    end

                    -- Ease-out
                    local progress = elapsed / duration
                    local eased = 1 - math.pow(1 - progress, 3)
                    barFrame:SetHeight(barHeight * eased)
                    label:SetAlpha(eased)
                end)
            end)
        else
            barFrame:SetHeight(barHeight)
            label:SetAlpha(1)
        end
    end

    return chart
end

---------------------------------------------------------------------------
-- Pie Chart (donut style)
---------------------------------------------------------------------------
function Charts:CreatePieChart(parent, size, data, options)
    options = options or {}
    local innerRadius = options.innerRadius or 0.5
    local animate = options.animate ~= false

    local chart = CreateFrame("Frame", nil, parent)
    chart:SetSize(size, size)

    -- Calculate total
    local total = 0
    for _, slice in ipairs(data) do
        total = total + slice.value
    end
    if total == 0 then total = 1 end

    -- Draw slices
    local startAngle = -math.pi / 2  -- Start at top
    local center = size / 2

    for i, slice in ipairs(data) do
        local angle = (slice.value / total) * 2 * math.pi
        local endAngle = startAngle + angle

        -- Create slice frame
        local sliceFrame = CreateFrame("Frame", nil, chart)
        sliceFrame:SetSize(size, size)
        sliceFrame:SetPoint("CENTER")

        -- Draw slice using multiple lines (approximation)
        local segments = math.max(2, math.floor(angle / (math.pi / 12)))
        for j = 0, segments do
            local theta = startAngle + (angle * j / segments)
            local nextTheta = startAngle + (angle * (j + 1) / segments)

            -- Outer points
            local x1 = center + math.cos(theta) * (size / 2)
            local y1 = center + math.sin(theta) * (size / 2)
            local x2 = center + math.cos(nextTheta) * (size / 2)
            local y2 = center + math.sin(nextTheta) * (size / 2)

            -- Inner points
            local x3 = center + math.cos(theta) * (size / 2 * innerRadius)
            local y3 = center + math.sin(theta) * (size / 2 * innerRadius)
            local x4 = center + math.cos(nextTheta) * (size / 2 * innerRadius)
            local y4 = center + math.sin(nextTheta) * (size / 2 * innerRadius)

            -- Draw quad approximation (2 triangles)
            local tri1 = sliceFrame:CreateTexture(nil, "ARTWORK")
            tri1:SetTexture(W.SOLID)
            tri1:SetVertexColor(slice.color[1], slice.color[2], slice.color[3], 0.9)
            -- Position triangles (simplified - WoW textures can't do arbitrary triangles easily)
            -- So we'll use a circle mask approach instead
        end

        -- Simplified: Use a colored frame
        local arcTex = sliceFrame:CreateTexture(nil, "ARTWORK")
        arcTex:SetTexture(W.SOLID)
        arcTex:SetVertexColor(slice.color[1], slice.color[2], slice.color[3], 0.8)
        arcTex:SetSize(size / 2, size / 2)

        -- Position at angle midpoint
        local midAngle = (startAngle + endAngle) / 2
        local radius = size / 2 * (1 + innerRadius) / 2
        arcTex:SetPoint("CENTER", chart, "CENTER",
            math.cos(midAngle) * radius * 0.4,
            math.sin(midAngle) * radius * 0.4
        )

        -- Hover
        sliceFrame:EnableMouse(true)
        sliceFrame:SetScript("OnEnter", function(self)
            arcTex:SetVertexColor(slice.color[1] * 1.3, slice.color[2] * 1.3, slice.color[3] * 1.3, 1)

            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(slice.label)
            GameTooltip:AddLine(string.format("%d (%.1f%%)", slice.value, (slice.value / total) * 100), 1, 1, 1)
            GameTooltip:Show()
        end)
        sliceFrame:SetScript("OnLeave", function(self)
            arcTex:SetVertexColor(slice.color[1], slice.color[2], slice.color[3], 0.8)
            GameTooltip:Hide()
        end)

        -- Animation
        if animate then
            arcTex:SetAlpha(0)
            C_Timer.After(i * 0.1, function()
                local ag = arcTex:CreateAnimationGroup()
                local fade = ag:CreateAnimation("Alpha")
                fade:SetFromAlpha(0)
                fade:SetToAlpha(0.8)
                fade:SetDuration(0.3)
                ag:Play()
            end)
        end

        startAngle = endAngle
    end

    -- Center label (total)
    local centerLabel = chart:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    centerLabel:SetPoint("CENTER")
    centerLabel:SetText(tostring(total))
    centerLabel:SetTextColor(C.text[1], C.text[2], C.text[3])

    return chart
end

---------------------------------------------------------------------------
-- Heatmap (for hourly activity)
---------------------------------------------------------------------------
function Charts:CreateHeatmap(parent, width, height, data, options)
    options = options or {}
    local cols = options.cols or 24  -- 24 hours
    local rows = options.rows or 7   -- 7 days
    local colorLow = options.colorLow or C.panel
    local colorHigh = options.colorHigh or C.green

    local chart = CreateFrame("Frame", nil, parent)
    chart:SetSize(width, height)

    local cellWidth = width / cols
    local cellHeight = height / rows

    -- Find max value for normalization
    local maxVal = 0
    for _, val in pairs(data) do
        maxVal = math.max(maxVal, val)
    end
    if maxVal == 0 then maxVal = 1 end

    -- Draw cells
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local index = row * cols + col
            local value = data[index] or 0
            local intensity = value / maxVal

            local cell = CreateFrame("Frame", nil, chart)
            cell:SetSize(cellWidth - 1, cellHeight - 1)
            cell:SetPoint("BOTTOMLEFT", chart, "BOTTOMLEFT", col * cellWidth, row * cellHeight)

            local cellTex = cell:CreateTexture(nil, "ARTWORK")
            cellTex:SetTexture(W.SOLID)
            cellTex:SetAllPoints()

            -- Interpolate color
            local r = colorLow[1] + (colorHigh[1] - colorLow[1]) * intensity
            local g = colorLow[2] + (colorHigh[2] - colorLow[2]) * intensity
            local b = colorLow[3] + (colorHigh[3] - colorLow[3]) * intensity
            cellTex:SetVertexColor(r, g, b, 0.9)

            -- Hover
            cell:EnableMouse(true)
            cell:SetScript("OnEnter", function(self)
                cellTex:SetVertexColor(r * 1.2, g * 1.2, b * 1.2, 1)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(string.format("Ligne %d, Col %d", row, col))
                GameTooltip:AddLine(string.format("Valeur : %d", value), 1, 1, 1)
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function(self)
                cellTex:SetVertexColor(r, g, b, 0.9)
                GameTooltip:Hide()
            end)
        end
    end

    return chart
end
