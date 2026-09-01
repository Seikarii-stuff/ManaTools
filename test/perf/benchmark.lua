-- ManaTools benchmark suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/perf/benchmark.lua [iterations]
-- Always overwrites: test/results/benchmark.txt

local iterations = tonumber(arg[1]) or 100000
local warmup = math.max(1000, math.floor(iterations / 10))
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
loadFile("ManaInvite/ManaInvite.lua", "ManaTools", ManaTools)
loadFile("CinematicSkip/cinematicskip.lua", "ManaTools", ManaTools)

local noWasteDB = ManaTools.DB.NoWasteCoin
local NoWasteCoin = ManaTools.NoWasteCoin
local ManaInvite = ManaTools.ManaInvite
local inviteDB = ManaTools.DB.ManaInvite
local CinematicSkip = ManaTools.CinematicSkip
local cinematicSkipDB = ManaTools.DB.CinematicSkip

local function runTimed(fn, count)
    local start = os.clock()
    fn(count)
    return os.clock() - start
end

local function appendMetric(results, name, elapsed, count)
    local rate = elapsed > 0 and count / elapsed or math.huge
    results[#results + 1] = string.format("%-32s %10.6f s  %12.0f calls/s  %12.3f us/call", name, elapsed, rate, elapsed * 1000000 / count)
end

local cases = {
    { name = "Mythic raid", type = "raid", difficulty = 16, challenge = false, heroic = false, mythicPlus = false },
    { name = "Heroic raid", type = "raid", difficulty = 15, challenge = false, heroic = true, mythicPlus = false },
    { name = "Mythic+", type = "party", difficulty = 8, challenge = true, heroic = false, mythicPlus = true },
    { name = "Mythic 0", type = "party", difficulty = 23, challenge = false, heroic = false, mythicPlus = true },
    { name = "Open world", type = nil, difficulty = 0, challenge = false, heroic = false, mythicPlus = false },
}

local results = {
    "ManaTools benchmark results",
    "===========================",
    "Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC"),
    string.format("Iterations per hot path: %d", iterations),
    string.format("Warmup per hot path: %d", warmup),
    "",
}

for _, case in ipairs(cases) do
    noWasteDB.allowHeroicRaid = case.heroic
    noWasteDB.allowMythicPlus = case.mythicPlus
    if case.type then
        mock.setContent(case.type, case.difficulty, case.challenge)
    else
        mock.setWorld()
    end

    local allowed
    for _ = 1, warmup do
        allowed = NoWasteCoin.IsAllowedContent()
    end
    local elapsed = os.clock()
    for _ = 1, iterations do
        allowed = NoWasteCoin.IsAllowedContent()
    end
    elapsed = os.clock() - elapsed
    appendMetric(results, "NoWasteCoin " .. case.name, elapsed, iterations)
end

