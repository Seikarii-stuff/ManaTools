-- Basic benchmark for the NoWasteCoin content gate.
-- Run from repository root: lua test/perf/benchmark.lua [iterations]

local iterations = tonumber(arg[1]) or 1000000
local mock = assert(loadfile("test/mockwow.lua"))()

local source = assert(io.open("NoWasteCoin/NoWasteCoin.lua", "r")):read("*a")
local chunk = assert(load(source, "NoWasteCoin.lua"))
chunk("NoWasteCoin")

local cases = {
    { name = "Mythic raid", type = "raid", difficulty = 16, challenge = false, heroic = false, mythicPlus = false },
    { name = "Heroic raid", type = "raid", difficulty = 15, challenge = false, heroic = true, mythicPlus = false },
    { name = "Mythic+", type = "party", difficulty = 8, challenge = true, heroic = false, mythicPlus = true },
    { name = "Mythic 0", type = "party", difficulty = 23, challenge = false, heroic = false, mythicPlus = true },
    { name = "Open world", type = nil, difficulty = 0, challenge = false, heroic = false, mythicPlus = false },
}

for _, case in ipairs(cases) do
    mock.reset()
    NoWasteCoinDB.allowHeroicRaid = case.heroic
    NoWasteCoinDB.allowMythicPlus = case.mythicPlus
    if case.type then
        mock.setContent(case.type, case.difficulty, case.challenge)
    else
        mock.setWorld()
    end

    local start = os.clock()
    local allowed
    for _ = 1, iterations do
        allowed = NoWasteCoin_IsAllowedContent()
    end
    local elapsed = os.clock() - start
    local rate = elapsed > 0 and iterations / elapsed or math.huge

    print(string.format("%-16s %10d calls  %10.6f s  %12.0f calls/s  result=%s",
        case.name, iterations, elapsed, rate, tostring(allowed)))
end
