-- ManaTools content-gating test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_waste_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()

local source = assert(io.open("NoWasteCoin/NoWasteCoin.lua", "r")):read("*a")
local chunk = assert(load(source, "NoWasteCoin.lua"))
chunk("NoWasteCoin")

local function assertEqual(actual, expected, name)
    if actual ~= expected then
        error(string.format("FAIL: %s (expected %s, got %s)", name, tostring(expected), tostring(actual)), 0)
    end
end

local passed, total = 0, 0
local function test(name, instanceType, difficultyID, challengeActive, heroic, mythicPlus, expected)
    total = total + 1
    mock.reset()
    NoWasteCoinDB.allowHeroicRaid = heroic == true
    NoWasteCoinDB.allowMythicPlus = mythicPlus == true

    if instanceType then
        mock.setContent(instanceType, difficultyID, challengeActive)
    else
        mock.setWorld()
    end

    assertEqual(NoWasteCoin_IsAllowedContent(), expected, name)
    passed = passed + 1
end

-- Open world.
test("Open world", nil, 0, false, false, false, false)

-- Raid matrix.
test("Mythic raid allowed", "raid", 16, false, false, false, true)
test("Mythic raid allowed with heroic exception", "raid", 16, false, true, false, true)
test("Mythic raid allowed with M+ exception", "raid", 16, false, false, true, true)
test("Heroic raid blocked by default", "raid", 15, false, false, false, false)
test("Heroic raid allowed by exception", "raid", 15, false, true, false, true)
test("Heroic raid blocked without exception", "raid", 15, false, false, true, false)
test("Normal raid blocked", "raid", 14, false, false, false, false)
test("Normal raid blocked with exceptions", "raid", 14, false, true, true, false)
test("LFR blocked", "raid", 17, false, true, true, false)

-- Party / Mythic+ matrix.
test("Mythic 0 blocked", "party", 23, false, false, false, false)
test("Mythic 0 blocked with M+ exception", "party", 23, false, false, true, false)
test("Mythic+ blocked by default", "party", 8, true, false, false, false)
test("Mythic+ allowed by exception", "party", 8, true, false, true, true)
test("M+ setting without challenge mode blocked", "party", 8, false, false, true, false)
test("Heroic setting cannot enable M+", "party", 8, true, true, false, false)

-- Everything else remains blocked.
test("Scenario blocked", "scenario", 0, false, true, true, false)
test("Delve-like scenario blocked", "scenario", 208, false, true, true, false)
test("Unknown instance type blocked", "arena", 16, false, true, true, false)

print(string.format("ManaTools tests passed: %d/%d", passed, total))