local function benchmarkMembership(size)
    local members = {}
    for i = 1, size do
        members[#members + 1] = "Guild" .. i .. "-Realm"
    end
    mock.setGuildMembers(unpackValues(members))
    ManaInvite:RebuildGuildMembers()

    local target = "Guild" .. size .. "-Realm"
    for _ = 1, warmup do
        ManaInvite.IsGuildMember(target)
    end
    return runTimed(function(count)
        for _ = 1, count do
            ManaInvite.IsGuildMember(target)
        end
    end, iterations)
end

local function benchmarkWhispers()
    mock.setGuildMembers("Guild1-Realm", "Guild2-Realm", "Guild3-Realm", "Guild4-Realm")
    ManaInvite:RebuildGuildMembers()
    inviteDB.enabled = true
    mock.clearInvites()

    local messages = { "mana", "mana pls", "give mana", "MANA", "" }
    local senders = { "Guild1-Realm", "Guild2-Realm", "NotGuild-Realm", "Guild3-Realm", "NotGuild-Realm" }
    local length = #messages
    for i = 1, warmup do
        local n = ((i - 1) % length) + 1
        ManaInvite:OnWhisper(messages[n], senders[n])
    end
    mock.clearInvites()
    return runTimed(function(count)
        for i = 1, count do
            local n = ((i - 1) % length) + 1
            ManaInvite:OnWhisper(messages[n], senders[n])
        end
    end, iterations)
end

local function benchmarkRebuild(size)
    local members = {}
    for i = 1, size do
        members[#members + 1] = "Guild" .. i .. "-Realm"
    end
    mock.setGuildMembers(unpackValues(members))
    for _ = 1, warmup do
        ManaInvite:RebuildGuildMembers()
    end
    local count = math.max(1, math.floor(iterations / 100))
    local elapsed = runTimed(function(rebuildCount)
        for _ = 1, rebuildCount do
            ManaInvite:RebuildGuildMembers()
        end
    end, count)
    return elapsed, count
end

results[#results + 1] = ""
results[#results + 1] = "ManaInvite benchmarks"
results[#results + 1] = "--------------------"
appendMetric(results, "IsGuildMember (100)", benchmarkMembership(100), iterations)
appendMetric(results, "OnWhisper", benchmarkWhispers(), iterations)
for _, size in ipairs({100, 500, 1000}) do
    local elapsed, count = benchmarkRebuild(size)
    appendMetric(results, "RebuildGuildMembers (" .. size .. ")", elapsed, count)
end

results[#results + 1] = ""
results[#results + 1] = "CinematicSkip benchmarks"
results[#results + 1] = "------------------------"

local function benchmarkCinematicStart()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    local calls = 0
    CinematicFrame_CancelCinematic = function() calls = calls + 1 end
    for _ = 1, warmup do
        mock.fireEvent("CINEMATIC_START")
    end
    calls = 0
    local elapsed = runTimed(function(count)
        for _ = 1, count do
            mock.fireEvent("CINEMATIC_START")
        end
    end, iterations)
    CinematicFrame_CancelCinematic = nil
    return elapsed
end

local function benchmarkPlayMovie()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    MovieFrame = CreateFrame("Frame")
    for _ = 1, warmup do
        MovieFrame:Show()
        mock.fireEvent("PLAY_MOVIE")
    end
    local elapsed = runTimed(function(count)
        for _ = 1, count do
            MovieFrame:Show()
            mock.fireEvent("PLAY_MOVIE")
        end
    end, iterations)
    MovieFrame = nil
    return elapsed
end

local function benchmarkTalkingHead()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    TalkingHeadFrame = CreateFrame("Frame")
    for _ = 1, warmup do
        TalkingHeadFrame:Show()
        mock.fireEvent("TALKINGHEAD_REQUESTED")
    end
    local elapsed = runTimed(function(count)
        for _ = 1, count do
            TalkingHeadFrame:Show()
            mock.fireEvent("TALKINGHEAD_REQUESTED")
        end
    end, iterations)
    TalkingHeadFrame = nil
    return elapsed
end

appendMetric(results, "CINEMATIC_START", benchmarkCinematicStart(), iterations)
appendMetric(results, "PLAY_MOVIE", benchmarkPlayMovie(), iterations)
appendMetric(results, "TALKINGHEAD_REQUESTED", benchmarkTalkingHead(), iterations)

results[#results + 1] = ""
results[#results + 1] = "NoInfo benchmarks"
results[#results + 1] = "----------------"

-- Load NoInfo after the other modules so its frame globals can be mocked locally.
GameTooltip = CreateFrame("GameTooltip")
function GameTooltip:GetTooltipData() return self.tooltipData end
function GameTooltip:GetOwner() return self.tooltipOwner end
Minimap = CreateFrame("Frame")
function Minimap:GetCenter() return 500, 500 end
function Minimap:GetWidth() return 100 end
MainMenuMicroButton = CreateFrame("Button")
UIParent = CreateFrame("Frame")
function UIParent:GetEffectiveScale() return 1 end
Enum = { TooltipDataType = { Item = 0 } }

loadFile("NoInfo/NoInfo.lua", "ManaTools", ManaTools)
local noInfoDB = ManaTools.DB.NoInfo
local NoInfo = ManaTools.NoInfo
local noInfoWrapper = GameTooltip:GetScript("OnShow")

local itemData = { type = Enum.TooltipDataType.Item }
local genericData = { type = 999 }

local function benchmarkNoInfoState(name, enabled, inspectMode, data, owner)
    noInfoDB.enabled = enabled
    noInfoDB.inspectMode = inspectMode
    GameTooltip.tooltipData = data
    GameTooltip.tooltipOwner = owner
    NoInfo.Update()
    local handler = GameTooltip:GetScript("OnShow")
    for _ = 1, warmup do
        handler(GameTooltip)
    end
    local elapsed = runTimed(function(count)
        for _ = 1, count do
            handler(GameTooltip)
        end
    end, iterations)
    appendMetric(results, name, elapsed, iterations)
end

benchmarkNoInfoState("NoInfo enabled: generic tooltip", true, false, genericData, nil)
benchmarkNoInfoState("NoInfo enabled: item tooltip", true, false, itemData, nil)
benchmarkNoInfoState("NoInfo enabled: inspect mode", true, true, genericData, nil)

-- Disabled state: measure the actual Blizzard handler path. NoInfo must not wrap it.
noInfoDB.enabled = false
noInfoDB.inspectMode = false
NoInfo.Update()
local disabledHandler = GameTooltip:GetScript("OnShow")
for _ = 1, warmup do
    disabledHandler(GameTooltip)
end
appendMetric(results, "NoInfo disabled: original OnShow", runTimed(function(count)
    for _ = 1, count do
        disabledHandler(GameTooltip)
    end
end, iterations), iterations)

results[#results + 1] = ""
results[#results + 1] = "Allocations: NOT AVAILABLE (Lua benchmark environment does not expose a reliable per-call allocation metric)."
results[#results + 1] = "Generated by test/perf/benchmark.lua"

local output = assert(io.open("test/results/benchmark.txt", "w"))
output:write(table.concat(results, "\n"), "\n")
output:close()

print(table.concat(results, "\n"))
print("Benchmark results written to test/results/benchmark.txt")
