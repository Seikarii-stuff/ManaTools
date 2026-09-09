-- ManaTools benchmark suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/perf/benchmark.lua [iterations]
-- Always overwrites: test/results/benchmark.txt
-- AGENT NOTE: This benchmark MUST stay under 2.0s total wall-clock time. Do not increase the default iteration count or add more expensive work; reduce iterations or optimize the hot path instead.

local MAX_BENCHMARK_SECONDS = 2.0
local requestedIterations = tonumber(arg[1]) or 10000
local iterations = math.min(requestedIterations, 10000)
local warmup = math.max(500, math.floor(iterations / 10))

if requestedIterations and requestedIterations > iterations then
    print(string.format("Benchmark cap enforced: reducing iterations from %d to %d to keep the suite under %.1fs.", requestedIterations, iterations, MAX_BENCHMARK_SECONDS))
end

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load
local unpackValues = table.unpack or unpack

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

ManaToolsDB = {}
local addonNamespace = {}
loadFile("Bootstrap.lua", "ManaTools", addonNamespace)
ManaTools = addonNamespace
loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", ManaTools)
loadFile("CinematicSkip/cinematicskip.lua", "ManaTools", ManaTools)
loadFile("ChatCopy/ChatCopy.lua", "ManaTools", ManaTools)

local noWasteDB = ManaTools.DB.NoWasteCoin
local NoWasteCoin = ManaTools.NoWasteCoin
local CinematicSkip = ManaTools.CinematicSkip
local cinematicSkipDB = ManaTools.DB.CinematicSkip
local ChatCopy = ManaTools.ChatCopy
local chatCopyDB = ManaTools.DB.ChatCopy

local function runTimed(fn, count)
    local start = os.clock()
    fn(count)
    return os.clock() - start
end

local function appendMetric(results, name, elapsed, count)
    local rate = elapsed > 0 and count / elapsed or math.huge
    results[#results + 1] = string.format("%-38s %10.6f s  %12.0f calls/s  %12.3f us/call", name, elapsed, rate, elapsed * 1000000 / count)
end

local results = {
    "ManaTools benchmark results",
    "===========================",
    "Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC"),
    string.format("Iterations per hot path: %d", iterations),
    string.format("Warmup per hot path: %d", warmup),
    "",
}

-- NoWasteCoin simplified: benchmark a lightweight Update() path.
for _ = 1, warmup do NoWasteCoin.Update() end
local elapsed = runTimed(function(count)
    for _ = 1, count do NoWasteCoin.Update() end
end, iterations)
appendMetric(results, "NoWasteCoin Update", elapsed, iterations)


-- ManaInvite benchmarks removed (deprecated)

