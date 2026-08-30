-- ManaTools content-gating, DB and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_waste_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()

local loader = loadstring or load
local function loadFile(path, ...)
    local source = io.open(path, "r")
    assert(source)
    local content = source:read("*a")
    source:close()
    local chunk = assert(loader(content, path))
    chunk(...)
end

local function loadAddonNamespace(db, includeInvite)
    mock.reset(db)
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    ManaTools = namespace
    loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", ManaTools)
    if includeInvite then
        loadFile("ManaInvite/ManaInvite.lua", "ManaTools", ManaTools)
    end
    return namespace, namespace.DB.NoWasteCoin
end

-- Existing central DB values are preserved.
local existingFeature2 = {}
local existingDB = {
    NoWasteCoin = { allowHeroicRaid = true, allowMythicPlus = true },
    ManaInvite = { enabled = true },
    Feature2 = existingFeature2,
}
local ManaTools, db = loadAddonNamespace(existingDB, true)
local NoWasteCoin = ManaTools.NoWasteCoin
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB must reference ManaToolsDB")
assert(ManaTools.DB.NoWasteCoin == existingDB.NoWasteCoin, "existing NoWasteCoin branch is preserved")
assert(db.allowHeroicRaid == true, "existing heroic value preserved")
assert(db.allowMythicPlus == true, "existing Mythic+ value preserved")
assert(ManaTools.DB.ManaInvite == existingDB.ManaInvite, "existing ManaInvite branch is preserved")
assert(ManaTools.DB.ManaInvite.enabled == true, "existing ManaInvite setting preserved")
assert(ManaTools.DB.Feature2 == existingFeature2, "unrelated DB branches are preserved")

-- A fresh DB receives defaults exactly once.
ManaTools, db = loadAddonNamespace({}, true)
NoWasteCoin = ManaTools.NoWasteCoin
assert(ManaTools.DB.NoWasteCoin ~= nil, "NoWasteCoin DB branch exists")
assert(db.allowHeroicRaid == false, "heroic default")
assert(db.allowMythicPlus == false, "Mythic+ default")
assert(ManaTools.DB.ManaInvite ~= nil, "ManaInvite DB branch exists")
assert(ManaTools.DB.ManaInvite.enabled == false, "ManaInvite disabled by default")

-- Re-running Bootstrap must not replace the DB or reset settings.
db.allowHeroicRaid = true
db.allowMythicPlus = true
ManaTools.DB.ManaInvite.enabled = true
local bootstrapDB = ManaToolsDB
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
assert(ManaTools.DB == bootstrapDB, "Bootstrap preserves existing DB table")
assert(ManaTools.DB.NoWasteCoin.allowHeroicRaid == true, "Bootstrap preserves heroic setting")
assert(ManaTools.DB.NoWasteCoin.allowMythicPlus == true, "Bootstrap preserves Mythic+ setting")
assert(ManaTools.DB.ManaInvite.enabled == true, "Bootstrap preserves ManaInvite setting")

-- ManaInvite tests.
ManaTools, db = loadAddonNamespace({ManaInvite = {enabled = false}}, false)
loadFile("ManaInvite/ManaInvite.lua", "ManaTools", ManaTools)
local ManaInvite = ManaTools.ManaInvite
assert(ManaTools.DB.ManaInvite.enabled == false, "ManaInvite default remains false")

