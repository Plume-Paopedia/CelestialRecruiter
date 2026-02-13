local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  A/B Testing System
-- Automatically test templates against each other to find the best
-- ═══════════════════════════════════════════════════════════════════

ns.ABTesting = ns.ABTesting or {}
local AB = ns.ABTesting

---------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------
function AB:Init()
    if not ns.db.global.abTests then
        ns.db.global.abTests = {}
    end
    if not ns.db.global.abActiveTest then
        ns.db.global.abActiveTest = nil
    end
end

---------------------------------------------------------------------------
-- Test Structure
-- test = {
--   id, name, status (active/paused/completed),
--   variants = { {templateId, sent, replies, joined, weight} },
--   createdAt, startedAt, completedAt,
--   minSamples, confidenceThreshold,
--   winner
-- }
---------------------------------------------------------------------------

function AB:CreateTest(name, templateIds, minSamples)
    self:Init()

    local id = "test_" .. time() .. "_" .. math.random(1000, 9999)
    minSamples = minSamples or 30

    local variants = {}
    for _, tplId in ipairs(templateIds) do
        table.insert(variants, {
            templateId = tplId,
            sent = 0,
            replies = 0,
            joined = 0,
            weight = 1,  -- Equal weight initially
        })
    end

    local test = {
        id = id,
        name = name or ("Test " .. date("%d/%m %H:%M")),
        status = "paused",
        variants = variants,
        createdAt = time(),
        startedAt = 0,
        completedAt = 0,
        minSamples = minSamples,
        confidenceThreshold = 0.95,
        winner = nil,
    }

    ns.db.global.abTests[id] = test
    return test
end

function AB:DeleteTest(testId)
    if not ns.db.global.abTests then return end
    -- If this was active, deactivate
    if ns.db.global.abActiveTest == testId then
        ns.db.global.abActiveTest = nil
    end
    ns.db.global.abTests[testId] = nil
end

function AB:StartTest(testId)
    self:Init()
    local test = ns.db.global.abTests[testId]
    if not test then return false end

    -- Stop any currently active test
    if ns.db.global.abActiveTest and ns.db.global.abActiveTest ~= testId then
        self:PauseTest(ns.db.global.abActiveTest)
    end

    test.status = "active"
    test.startedAt = time()
    ns.db.global.abActiveTest = testId

    ns.DB_Log("AB", "Test A/B demarre: " .. test.name)
    if ns.Notifications_Success then
        ns.Notifications_Success("A/B Test", "Demarre: " .. test.name)
    end
    return true
end

function AB:PauseTest(testId)
    self:Init()
    local test = ns.db.global.abTests[testId]
    if not test then return end

    test.status = "paused"
    if ns.db.global.abActiveTest == testId then
        ns.db.global.abActiveTest = nil
    end
end

function AB:CompleteTest(testId)
    self:Init()
    local test = ns.db.global.abTests[testId]
    if not test then return end

    test.status = "completed"
    test.completedAt = time()
    if ns.db.global.abActiveTest == testId then
        ns.db.global.abActiveTest = nil
    end

    -- Determine winner
    local winner = self:GetWinner(testId)
    if winner then
        test.winner = winner.templateId
        ns.DB_Log("AB", ("Test termine: %s - Gagnant: %s (%.1f%% conv.)"):format(
            test.name, winner.templateId, winner.conversionRate * 100))
        if ns.Notifications_Success then
            ns.Notifications_Success("A/B Test termine",
                ("Gagnant: %s (%.1f%%)"):format(winner.templateId, winner.conversionRate * 100))
        end
    end
end

---------------------------------------------------------------------------
-- Template Selection (called during whisper)
---------------------------------------------------------------------------
function AB:PickTemplate(defaultTemplateId)
    self:Init()

    local activeId = ns.db.global.abActiveTest
    if not activeId then return defaultTemplateId end

    local test = ns.db.global.abTests[activeId]
    if not test or test.status ~= "active" or #test.variants == 0 then
        return defaultTemplateId
    end

    -- Thompson Sampling inspired: use weighted random based on performance
    -- Early on, use equal distribution. As data grows, favor better performers.
    local totalWeight = 0
    for _, v in ipairs(test.variants) do
        -- Weight = base + bonus from success rate
        local rate = v.sent > 0 and ((v.replies + v.joined * 2) / v.sent) or 0.5
        v.weight = 1 + rate * v.sent * 0.1  -- More data = more influence
        totalWeight = totalWeight + v.weight
    end

    -- Weighted random selection
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, v in ipairs(test.variants) do
        cumulative = cumulative + v.weight
        if roll <= cumulative then
            return v.templateId
        end
    end

    -- Fallback
    return test.variants[1].templateId
end

