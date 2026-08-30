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

local noWasteDB = ManaTools.DB.NoWasteCoin
local NoWasteCoin = ManaTools.NoWasteCoin
local ManaInvite = ManaTools.ManaInvite
local inviteDB = ManaTools.DB.ManaInvite

local function runTimed(fn, count)
    local start = os.clock()
    fn(count)
    return os.clock() - start
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

    local start = os.clock()
    local allowed
    for _ = 1, warmup do
        allowed = NoWasteCoin.IsAllowedContent()
    end
    start = os.clock()
    for _ = 1, iterations do
        allowed = NoWasteCoin.IsAllowedContent()
    end
    local elapsed = os.clock() - start
    local rate = elapsed > 0 and iterations / elapsed or math.huge
    results[#results + 1] = string.format("%-16s %10.6f s  %12.0f calls/s  result=%s", case.name, elapsed, rate, tostring(allowed))
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
        ManaInvite:IsGuildMember(target)
    end
    return runTimed(function(count)
        for _ = 1, count do
            ManaInvite:IsGuildMember(target)
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

local function appendMetric(name, elapsed, count)
    local rate = elapsed > 0 and count / elapsed or math.huge
    results[#results + 1] = string.format("%-28s %10.6f s  %12.0f calls/s  %12.3f us/call", name, elapsed, rate, elapsed * 1000000 / count)
end

results[#results + 1] = ""
results[#results + 1] = "ManaInvite benchmarks"
results[#results + 1] = "--------------------"
appendMetric("IsGuildMember (100)", benchmarkMembership(100), iterations)
appendMetric("OnWhisper", benchmarkWhispers(), iterations)
for _, size in ipairs({100, 500, 1000}) do
    local elapsed, count = benchmarkRebuild(size)
    appendMetric("RebuildGuildMembers (" .. size .. ")", elapsed, count)
end

results[#results + 1] = ""
results[#results + 1] = "Allocations: NOT AVAILABLE (Lua benchmark environment does not expose a reliable per-call allocation metric)."
results[#results + 1] = "Generated by test/perf/benchmark.lua"

local output = assert(io.open("test/results/benchmark.txt", "w"))
output:write(table.concat(results, "\n"), "\n")
output:close()

print(table.concat(results, "\n"))
print("Benchmark results written to test/results/benchmark.txt")
