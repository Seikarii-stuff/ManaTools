-- ManaTools content-gating, DB and Bonus Roll lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_waste_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local source = assert(io.open(path, "r")):read("*a")
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

local existingFeature2 = {}
local existingDB = {
    NoWasteCoin = { allowHeroicRaid = true, allowMythicPlus = true },
    Feature2 = existingFeature2,
}
local ManaTools, db = loadAddonNamespace(existingDB)
local NoWasteCoin = ManaTools.NoWasteCoin
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB must reference ManaToolsDB")
assert(ManaTools.DB.NoWasteCoin == existingDB.NoWasteCoin, "existing NoWasteCoin branch is preserved")
assert(db.allowHeroicRaid == true, "existing heroic value preserved")
assert(db.allowMythicPlus == true, "existing Mythic+ value preserved")
assert(ManaTools.DB.Feature2 == existingFeature2, "unrelated DB branches are preserved")

ManaTools, db = loadAddonNamespace({})
NoWasteCoin = ManaTools.NoWasteCoin
assert(ManaTools.DB.NoWasteCoin ~= nil, "NoWasteCoin DB branch exists")
assert(db.allowHeroicRaid == false, "heroic default")
assert(db.allowMythicPlus == false, "Mythic+ default")

db.allowHeroicRaid = true
db.allowMythicPlus = true
local bootstrapDB = ManaToolsDB
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
assert(ManaTools.DB == bootstrapDB, "Bootstrap preserves existing DB table")
assert(ManaTools.DB.NoWasteCoin.allowHeroicRaid == true, "Bootstrap preserves heroic setting")
assert(ManaTools.DB.NoWasteCoin.allowMythicPlus == true, "Bootstrap preserves Mythic+ setting")

local function assertEqual(actual, expected, name)
    if actual ~= expected then
        error(string.format("FAIL: %s (expected %s, got %s)", name, tostring(expected), tostring(actual)), 0)
    end
end
local function assertTrue(value, name) assertEqual(value, true, name) end
local function assertFalse(value, name) assertEqual(value, false, name) end

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

db.allowHeroicRaid = false
db.allowMythicPlus = false

test("Open world", nil, 0, false, false, false, false)
test("Mythic raid allowed", "raid", 16, false, false, false, true)
test("Heroic raid blocked by default", "raid", 15, false, false, false, false)
test("Heroic raid allowed by exception", "raid", 15, false, true, false, true)
test("Normal raid blocked", "raid", 14, false, true, true, false)
test("LFR blocked", "raid", 17, false, true, true, false)
test("Mythic 0 blocked", "party", 23, false, false, true, false)
test("Mythic+ blocked by default", "party", 8, true, false, false, false)
test("Mythic+ allowed by exception", "party", 8, true, false, true, true)
test("Mythic+ without active challenge blocked", "party", 8, false, false, true, false)
test("Heroic setting cannot enable Mythic+", "party", 8, true, false, false, false)
test("Scenario blocked", "scenario", 0, false, true, true, false)
test("Delve-like scenario blocked", "scenario", 208, false, true, true, false)
test("Unknown instance type blocked", "arena", 16, false, true, true, false)

local feature2 = {}
ManaTools.DB.Feature2 = feature2
db.allowHeroicRaid = true
db.allowMythicPlus = false
mock.setContent("raid", 15, false)
assertTrue(NoWasteCoin.IsAllowedContent(), "heroic setting enables heroic raid")
assertFalse(db.allowMythicPlus, "heroic setting does not enable Mythic+")
mock.setContent("party", 8, true)
assertFalse(NoWasteCoin.IsAllowedContent(), "heroic setting does not enable Mythic+")
db.allowHeroicRaid = false
db.allowMythicPlus = true
mock.setContent("raid", 15, false)
assertFalse(NoWasteCoin.IsAllowedContent(), "Mythic+ setting does not enable heroic raid")
assertTrue(ManaTools.DB.Feature2 == feature2, "settings do not replace other DB branches")

BonusRollFrame = nil
assertEqual(NoWasteCoin.Initialize(), false, "initialization without BonusRollFrame")
assertEqual(mock.secureHookCount("BonusRollFrame_StartBonusRoll"), 0, "no start hook before Blizzard function exists")
mock.defineBonusRollStart()
mock.fireEvent("ADDON_LOADED", "Blizzard_BonusRoll")
assertEqual(mock.secureHookCount("BonusRollFrame_StartBonusRoll"), 1, "BonusRoll start hook installed once")
mock.fireEvent("ADDON_LOADED", "Blizzard_BonusRoll")
assertEqual(mock.secureHookCount("BonusRollFrame_StartBonusRoll"), 1, "BonusRoll start hook is not duplicated")

