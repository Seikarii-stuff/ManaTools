-- ManaTools complete local test runner.
-- Run from repository root: lua test/test_all.lua [iterations]
-- Executes tests and benchmark, preserves their console output, and returns
-- a failing process status when either stage fails.

local iterations = tonumber(arg[1]) or 1000000

local function execute(command)
    local result = os.execute(command)
    if type(result) == "number" then
        return result == 0
    end
    return result == true
end

print("=== ManaTools test suite ===")
local testsPassed = execute("lua test/test_no_waste_coin.lua")
if not testsPassed then
    print("TESTS: FAIL")
    print("The test command failed. Review the failure output above.")
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
print("Tests: " .. (testsPassed and "PASS" or "FAIL"))
print("Benchmark: " .. (benchmarkPassed and "PASS" or "FAIL"))
print("Benchmark results: test/results/benchmark.txt")

if not testsPassed or not benchmarkPassed then
    os.exit(1)
end