mock.setGuildMembers("Player-Realm", "Other-Realm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(ManaInvite.IsGuildMember("Player-Realm"), "guild cache contains member")
assert(ManaInvite.IsGuildMember("player-realm"), "guild lookup is case insensitive")

-- Roster rebuild removes stale members and adds current members.
mock.setGuildMembers("New-Realm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(not ManaInvite.IsGuildMember("Player-Realm"), "stale guild member removed")
assert(ManaInvite.IsGuildMember("New-Realm"), "new guild member added")

-- Disabled means CHAT_MSG_WHISPER is not registered and invites never happen.
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event disabled")
mock.clearInvites()
mock.fireEvent("CHAT_MSG_WHISPER", "mana", "New-Realm")
assert(#mock.invites == 0, "disabled feature does not invite")

-- Enabling registers once and exact trigger variants invite guild members.
ManaTools.DB.ManaInvite.enabled = true
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
assert(ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event enabled")

local triggerMessages = {"mana", "Mana", "MANA", "MaNa", " mana "}
for _, message in ipairs(triggerMessages) do
    mock.clearInvites()
    mock.fireEvent("CHAT_MSG_WHISPER", message, "New-Realm")
    assert(#mock.invites == 1, "exact trigger invites guild member: " .. message)
    assert(mock.invites[1] == "New-Realm", "InviteUnit receives whisper sender")
end

local rejectedMessages = {"mana pls", "give mana", "mana?", "manana", "my mana", "mana please", ""}
for _, message in ipairs(rejectedMessages) do
    mock.clearInvites()
    mock.fireEvent("CHAT_MSG_WHISPER", message, "New-Realm")
    assert(#mock.invites == 0, "rejected trigger does not invite: " .. message)
end

mock.clearInvites()
mock.fireEvent("CHAT_MSG_WHISPER", "mana", "NotGuild-Realm")
assert(#mock.invites == 0, "non-guild member is not invited")

-- Disabling unregisters the whisper event immediately.
ManaTools.DB.ManaInvite.enabled = false
ManaInvite:UpdateEvents()
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event disabled after toggle")

-- Existing NoWasteCoin behavior and lifecycle.
NoWasteCoin = ManaTools.NoWasteCoin
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
    if instanceType then mock.setContent(instanceType, difficultyID, challengeActive) else mock.setWorld() end
    assertEqual(NoWasteCoin.IsAllowedContent(), expected, name)
    passed = passed + 1
end

db.allowHeroicRaid = false
db.allowMythicPlus = false
test("Open world", nil, 0, false, false, false, false)
test("Mythic raid allowed", "raid", 16, false, false, false, true)
test("Mythic raid allowed with heroic exception", "raid", 16, false, true, false, true)
test("Mythic raid allowed with M+ exception", "raid", 16, false, false, true, true)
test("Heroic raid blocked by default", "raid", 15, false, false, false, false)
test("Heroic raid allowed by exception", "raid", 15, false, true, false, true)
test("Heroic raid blocked without exception", "raid", 15, false, false, true, false)
test("Normal raid blocked", "raid", 14, false, false, false, false)
test("Normal raid blocked with exceptions", "raid", 14, false, true, true, false)
test("LFR blocked", "raid", 17, false, true, true, false)
test("Mythic 0 blocked", "party", 23, false, false, false, false)
test("Mythic 0 blocked with M+ exception", "party", 23, false, false, true, false)
test("Mythic+ blocked by default", "party", 8, true, false, false, false)
test("Mythic+ allowed by exception", "party", 8, true, false, true, true)
test("M+ setting without challenge mode blocked", "party", 8, false, false, true, false)
test("Heroic setting cannot enable M+", "party", 8, true, true, false, false)
test("Scenario blocked", "scenario", 0, false, true, true, false)
test("Delve-like scenario blocked", "scenario", 208, false, true, true, false)
test("Unknown instance type blocked", "arena", 16, false, true, true, false)

local feature2 = {}
ManaTools.DB.Feature2 = feature2
db.allowHeroicRaid = true
db.allowMythicPlus = false
mock.setContent("raid", 15, false)
assertTrue(NoWasteCoin.IsAllowedContent(), "heroic setting enables heroic raid")
assertTrue(ManaTools.DB.Feature2 == feature2, "heroic setting does not replace other DB branches")
mock.setContent("party", 8, true)
assertFalse(NoWasteCoin.IsAllowedContent(), "heroic setting does not enable Mythic+")
db.allowHeroicRaid = false
db.allowMythicPlus = true
mock.setContent("raid", 15, false)
assertFalse(NoWasteCoin.IsAllowedContent(), "Mythic+ setting does not enable heroic raid")
assertTrue(ManaTools.DB.Feature2 == feature2, "Mythic+ setting does not replace other DB branches")

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
BonusRollFrame = { RollButton = nil }
assertEqual(NoWasteCoin.Update(), nil, "missing RollButton update is safe")

print(string.format("ManaTools tests passed: %d/%d", passed, total))
