-- CinematicSkip DB, lifecycle, hot-path and defensive behavior tests.
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
    loadFile("CinematicSkip/cinematicskip.lua", "ManaTools", ManaTools)
    return namespace, namespace.CinematicSkip
end

local emptyDB = {}
local ManaTools, CinematicSkip = loadAddon(emptyDB)
assert(ManaTools.DB == ManaToolsDB, "ManaTools.DB points at central DB")
assert(ManaTools.DB.CinematicSkip ~= nil, "CinematicSkip DB branch exists")
assert(ManaTools.DB.CinematicSkip.enabled == true, "CinematicSkip defaults to enabled")
assert(ManaTools.CinematicSkip == CinematicSkip, "feature namespace exposed")
assert(ManaTools.CinematicSkipDB == nil, "legacy CinematicSkipDB global is absent")

local disabledDB = { CinematicSkip = { enabled = false } }
ManaTools, CinematicSkip = loadAddon(disabledDB)
assert(ManaTools.DB.CinematicSkip == disabledDB.CinematicSkip, "existing CinematicSkip branch preserved")
assert(ManaTools.DB.CinematicSkip.enabled == false, "existing disabled setting preserved")
assert(ManaTools.CinematicSkipDB == nil, "legacy CinematicSkipDB remains absent")

local enabledDB = { CinematicSkip = { enabled = true } }
ManaTools, CinematicSkip = loadAddon(enabledDB)
assert(ManaTools.DB.CinematicSkip == enabledDB.CinematicSkip, "existing enabled branch preserved")
assert(ManaTools.DB.CinematicSkip.enabled == true, "existing enabled setting preserved")

local bootstrapDB = ManaToolsDB
local branch = ManaTools.DB.CinematicSkip
branch.enabled = false
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
assert(ManaTools.DB == bootstrapDB, "Bootstrap is idempotent")
assert(ManaTools.DB.CinematicSkip == branch, "Bootstrap preserves CinematicSkip branch")
assert(ManaTools.DB.CinematicSkip.enabled == false, "Bootstrap preserves disabled setting")

local db = ManaTools.DB.CinematicSkip
db.enabled = true
CinematicSkip:UpdateEvents()
assert(CinematicSkip.eventFrame:IsEventRegistered("CINEMATIC_START"), "cinematic event registered while enabled")
assert(CinematicSkip.eventFrame:IsEventRegistered("PLAY_MOVIE"), "movie event registered while enabled")
assert(CinematicSkip.eventFrame:IsEventRegistered("TALKINGHEAD_REQUESTED"), "talking head event registered while enabled")

local cinematicListeners = #mock.events.CINEMATIC_START
local movieListeners = #mock.events.PLAY_MOVIE
local talkingHeadListeners = #mock.events.TALKINGHEAD_REQUESTED
CinematicSkip:UpdateEvents()
CinematicSkip:UpdateEvents()
CinematicSkip:UpdateEvents()
assert(#mock.events.CINEMATIC_START == cinematicListeners, "repeated ON does not duplicate cinematic listener")
assert(#mock.events.PLAY_MOVIE == movieListeners, "repeated ON does not duplicate movie listener")
assert(#mock.events.TALKINGHEAD_REQUESTED == talkingHeadListeners, "repeated ON does not duplicate talking head listener")

local cancelCalls = 0
CinematicFrame_CancelCinematic = function() cancelCalls = cancelCalls + 1 end
local movieFrame = CreateFrame("Frame")
local talkingHeadFrame = CreateFrame("Frame")
MovieFrame = movieFrame
TalkingHeadFrame = talkingHeadFrame
movieFrame:Show()
talkingHeadFrame:Show()

mock.fireEvent("CINEMATIC_START")
assert(cancelCalls == 1, "enabled cinematic event cancels exactly once")
mock.fireEvent("PLAY_MOVIE")
assert(not movieFrame:IsShown(), "enabled movie event hides MovieFrame")
mock.fireEvent("TALKINGHEAD_REQUESTED")
assert(not talkingHeadFrame:IsShown(), "enabled talking head event hides TalkingHeadFrame")

-- OFF is completely dormant and removes all listeners.
db.enabled = false
CinematicSkip:UpdateEvents()
assert(not CinematicSkip.eventFrame:IsEventRegistered("CINEMATIC_START"), "cinematic event absent while disabled")
assert(not CinematicSkip.eventFrame:IsEventRegistered("PLAY_MOVIE"), "movie event absent while disabled")
assert(not CinematicSkip.eventFrame:IsEventRegistered("TALKINGHEAD_REQUESTED"), "talking head event absent while disabled")

cancelCalls = 0
movieFrame:Show()
talkingHeadFrame:Show()
mock.fireEvent("CINEMATIC_START")
mock.fireEvent("PLAY_MOVIE")
mock.fireEvent("TALKINGHEAD_REQUESTED")
assert(cancelCalls == 0, "disabled cinematic event does nothing")
assert(movieFrame:IsShown(), "disabled movie event leaves MovieFrame untouched")
assert(talkingHeadFrame:IsShown(), "disabled talking head event leaves TalkingHeadFrame untouched")

-- OFF -> ON restores listeners.
db.enabled = true
CinematicSkip:UpdateEvents()
assert(CinematicSkip.eventFrame:IsEventRegistered("CINEMATIC_START"), "cinematic event restored after re-enable")
assert(CinematicSkip.eventFrame:IsEventRegistered("PLAY_MOVIE"), "movie event restored after re-enable")
assert(CinematicSkip.eventFrame:IsEventRegistered("TALKINGHEAD_REQUESTED"), "talking head event restored after re-enable")

-- Defensive API/frame checks.
CinematicFrame_CancelCinematic = nil
MovieFrame = nil
TalkingHeadFrame = nil
assert(pcall(function() mock.fireEvent("CINEMATIC_START") end), "missing cinematic API does not error")
assert(pcall(function() mock.fireEvent("PLAY_MOVIE") end), "missing MovieFrame does not error")
assert(pcall(function() mock.fireEvent("TALKINGHEAD_REQUESTED") end), "missing TalkingHeadFrame does not error")

print("CinematicSkip tests passed")
