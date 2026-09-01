-- NoWasteCoin behavior tests.
-- Deliberately tests behavior, not the number/order of UI controls.
-- Run from repository root: lua test/test_no_waste_coin_behavior.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

local function loadAddonNamespace(db)
    mock.reset(db)
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", namespace)
    return namespace, namespace.DB.NoWasteCoin
end

local function assertEqual(actual, expected, name)
    if actual ~= expected then
        error(string.format("FAIL: %s (expected %s, got %s)", name, tostring(expected), tostring(actual)), 0)
    end
end

local function assertTrue(value, name)
    assertEqual(value, true, name)
end

local function assertFalse(value, name)
    assertEqual(value, false, name)
end

local ManaTools, db = loadAddonNamespace({})
local NoWasteCoin = ManaTools.NoWasteCoin

assertTrue(ManaTools.DB.NoWasteCoin ~= nil, "NoWasteCoin DB branch exists")
assertFalse(db.allowHeroicRaid, "Heroic raid is disabled by default")
assertFalse(db.allowMythicPlus, "Mythic+ is disabled by default")

local passed, total = 0, 0

local function test(name, instanceType, difficultyID, challengeActive, heroic, mythicPlus, expected)
    total = total + 1
    db.allowHeroicRaid = heroic == true
    db.allowMythicPlus = mythicPlus == true

    if instanceType then
        mock.setContent(instanceType, difficultyID, challengeActive)
    else
        mock.setWorld()
    end

    assertEqual(NoWasteCoin.IsAllowedContent(), expected, name)
    passed = passed + 1
end

test("Open world is blocked", nil, 0, false, false, false, false)
test("Mythic raid is allowed", "raid", 16, false, false, false, true)
test("Heroic raid is blocked by default", "raid", 15, false, false, false, false)
test("Heroic raid can be enabled", "raid", 15, false, true, false, true)
test("Normal raid remains blocked", "raid", 14, false, true, true, false)
test("LFR remains blocked", "raid", 17, false, true, true, false)
test("Mythic 0 is blocked", "party", 23, false, false, true, false)
test("Mythic+ is blocked by default", "party", 8, true, false, false, false)
test("Mythic+ can be enabled", "party", 8, true, false, true, true)
test("Non-challenge party remains blocked", "party", 8, false, false, true, false)
test("Scenario is blocked", "scenario", 0, false, true, true, false)
test("Unknown instance type is blocked", "arena", 16, false, true, true, false)

db.allowHeroicRaid = true
db.allowMythicPlus = false
mock.setContent("raid", 15, false)
assertTrue(NoWasteCoin.IsAllowedContent(), "Heroic setting does not get lost")
mock.setContent("party", 8, true)
assertFalse(NoWasteCoin.IsAllowedContent(), "Heroic setting does not enable Mythic+")

db.allowHeroicRaid = false
db.allowMythicPlus = true
mock.setContent("raid", 15, false)
assertFalse(NoWasteCoin.IsAllowedContent(), "Mythic+ setting does not enable Heroic raid")

print(string.format("NoWasteCoin behavior tests passed: %d/%d", passed, total))