results[#results + 1] = ""
results[#results + 1] = "CinematicSkip benchmarks"
results[#results + 1] = "------------------------"

local function benchmarkCinematicStart()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    local calls = 0
    CinematicFrame_CancelCinematic = function() calls = calls + 1 end
    for _ = 1, warmup do mock.fireEvent("CINEMATIC_START") end
    calls = 0
    local elapsed = runTimed(function(count)
        for _ = 1, count do mock.fireEvent("CINEMATIC_START") end
    end, iterations)
    CinematicFrame_CancelCinematic = nil
    return elapsed
end

local function benchmarkPlayMovie()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    MovieFrame = CreateFrame("Frame")
    for _ = 1, warmup do MovieFrame:Show(); mock.fireEvent("PLAY_MOVIE") end
    local elapsed = runTimed(function(count)
        for _ = 1, count do MovieFrame:Show(); mock.fireEvent("PLAY_MOVIE") end
    end, iterations)
    MovieFrame = nil
    return elapsed
end

local function benchmarkTalkingHead()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    TalkingHeadFrame = CreateFrame("Frame")
    for _ = 1, warmup do TalkingHeadFrame:Show(); mock.fireEvent("TALKINGHEAD_REQUESTED") end
    local elapsed = runTimed(function(count)
        for _ = 1, count do TalkingHeadFrame:Show(); mock.fireEvent("TALKINGHEAD_REQUESTED") end
    end, iterations)
    TalkingHeadFrame = nil
    return elapsed
end

appendMetric(results, "CINEMATIC_START", benchmarkCinematicStart(), iterations)
appendMetric(results, "PLAY_MOVIE", benchmarkPlayMovie(), iterations)
appendMetric(results, "TALKINGHEAD_REQUESTED", benchmarkTalkingHead(), iterations)

results[#results + 1] = ""
results[#results + 1] = "ChatCopy benchmarks"
results[#results + 1] = "-------------------"

local function benchmarkChatCopyBuildText()
    local total = 200
    local messages = {}
    for i = 1, total do
        messages[i] = "chat line " .. i .. " lorem ipsum dolor sit amet consectetur adipiscing elit"
    end

    local chatFrame = CreateFrame("Frame", "ChatFrame1")
    function chatFrame:GetNumMessages() return total end
    function chatFrame:GetMessageInfo(index)
        return messages[index]
    end
    _G.ChatFrame1 = chatFrame
    _G.DEFAULT_CHAT_FRAME = chatFrame

    chatCopyDB.enabled = true
    ChatCopy:Update()
    for _ = 1, warmup do ChatCopy:BuildTextFromGeneral() end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            ChatCopy:BuildTextFromGeneral()
        end
    end, iterations)

    return elapsed
end

local function benchmarkChatCopyOpenPopup()
    local total = 200
    local messages = {}
    for i = 1, total do
        messages[i] = "copy line " .. i .. " vel pretium nisl suspendisse at ultrices urna"
    end

    local chatFrame = CreateFrame("Frame", "ChatFrame1")
    function chatFrame:GetNumMessages() return total end
    function chatFrame:GetMessageInfo(index)
        return messages[index]
    end
    _G.ChatFrame1 = chatFrame
    _G.DEFAULT_CHAT_FRAME = chatFrame

    chatCopyDB.enabled = true
    ChatCopy:Update()
    for _ = 1, warmup do
        ChatCopy:OpenPopup()
        if ChatCopy.popup and ChatCopy.popup.Hide then
            ChatCopy.popup:Hide()
        end
    end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            ChatCopy:OpenPopup()
            if ChatCopy.popup and ChatCopy.popup.Hide then
                ChatCopy.popup:Hide()
            end
        end
    end, iterations)

    return elapsed
end

appendMetric(results, "ChatCopy BUILD_TEXT_FROM_GENERAL", benchmarkChatCopyBuildText(), iterations)
appendMetric(results, "ChatCopy OPEN_POPUP", benchmarkChatCopyOpenPopup(), iterations)

results[#results + 1] = ""
results[#results + 1] = "NoInfo benchmarks"
results[#results + 1] = "----------------"

-- Give NoInfo a real original OnShow handler so its disabled path is measurable.
GameTooltip = CreateFrame("GameTooltip")
local originalTooltipOnShowCalls = 0
local originalTooltipOnShow = function() originalTooltipOnShowCalls = originalTooltipOnShowCalls + 1 end
GameTooltip:SetScript("OnShow", originalTooltipOnShow)
function GameTooltip:GetTooltipData() return self.tooltipData end
function GameTooltip:GetOwner() return self.tooltipOwner end
Minimap = CreateFrame("Frame")
MainMenuMicroButton = CreateFrame("Button")
UIParent = CreateFrame("Frame")
Enum = { TooltipDataType = { Item = 0 } }

loadFile("NoInfo/NoInfo.lua", "ManaTools", ManaTools)
local noInfoDB = ManaTools.DB.NoInfo
local NoInfo = ManaTools.NoInfo

local itemData = { type = Enum.TooltipDataType.Item }
local genericData = { type = 999 }

local function benchmarkNoInfoState(name, enabled, inspectMode, data, owner)
    noInfoDB.enabled = enabled
    noInfoDB.inspectMode = inspectMode
    GameTooltip.tooltipData = data
    GameTooltip.tooltipOwner = owner
    NoInfo.Update()
    local handler = GameTooltip:GetScript("OnShow")
    assert(handler, "NoInfo benchmark requires an OnShow handler: " .. name)
    for _ = 1, warmup do handler(GameTooltip) end
    local elapsed = runTimed(function(count)
        for _ = 1, count do handler(GameTooltip) end
    end, iterations)
    appendMetric(results, name, elapsed, iterations)
end

benchmarkNoInfoState("NoInfo OFF", true, 0, genericData, nil)
benchmarkNoInfoState("NoInfo normal inspection", true, 1, genericData, nil)
benchmarkNoInfoState("NoInfo inspection + rating", true, 2, genericData, nil)

noInfoDB.enabled = false
noInfoDB.inspectMode = 0
NoInfo.Update()
local disabledHandler = GameTooltip:GetScript("OnShow")
assert(disabledHandler == originalTooltipOnShow, "NoInfo disabled path must restore the original OnShow")
for _ = 1, warmup do disabledHandler(GameTooltip) end
appendMetric(results, "NoInfo disabled: original OnShow", runTimed(function(count)
    for _ = 1, count do disabledHandler(GameTooltip) end
end, iterations), iterations)

results[#results + 1] = ""
results[#results + 1] = "Allocations: NOT AVAILABLE (Lua benchmark environment does not expose a reliable per-call allocation metric)."
results[#results + 1] = "Generated by test/perf/benchmark.lua"

local output = assert(io.open("test/results/benchmark.txt", "w"))
output:write(table.concat(results, "\n"), "\n")
output:close()

print(table.concat(results, "\n"))
print("Benchmark results written to test/results/benchmark.txt")
