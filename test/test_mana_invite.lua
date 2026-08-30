-- ManaInvite DB, trigger, guild-cache and invite lifecycle tests.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_mana_invite.lua

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

-- Central DB and defaults.
local existingDB = { ManaInvite = { enabled = true } }
local ManaTools, ManaInvite = loadAddon(existingDB)
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB points at central DB")
assert(ManaTools.DB.ManaInvite == existingDB.ManaInvite, "existing ManaInvite branch preserved")
assert(ManaTools.DB.ManaInvite.enabled == true, "existing enabled setting preserved")

ManaTools, ManaInvite = loadAddon({})
assert(ManaTools.DB.ManaInvite ~= nil, "ManaInvite DB branch exists")
assert(ManaTools.DB.ManaInvite.enabled == false, "ManaInvite defaults to disabled")

local db = ManaTools.DB.ManaInvite
local bootstrapDB = ManaToolsDB
db.enabled = true
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
assert(ManaTools.DB == bootstrapDB, "Bootstrap is idempotent")
assert(ManaTools.DB.ManaInvite.enabled == true, "Bootstrap preserves ManaInvite setting")

-- Initialize is idempotent and does not duplicate the roster listener.
local rosterListeners = #mock.events.GUILD_ROSTER_UPDATE
ManaInvite:Initialize()
ManaInvite:Initialize()
assert(#mock.events.GUILD_ROSTER_UPDATE == rosterListeners, "repeated Initialize does not duplicate roster listener")

-- Guild cache uses wipe + rebuild and supports Retail's name-realm format.
mock.setGuildMembers("GuildOne-Realm", "GuildTwo-OtherRealm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(ManaInvite.IsGuildMember("GuildOne-Realm"), "guild member cached")
assert(ManaInvite.IsGuildMember("guildone-realm"), "guild lookup is case insensitive")
assert(ManaInvite.IsGuildMember("GuildTwo-OtherRealm"), "cross-realm guild member cached")

mock.setGuildMembers("Fresh-Realm")
mock.fireEvent("GUILD_ROSTER_UPDATE")
assert(ManaInvite.IsGuildMember("Fresh-Realm"), "new guild member cached")
assert(not ManaInvite.IsGuildMember("GuildOne-Realm"), "stale guild member removed")
assert(not ManaInvite.IsGuildMember("GuildTwo-OtherRealm"), "old cross-realm member removed")

-- Disabled: whisper event is not registered.
db.enabled = false
ManaInvite:UpdateEvents()
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event absent while disabled")
mock.clearInvites()
mock.fireEvent("CHAT_MSG_WHISPER", "mana", "Fresh-Realm")
assert(#mock.invites == 0, "disabled feature ignores whisper")

-- Enabled: event registers exactly once and exact trigger variants work.
db.enabled = true
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
assert(ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event registered while enabled")

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

-- Disabling again unregisters immediately and remains idempotent.
db.enabled = false
ManaInvite:UpdateEvents()
ManaInvite:UpdateEvents()
assert(not ManaInvite.eventFrame:IsEventRegistered("CHAT_MSG_WHISPER"), "whisper event removed after disable")

print("ManaInvite tests passed")