local frame = mock.newBonusRollFrame(true)
BonusRollFrame = frame
mock.setContent("raid", 15, false)
mock.startBonusRoll()
assertEqual(#frame.PromptFrame.RollButton.hooks.OnShow, 1, "PromptFrame.RollButton is hooked")
assertEqual(#frame.PromptFrame.RollButton.hooks.OnEnable, 1, "PromptFrame.RollButton has an enable guard")
assertEqual(#frame.RollButton.hooks.OnShow, 0, "fallback RollButton is not selected when PromptFrame button exists")
assertFalse(frame.PromptFrame.RollButton.enabled, "PromptFrame button is blocked")
mock.startBonusRoll()
assertEqual(#frame.PromptFrame.RollButton.hooks.OnShow, 1, "same button receives one OnShow hook")
assertEqual(#frame.PromptFrame.RollButton.hooks.OnEnable, 1, "same button receives one OnEnable hook")

mock.setContent("raid", 16, false)
NoWasteCoin.Update()
assertTrue(frame.PromptFrame.RollButton.enabled, "Mythic raid enables button")
assertEqual(frame.PromptFrame.RollButton.alpha, 1, "allowed content alpha")
assertEqual(frame.PromptFrame.RollButton.tooltipText, nil, "allowed content clears tooltip")

db.allowHeroicRaid = false
mock.setContent("raid", 15, false)
NoWasteCoin.Update()
assertFalse(frame.PromptFrame.RollButton.enabled, "heroic raid disabled by option")
db.allowHeroicRaid = true
NoWasteCoin.Update()
assertTrue(frame.PromptFrame.RollButton.enabled, "heroic raid enabled by option")

db.allowHeroicRaid = false
db.allowMythicPlus = false
mock.setContent("party", 8, true)
NoWasteCoin.Update()
assertFalse(frame.PromptFrame.RollButton.enabled, "Mythic+ disabled by option")
db.allowMythicPlus = true
NoWasteCoin.Update()
assertTrue(frame.PromptFrame.RollButton.enabled, "active Mythic+ enabled by option")
mock.setContent("party", 8, false)
NoWasteCoin.Update()
assertFalse(frame.PromptFrame.RollButton.enabled, "inactive Mythic+ remains blocked")

db.allowMythicPlus = false
mock.setContent("party", 8, true)
NoWasteCoin.Update()
frame.PromptFrame.RollButton:Enable()
assertFalse(frame.PromptFrame.RollButton.enabled, "blocked button cannot remain enabled after Blizzard enables it")

local replacement = mock.newBonusRollFrame(true)
BonusRollFrame = replacement
mock.setContent("raid", 15, false)
mock.startBonusRoll()
assertEqual(#replacement.PromptFrame.RollButton.hooks.OnShow, 1, "replacement PromptFrame button is hooked")
assertEqual(#replacement.PromptFrame.RollButton.hooks.OnEnable, 1, "replacement button gets enable guard")
assertFalse(replacement.PromptFrame.RollButton.enabled, "replacement button is blocked")
assertEqual(#frame.PromptFrame.RollButton.hooks.OnShow, 1, "old button keeps its single hook")

local fallbackFrame = mock.newBonusRollFrame(false)
BonusRollFrame = fallbackFrame
mock.setContent("raid", 16, false)
mock.startBonusRoll()
assertEqual(#fallbackFrame.RollButton.hooks.OnShow, 1, "fallback RollButton is hooked")
assertTrue(fallbackFrame.RollButton.enabled, "fallback RollButton follows allowed content")

local lateFrame = mock.newBonusRollFrame(false)
lateFrame.RollButton = nil
BonusRollFrame = lateFrame
assertEqual(NoWasteCoin.Initialize(), false, "missing button is safe")
lateFrame.PromptFrame = mock.newBonusRollFrame(false)
mock.setContent("raid", 16, false)
mock.startBonusRoll()
assertEqual(#lateFrame.PromptFrame.RollButton.hooks.OnShow, 1, "late-created known button is hooked")

BonusRollFrame = fallbackFrame
mock.setContent("raid", 15, false)
db.allowHeroicRaid = false
loadFile("Options.lua", "ManaTools", ManaTools)
local clickFrames = {}
for _, created in ipairs(mock.createdFrames) do
    if created.scripts and created.scripts.OnClick then
        table.insert(clickFrames, created)
    end
end
assertEqual(#clickFrames, 3, "options create the two NoWasteCoin checkboxes and one Mana Invite checkbox")
clickFrames[1]:SetChecked(true)
clickFrames[1]:TriggerScript("OnClick")
assertTrue(db.allowHeroicRaid, "Heroic option updates central DB")
assertTrue(fallbackFrame.RollButton.enabled, "Heroic option refreshes button immediately")
clickFrames[2]:SetChecked(true)
clickFrames[2]:TriggerScript("OnClick")
assertTrue(db.allowMythicPlus, "Mythic+ option updates central DB")
assertTrue(ManaTools.DB.NoWasteCoin == ManaToolsDB.NoWasteCoin, "options keep central DB identity")

print(string.format("ManaTools tests passed: %d/%d", passed, total))