---------------------------------------------------------------------------
-- Record Events
---------------------------------------------------------------------------
function AB:RecordSent(templateId)
    self:Init()
    local activeId = ns.db.global.abActiveTest
    if not activeId then return end

    local test = ns.db.global.abTests[activeId]
    if not test or test.status ~= "active" then return end

    for _, v in ipairs(test.variants) do
        if v.templateId == templateId then
            v.sent = v.sent + 1
            break
        end
    end

    -- Check if we should auto-complete
    self:CheckAutoComplete(activeId)
end

function AB:RecordReply(templateId)
    self:Init()
    local activeId = ns.db.global.abActiveTest
    if not activeId then return end

    local test = ns.db.global.abTests[activeId]
    if not test or test.status ~= "active" then return end

    for _, v in ipairs(test.variants) do
        if v.templateId == templateId then
            v.replies = v.replies + 1
            break
        end
    end
end

function AB:RecordJoined(templateId)
    self:Init()
    -- Check ALL active/paused tests (joined can happen after test ends)
    for testId, test in pairs(ns.db.global.abTests or {}) do
        for _, v in ipairs(test.variants) do
            if v.templateId == templateId then
                v.joined = v.joined + 1
            end
        end
    end
end

---------------------------------------------------------------------------
-- Auto-Complete Check
---------------------------------------------------------------------------
function AB:CheckAutoComplete(testId)
    local test = ns.db.global.abTests[testId]
    if not test or test.status ~= "active" then return end

    -- Check if all variants have enough samples
    local allReady = true
    for _, v in ipairs(test.variants) do
        if v.sent < test.minSamples then
            allReady = false
            break
        end
    end

    if allReady then
        -- Check if there's a clear winner
        local winner = self:GetWinner(testId)
        if winner and winner.confidence >= test.confidenceThreshold then
            self:CompleteTest(testId)
        end
    end
end

---------------------------------------------------------------------------
-- Analysis
---------------------------------------------------------------------------
function AB:GetWinner(testId)
    self:Init()
    local test = ns.db.global.abTests[testId]
    if not test or #test.variants < 2 then return nil end

    local best = nil
    local bestRate = -1

    for _, v in ipairs(test.variants) do
        local rate = v.sent > 0 and ((v.replies + v.joined * 3) / v.sent) or 0
        if rate > bestRate then
            bestRate = rate
            best = v
        end
    end

    if not best or best.sent == 0 then return nil end

    -- Simple confidence estimation based on sample size difference
    local secondBest = nil
    local secondRate = -1
    for _, v in ipairs(test.variants) do
        if v ~= best then
            local rate = v.sent > 0 and ((v.replies + v.joined * 3) / v.sent) or 0
            if rate > secondRate then
                secondRate = rate
                secondBest = v
            end
        end
    end

    -- Confidence: higher when more samples and bigger difference
    local confidence = 0.5
    if best.sent >= test.minSamples and secondBest and secondBest.sent >= test.minSamples then
        local diff = bestRate - secondRate
        local avgSamples = (best.sent + secondBest.sent) / 2
        confidence = math.min(0.99, 0.5 + diff * math.sqrt(avgSamples) * 0.5)
    end

    return {
        templateId = best.templateId,
        sent = best.sent,
        replies = best.replies,
        joined = best.joined,
        conversionRate = bestRate,
        confidence = confidence,
    }
end

function AB:GetTestResults(testId)
    self:Init()
    local test = ns.db.global.abTests[testId]
    if not test then return {} end

    local results = {}
    for _, v in ipairs(test.variants) do
        local replyRate = v.sent > 0 and (v.replies / v.sent) or 0
        local joinRate = v.sent > 0 and (v.joined / v.sent) or 0
        local score = v.sent > 0 and ((v.replies + v.joined * 3) / v.sent) or 0

        table.insert(results, {
            templateId = v.templateId,
            sent = v.sent,
            replies = v.replies,
            joined = v.joined,
            replyRate = replyRate,
            joinRate = joinRate,
            score = score,
            isWinner = test.winner == v.templateId,
        })
    end

    -- Sort by score descending
    table.sort(results, function(a, b) return a.score > b.score end)
    return results
end

---------------------------------------------------------------------------
-- List Tests
---------------------------------------------------------------------------
function AB:GetAllTests()
    self:Init()
    local tests = {}
    for id, test in pairs(ns.db.global.abTests or {}) do
        table.insert(tests, test)
    end
    -- Sort by creation date, newest first
    table.sort(tests, function(a, b) return a.createdAt > b.createdAt end)
    return tests
end

function AB:GetActiveTest()
    self:Init()
    local activeId = ns.db.global.abActiveTest
    if not activeId then return nil end
    return ns.db.global.abTests[activeId]
end

function AB:GetActiveTestId()
    self:Init()
    return ns.db.global.abActiveTest
end
