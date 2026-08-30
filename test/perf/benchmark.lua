-- Basic benchmark for the content-gating function.
-- Run with: lua test/perf/benchmark.lua

local iterations = tonumber(arg[1]) or 100000
local source = assert(io.open("NoWasteCoin/NoWasteCoin.lua", "r")):read("*a")

IsInInstance = function() return true, "raid" end
GetInstanceInfo = function() return "Benchmark Instance", "raid", 16 end
C_ChallengeMode = { IsChallengeModeActive = function() return false end }
C_Timer = { After = function() end }
CreateFrame = function() return nil end
NoWasteCoinDB = { allowHeroicRaid = false, allowMythicPlus = false }

local chunk = assert(load(source, "NoWasteCoin.lua"))
chunk("NoWasteCoin")

local start = os.clock()
local allowed
for _ = 1, iterations do
    allowed = NoWasteCoin_IsAllowedContent()
end
local elapsed = os.clock() - start

print(string.format("iterations: %d", iterations))
print(string.format("elapsed: %.6f s", elapsed))
print(string.format("calls/sec: %.0f", iterations / elapsed))
print(string.format("last result: %s", tostring(allowed)))
