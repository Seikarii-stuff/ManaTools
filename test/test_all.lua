-- ManaTools complete local test runner.
-- Run from repository root: lua test/test_all.lua [iterations]
-- Executes all feature tests and the benchmark, returning a failing process
-- status when either stage fails.

local iterations = tonumber(arg[1]) or 100000

local function execute(command)
    local result = os.execute(command)
    if type(result) == "number" then
        return result == 0
    end
    return result == true
end

print("=== ManaTools test suite ===")
local noWastePassed = execute("lua test/test_no_waste_coin.lua")
local manaInvitePassed = execute("lua test/test_mana_invite.lua")
local manaCoinPassed = execute("lua test/test_mana_coin.lua")
local cinematicSkipPassed = execute("lua test/test_cinematic_skip.lua")
local testsPassed = noWastePassed and manaInvitePassed and manaCoinPassed and cinematicSkipPassed
if not testsPassed then
    print("TESTS: FAIL")
    print("One or more test commands failed. Review the failure output above.")
else
    print("TESTS: PASS")
end

print("")
print("=== ManaTools benchmark ===")
local benchmarkPassed = execute("lua test/perf/benchmark.lua " .. tostring(iterations))
if not benchmarkPassed then
    print("BENCHMARK: FAIL")
    print("The benchmark command failed. Review the failure output above.")
else
    print("BENCHMARK: PASS")
end

print("")
print("=== Summary ===")
print("NoWasteCoin tests: " .. (noWastePassed and "PASS" or "FAIL"))
print("ManaInvite tests: " .. (manaInvitePassed and "PASS" or "FAIL"))
print("Mana coin tests: " .. (manaCoinPassed and "PASS" or "FAIL"))
print("CinematicSkip tests: " .. (cinematicSkipPassed and "PASS" or "FAIL"))
print("Tests: " .. (testsPassed and "PASS" or "FAIL"))
print("Benchmark: " .. (benchmarkPassed and "PASS" or "FAIL"))
print("Benchmark results: test/results/benchmark.txt")

if not testsPassed or not benchmarkPassed then
    os.exit(1)
end
