-- ManaTools content-gating, DB and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_waste_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()

local loader = loadstring or load
local function loadFile(path, ...)
    local source = assert(io.open(path, "r")):read("*a")
    local chunk = assert(loader(source, path))
    chunk(...)
end

-- Bootstrap must own the relationship between the SavedVariables global and the addon namespace.
ManaToolsDB = nil
loadFile("Bootstrap.lua", "ManaTools", {})
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB must reference ManaToolsDB")
loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", {})

local db = ManaTools.DB.NoWasteCoin
local NoWasteCoin = ManaTools.NoWasteCoin

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

-- Central DB and defaults.
total = total + 1
assertTrue(ManaTools.DB == ManaToolsDB, "central DB identity")
passed = passed + 1

total = total + 1
assertTrue(ManaTools.DB.NoWasteCoin ~= nil, "NoWasteCoin DB branch exists")
passed = passed + 1

total = total + 1
assertFalse(db.allowHeroicRaid, "heroic default")
passed = passed + 1

total = total + 1
assertFalse(db.allowMythicPlus, "Mythic+ default")
passed = passed + 1

-- Existing values are preserved by feature initialization.
db.allowHeroicRaid = true
db.allowMythicPlus = true
NoWasteCoin.Initialize()
assertTrue(db.allowHeroicRaid, "existing heroic value preserved")
assertTrue(db.allowMythicPlus, "existing Mythic+ value preserved")

-- Re-running Bootstrap must not replace the DB or reset settings.
local existingDB = ManaToolsDB
loadFile("Bootstrap.lua", "ManaTools", {})
assertTrue(ManaTools.DB == existingDB, "Bootstrap preserves existing DB table")
assertTrue(ManaTools.DB.NoWasteCoin.allowHeroicRaid, "Bootstrap preserves heroic setting")
assertTrue(ManaTools.DB.NoWasteCoin.allowMythicPlus, "Bootstrap preserves Mythic+ setting")

-- Return to defaults for content matrix.
db.allowHeroicRaid = false
db.allowMythicPlus = false

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

-- Configuration branches are independent.
db.allowHeroicRaid = true
db.allowMythicPlus = false
assertTrue(NoWasteCoin.IsAllowedContent(), "heroic setting enables heroic raid")
mock.setContent("party", 8, true)
assertFalse(NoWasteCoin.IsAllowedContent(), "heroic setting does not enable Mythic+")
db.allowHeroicRaid = false
db.allowMythicPlus = true
mock.setContent("raid", 15, false)
assertFalse(NoWasteCoin.IsAllowedContent(), "Mythic+ setting does not enable heroic raid")

-- Lifecycle: absent UI is safe, late UI can be hooked, repeated initialization is idempotent.
BonusRollFrame = nil
assertEqual(NoWasteCoin.Initialize(), false, "initialization without BonusRollFrame")

local frame = mock.newBonusRollFrame()
BonusRollFrame = frame
assertTrue(NoWasteCoin.Initialize(), "late BonusRollFrame initialization")
assertEqual(#frame.hooks.OnShow, 1, "frame OnShow hook installed once")
assertEqual(#frame.RollButton.hooks.OnShow, 1, "button OnShow hook installed once")

NoWasteCoin.Initialize()
NoWasteCoin.Initialize()
assertEqual(#frame.hooks.OnShow, 1, "repeated initialization does not duplicate frame hook")
assertEqual(#frame.RollButton.hooks.OnShow, 1, "repeated initialization does not duplicate button hook")

-- Button state follows content and configuration.
db.allowHeroicRaid = false
db.allowMythicPlus = false
mock.setContent("raid", 15, false)
NoWasteCoin.Update()
assertFalse(frame.RollButton.enabled, "blocked content disables button")
assertEqual(frame.RollButton.alpha, 0.4, "blocked content alpha")
assertEqual(frame.RollButton.tooltipText, "NoWasteCoin: Bonus Roll disabled here.", "blocked content tooltip")

db.allowHeroicRaid = true
NoWasteCoin.Update()
assertTrue(frame.RollButton.enabled, "configuration change enables button")
assertEqual(frame.RollButton.alpha, 1, "allowed content alpha")
assertEqual(frame.RollButton.tooltipText, nil, "allowed content clears tooltip")

-- Missing button is safe.
BonusRollFrame = { RollButton = nil }
assertEqual(NoWasteCoin.Update(), nil, "missing RollButton update is safe")

print(string.format("ManaTools tests passed: %d/%d", passed, total))
