-- ManaInvite DB, trigger, guild-cache and invite lifecycle tests.
-- Requires Lua 5.1+.

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

local function loadAddon(db)
    mock.reset(db)
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    ManaTools = namespace
    loadFile("ManaInvite/ManaInvite.lua", "ManaTools", ManaTools)
    return namespace, namespace.ManaInvite
end

local existingDB = { ManaInvite = { enabled = true } }
local ManaTools, ManaInvite = loadAddon(existingDB)
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB points at central DB")
assert(ManaTools.DB.ManaInvite == existingDB.ManaInvite, "existing ManaInvite branch preserved")
assert(ManaTools.DB.ManaInvite.enabled == true, "existing enabled setting preserved")
assert(ManaTools.ManaInvite == ManaInvite, "feature namespace exposed")
assert(ManaTools.ManaInviteDB == nil, "legacy ManaInviteDB global is absent")

ManaTools, ManaInvite = loadAddon({})
assert(ManaTools.DB.ManaInvite ~= nil, "ManaInvite DB branch exists")
assert(ManaTools.DB.ManaInvite.enabled == false, "ManaInvite defaults to disabled")
assert(ManaTools.ManaInviteDB == nil, "legacy ManaInviteDB is absent")

local db = ManaTools.DB.ManaInvite
local bootstrapDB = ManaToolsDB
db.enabled = true
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
assert(ManaTools.DB == bootstrapDB, "Bootstrap is idempotent")
assert(ManaTools.DB.ManaInvite.enabled == true, "Bootstrap preserves ManaInvite setting")

-- OFF is completely dormant: neither feature event is registered.
db.enabled = false
ManaInvite:UpdateEvents()
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event absent while disabled")
assert(not ManaInvite.eventFrame:IsEventRegistered("GUILD_ROSTER_UPDATE"), "roster event absent while disabled")

-- Roster changes while OFF are not processed.
mock.setGuildMembers("A-Realm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(not ManaInvite.IsGuildMember("A-Realm"), "disabled feature does not rebuild cache")

-- OFF -> ON rebuilds immediately from the current roster.
mock.setGuildMembers("B-Realm")
db.enabled = true
ManaInvite:UpdateEvents()
assert(ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event registered while enabled")
assert(ManaInvite.eventFrame:IsEventRegistered("GUILD_ROSTER_UPDATE"), "roster event registered while enabled")
assert(ManaInvite.IsGuildMember("B-Realm"), "activation immediately rebuilds current roster")
assert(not ManaInvite.IsGuildMember("A-Realm"), "activation cache does not retain stale roster")

-- ON is idempotent and does not duplicate listeners or rebuild unnecessarily.
local whisperListeners = #mock.events.CHAT_MSG_WHISPER
local rosterListeners = #mock.events.GUILD_ROSTER_UPDATE
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
assert(#mock.events.CHAT_MSG_WHISPER == whisperListeners, "repeated ON does not duplicate whisper listener")
assert(#mock.events.GUILD_ROSTER_UPDATE == rosterListeners, "repeated ON does not duplicate roster listener")

-- GUILD_ROSTER_UPDATE rebuilds with wipe + rebuild.
mock.setGuildMembers("Fresh-Realm", "Second-Realm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(ManaInvite.IsGuildMember("Fresh-Realm"), "new guild member cached")
assert(ManaInvite.IsGuildMember("Second-Realm"), "second guild member cached")
assert(not ManaInvite.IsGuildMember("B-Realm"), "stale guild member removed")

local accepted = { "mana", "Mana", "MANA", "MaNa", " mana " }
for _, message in ipairs(accepted) do
    mock.clearInvites()
    mock.fireEvent("CHAT_MSG_WHISPER", message, "Fresh-Realm")
    assert(#mock.invites == 1, "accepted trigger invites exactly once: " .. message)
    assert(mock.invites[1] == "Fresh-Realm", "invite uses whisper sender")
end

local rejected = { "mana pls", "give mana", "mana?", "manana", "my mana", "mana please", "" }
for _, message in ipairs(rejected) do
    mock.clearInvites()
    mock.fireEvent("CHAT_MSG_WHISPER", message, "Fresh-Realm")
    assert(#mock.invites == 0, "rejected trigger does not invite: " .. message)
end

mock.clearInvites()
mock.fireEvent("CHAT_MSG_WHISPER", "mana", "NotGuild-Realm")
assert(#mock.invites == 0, "non-guild member is never invited")

db.enabled = false
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event removed after disable")
assert(not ManaInvite.eventFrame:IsEventRegistered("GUILD_ROSTER_UPDATE"), "roster event removed after disable")

print("ManaInvite tests passed")
