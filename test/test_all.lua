-- ManaTools complete local test runner.
-- Run from repository root: lua test/test_all.lua [iterations]
-- Executes the unit suite and benchmark, prints failures + benchmark summary.

local function run(command)
    local handle = io.popen(command .. " 2>&1", "r")
    if not handle then return 1, "Unable to start: " .. command end
    local output = handle:read("*a")
    local ok, _, code = handle:close()
    if ok then return 0, output end
    return code or 1, output
end

local iterations = tonumber(arg[1]) or 1000000

print("=== ManaTools test suite ===")
local testCode, testOutput = run("lua test/test_no_waste_coin.lua")
print(testOutput)

if testCode ~= 0 then
    print("TEST FAILURES:")
    local found = false
    for line in testOutput:gmatch("[^\r\n]+") do
        if line:match("FAIL:") or line:match("stack traceback:") or line:match("Error") then
            print(line)
            found = true
        end
    end
    if not found then
        print(testOutput)
    end
end

print("=== ManaTools benchmark ===")
local benchmarkCommand = "lua test/perf/benchmark.lua " .. tostring(iterations)
local benchmarkCode, benchmarkOutput = run(benchmarkCommand)
print(benchmarkOutput)

if benchmarkCode ~= 0 then
    print("BENCHMARK FAILED:")
    print(benchmarkOutput)
end

print("=== Summary ===")
print(string.format("Tests: %s", testCode == 0 and "PASS" or "FAIL"))
print(string.format("Benchmark: %s", benchmarkCode == 0 and "PASS" or "FAIL"))
print(string.format("Benchmark results: test/results/benchmark.txt"))

if testCode ~= 0 or benchmarkCode ~= 0 then
    os.exit(1)
end
