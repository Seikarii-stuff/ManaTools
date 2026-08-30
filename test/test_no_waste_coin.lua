-- ManaTools content-gating and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_waste_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local source = assert(io.open("NoWasteCoin/NoWasteCoin.lua", "r")):read("*a")
local loader = loadstring or load
local chunk = assert(loader(source, "NoWasteCoin.lua"))

local ManaTools = { DB = {}, NoWasteCoin = {} }
chunk("NoWasteCoin", ManaTools)

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
local function test(name, fn)
    total = total + 1
    mock.reset()
    fn()
    passed = passed + 1
end

-- Configuration defaults and independence.
test("Defaults are initialized once in central DB", function()
    assertEqual(ManaTools.DB.NoWasteCoin, NoWasteCoinDB, "central DB aliases SavedVariables")
    assertFalse(ManaTools.DB.NoWasteCoin.allowHeroicRaid, "heroic default")
    assertFalse(ManaTools.DB.NoWasteCoin.allowMythicPlus, "mythic+ default")
end)

test("Heroic setting is independent", function()
    ManaTools.DB.NoWasteCoin.allowHeroicRaid = true
    assertTrue(ManaTools.DB.NoWasteCoin.allowHeroicRaid, "heroic enabled")
    assertFalse(ManaTools.DB.NoWasteCoin.allowMythicPlus, "mythic+ remains disabled")
end)

test("Mythic+ setting is independent", function()
    ManaTools.DB.NoWasteCoin.allowMythicPlus = true
    assertFalse(ManaTools.DB.NoWasteCoin.allowHeroicRaid, "heroic remains disabled")
    assertTrue(ManaTools.DB.NoWasteCoin.allowMythicPlus, "mythic+ enabled")
end)

local function contentTest(name, instanceType, difficultyID, challengeActive, heroic, mythicPlus, expected)
    test(name, function()
        ManaTools.DB.NoWasteCoin.allowHeroicRaid = heroic == true
        ManaTools.DB.NoWasteCoin.allowMythicPlus = mythicPlus == true
        if instanceType then
            mock.setContent(instanceType, difficultyID, challengeActive)
        else
            mock.setWorld()
        end
        assertEqual(ManaTools.NoWasteCoin.IsAllowedContent(), expected, name)
    end)
end

contentTest("Open world", nil, 0, false, false, false, false)
contentTest("Mythic raid allowed", "raid", 16, false, false, false, true)
contentTest("Mythic raid allowed with heroic exception", "raid", 16, false, true, false, true)
contentTest("Mythic raid allowed with M+ exception", "raid", 16, false, false, true, true)
contentTest("Heroic raid blocked by default", "raid", 15, false, false, false, false)
contentTest("Heroic raid allowed by exception", "raid", 15, false, true, false, true)
contentTest("Heroic raid blocked without exception", "raid", 15, false, false, true, false)
contentTest("Normal raid blocked", "raid", 14, false, false, false, false)
contentTest("Normal raid blocked with exceptions", "raid", 14, false, true, true, false)
contentTest("LFR blocked", "raid", 17, false, true, true, false)
contentTest("Mythic 0 blocked", "party", 23, false, false, false, false)
contentTest("Mythic 0 blocked with M+ exception", "party", 23, false, false, true, false)
contentTest("Mythic+ blocked by default", "party", 8, true, false, false, false)
contentTest("Mythic+ allowed by exception", "party", 8, true, false, true, true)
contentTest("M+ setting without challenge mode blocked", "party", 8, false, false, true, false)
contentTest("Heroic setting cannot enable M+", "party", 8, true, true, false, false)
contentTest("Scenario blocked", "scenario", 0, false, true, true, false)
contentTest("Delve-like scenario blocked", "scenario", 208, false, true, true, false)
contentTest("Unknown instance type blocked", "arena", 16, false, true, true, false)

-- Lifecycle and API.
test("Feature API is namespaced", function()
    assertTrue(type(ManaTools.NoWasteCoin.Initialize) == "function", "Initialize API")
    assertTrue(type(ManaTools.NoWasteCoin.IsAllowedContent) == "function", "content API")
    assertTrue(type(ManaTools.NoWasteCoin.Update) == "function", "update API")
    assertEqual(NoWasteCoin_IsAllowedContent, nil, "legacy content global absent")
    assertEqual(NoWasteCoin_Update, nil, "legacy update global absent")
end)

test("Missing BonusRollFrame is safe", function()
    assertFalse(ManaTools.NoWasteCoin.Initialize(), "initialize without frame")
end)

test("Missing RollButton is safe", function()
    BonusRollFrame = mock.newBonusRollFrame()
    BonusRollFrame.RollButton = nil
    assertFalse(ManaTools.NoWasteCoin.Initialize(), "initialize without button")
end)

test("Late frame appearance installs hooks", function()
    BonusRollFrame = mock.newBonusRollFrame()
    assertTrue(ManaTools.NoWasteCoin.Initialize(), "late initialize succeeds")
    assertEqual(#BonusRollFrame.hooks.OnShow, 1, "frame hook installed")
    assertEqual(#BonusRollFrame.RollButton.hooks.OnShow, 1, "button hook installed")
end)

test("Repeated initialization is idempotent", function()
    BonusRollFrame = mock.newBonusRollFrame()
    ManaTools.NoWasteCoin.Initialize()
    ManaTools.NoWasteCoin.Initialize()
    ManaTools.NoWasteCoin.Initialize()
    assertEqual(#BonusRollFrame.hooks.OnShow, 1, "frame hook count")
    assertEqual(#BonusRollFrame.RollButton.hooks.OnShow, 1, "button hook count")
end)

test("ADDON_LOADED retries when UI appears later", function()
    assertFalse(ManaTools.NoWasteCoin.Initialize(), "initial attempt without frame")
    BonusRollFrame = mock.newBonusRollFrame()
    mock.fireEvent("ADDON_LOADED", "Blizzard_BonusRoll")
    assertEqual(#BonusRollFrame.hooks.OnShow, 1, "late addon hook count")
end)

test("Update changes button state from content", function()
    BonusRollFrame = mock.newBonusRollFrame()
    ManaTools.NoWasteCoin.Initialize()
    mock.setWorld()
    ManaTools.NoWasteCoin.Update()
    assertFalse(BonusRollFrame.RollButton.enabled, "world disabled")
    assertEqual(BonusRollFrame.RollButton.alpha, 0.4, "world alpha")
    assertEqual(BonusRollFrame.RollButton.tooltipText, "NoWasteCoin: Bonus Roll disabled here.", "world tooltip")

    mock.setContent("raid", 16, false)
    ManaTools.NoWasteCoin.Update()
    assertTrue(BonusRollFrame.RollButton.enabled, "mythic enabled")
    assertEqual(BonusRollFrame.RollButton.alpha, 1, "mythic alpha")
    assertEqual(BonusRollFrame.RollButton.tooltipText, nil, "mythic tooltip")
end)

test("Configuration changes can request an update", function()
    BonusRollFrame = mock.newBonusRollFrame()
    ManaTools.NoWasteCoin.Initialize()
    mock.setContent("raid", 15, false)
    ManaTools.DB.NoWasteCoin.allowHeroicRaid = false
    ManaTools.NoWasteCoin.Update()
    assertFalse(BonusRollFrame.RollButton.enabled, "heroic initially disabled")
    ManaTools.DB.NoWasteCoin.allowHeroicRaid = true
    ManaTools.NoWasteCoin.Update()
    assertTrue(BonusRollFrame.RollButton.enabled, "heroic updated")
end)

print(string.format("ManaTools tests passed: %d/%d", passed, total))
