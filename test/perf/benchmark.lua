-- ManaTools benchmark suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/perf/benchmark.lua [iterations]
-- Always overwrites: test/results/benchmark.txt

local requestedIterations = tonumber(arg[1]) or 100000
local iterations = requestedIterations or 100000
local warmup = math.max(500, math.floor(iterations / 10))

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

ManaToolsDB = {}
local addonNamespace = {}
loadFile("Bootstrap.lua", "ManaTools", addonNamespace)
ManaTools = addonNamespace
loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", ManaTools)
loadFile("CinematicSkip/cinematicskip.lua", "ManaTools", ManaTools)
loadFile("NoInfo/NoInfo.lua", "ManaTools", ManaTools)
loadFile("ChatCopy/ChatCopy.lua", "ManaTools", ManaTools)
loadFile("Permalogging/Permalogging.lua", "ManaTools", ManaTools)
loadFile("QueueAutoAccept/AutoInvite.lua", "ManaTools", ManaTools)
loadFile("QueueAutoAccept/QueueAutoAccept.lua", "ManaTools", ManaTools)

local NoWasteCoin = ManaTools.NoWasteCoin
local CinematicSkip = ManaTools.CinematicSkip
local NoInfo = ManaTools.NoInfo
local ChatCopy = ManaTools.ChatCopy
local Permalogging = ManaTools.Permalogging
local QueueAutoAccept = ManaTools.QueueAutoAccept
local AutoInvite = QueueAutoAccept.AutoInvite
local cinematicSkipDB = ManaTools.DB.CinematicSkip
local chatCopyDB = ManaTools.DB.ChatCopy
local noInfoDB = ManaTools.DB.NoInfo
local queueAutoAcceptDB = ManaTools.DB.QueueAutoAccept
local permaloggingDB = ManaTools.DB.Permalogging

local function runTimed(fn, count)
    local start = os.clock()
    fn(count)
    return os.clock() - start
end

local function appendMetric(results, name, elapsed, count)
    local rate = elapsed > 0 and count / elapsed or math.huge
    results[#results + 1] = string.format("%-38s %10.6f s  %12.0f calls/s  %12.3f us/call", name, elapsed, rate, elapsed * 1000000 / count)
end

local results = {
    "ManaTools benchmark results",
    "===========================",
    "Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC"),
    string.format("Iterations per hot path: %d", iterations),
    string.format("Warmup per hot path: %d", warmup),
    "",
}

results[#results + 1] = ""
results[#results + 1] = "NoWasteCoin benchmarks"
results[#results + 1] = "----------------------"

local function benchmarkNoWasteCoinOverride()
    BonusRollFrame = mock.newBonusRollFrame(true)
    BonusRollFrame.IsShown = function(self)
        return self.shown ~= false
    end
    BonusRollFrame.shown = true
    NoWasteCoin.ClearCurrentRollOverride()
    for _ = 1, warmup do NoWasteCoin.EnableCurrentRollOverride() end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            NoWasteCoin.ClearCurrentRollOverride()
            NoWasteCoin.EnableCurrentRollOverride()
        end
    end, iterations)

    BonusRollFrame = nil
    return elapsed
end

appendMetric(results, "NoWasteCoin ENABLE_CURRENT_ROLL_OVERRIDE", benchmarkNoWasteCoinOverride(), iterations)

results[#results + 1] = ""
results[#results + 1] = "CinematicSkip benchmarks"
results[#results + 1] = "------------------------"

local function benchmarkCinematicStart()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    local calls = 0
    CinematicFrame_CancelCinematic = function() calls = calls + 1 end
    for _ = 1, warmup do mock.fireEvent("CINEMATIC_START") end
    calls = 0
    local elapsed = runTimed(function(count)
        for _ = 1, count do mock.fireEvent("CINEMATIC_START") end
    end, iterations)
    CinematicFrame_CancelCinematic = nil
    return elapsed
end

local function benchmarkPlayMovie()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    MovieFrame = CreateFrame("Frame")
    for _ = 1, warmup do MovieFrame:Show(); mock.fireEvent("PLAY_MOVIE") end
    local elapsed = runTimed(function(count)
        for _ = 1, count do MovieFrame:Show(); mock.fireEvent("PLAY_MOVIE") end
    end, iterations)
    MovieFrame = nil
    return elapsed
end

local function benchmarkTalkingHead()
    cinematicSkipDB.enabled = true
    CinematicSkip:UpdateEvents()
    TalkingHeadFrame = CreateFrame("Frame")
    for _ = 1, warmup do TalkingHeadFrame:Show(); mock.fireEvent("TALKINGHEAD_REQUESTED") end
    local elapsed = runTimed(function(count)
        for _ = 1, count do TalkingHeadFrame:Show(); mock.fireEvent("TALKINGHEAD_REQUESTED") end
    end, iterations)
    TalkingHeadFrame = nil
    return elapsed
end

appendMetric(results, "CINEMATIC_START", benchmarkCinematicStart(), iterations)
appendMetric(results, "PLAY_MOVIE", benchmarkPlayMovie(), iterations)
appendMetric(results, "TALKINGHEAD_REQUESTED", benchmarkTalkingHead(), iterations)

results[#results + 1] = ""
results[#results + 1] = "ChatCopy benchmarks"
results[#results + 1] = "-------------------"

local function benchmarkChatCopyBuildText()
    local total = 200
    local messages = {}
    for i = 1, total do
        messages[i] = "chat line " .. i .. " lorem ipsum dolor sit amet consectetur adipiscing elit"
    end

    local chatFrame = CreateFrame("Frame", "ChatFrame1")
    function chatFrame:GetNumMessages() return total end
    function chatFrame:GetMessageInfo(index)
        return messages[index]
    end
    _G.ChatFrame1 = chatFrame
    _G.DEFAULT_CHAT_FRAME = chatFrame

    chatCopyDB.enabled = true
    ChatCopy:Update()
    for _ = 1, warmup do ChatCopy:BuildTextFromGeneral() end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            ChatCopy:BuildTextFromGeneral()
        end
    end, iterations)

    return elapsed
end

local function benchmarkChatCopyOpenPopup()
    local total = 200
    local messages = {}
    for i = 1, total do
        messages[i] = "copy line " .. i .. " vel pretium nisl suspendisse at ultrices urna"
    end

    local chatFrame = CreateFrame("Frame", "ChatFrame1")
    function chatFrame:GetNumMessages() return total end
    function chatFrame:GetMessageInfo(index)
        return messages[index]
    end
    _G.ChatFrame1 = chatFrame
    _G.DEFAULT_CHAT_FRAME = chatFrame

    chatCopyDB.enabled = true
    ChatCopy:Update()
    for _ = 1, warmup do
        ChatCopy:OpenPopup()
        if ChatCopy.popup and ChatCopy.popup.Hide then
            ChatCopy.popup:Hide()
        end
    end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            ChatCopy:OpenPopup()
            if ChatCopy.popup and ChatCopy.popup.Hide then
                ChatCopy.popup:Hide()
            end
        end
    end, iterations)

    return elapsed
end

appendMetric(results, "ChatCopy BUILD_TEXT_FROM_GENERAL", benchmarkChatCopyBuildText(), iterations)
appendMetric(results, "ChatCopy OPEN_POPUP", benchmarkChatCopyOpenPopup(), iterations)

results[#results + 1] = ""
results[#results + 1] = "NoInfo benchmarks"
results[#results + 1] = "----------------"

GameTooltip = CreateFrame("GameTooltip")
local originalTooltipOnShow = function() end
GameTooltip:SetScript("OnShow", originalTooltipOnShow)
function GameTooltip:GetTooltipData() return self.tooltipData end
function GameTooltip:GetOwner() return self.tooltipOwner end
Minimap = CreateFrame("Frame")
MainMenuMicroButton = CreateFrame("Button")
UIParent = CreateFrame("Frame")
Enum = { TooltipDataType = { Item = 0 } }

local itemData = { type = Enum.TooltipDataType.Item }
local genericData = { type = 999 }

local function benchmarkNoInfoState(name, enabled, inspectMode, data, owner)
    noInfoDB.enabled = enabled
    noInfoDB.inspectMode = inspectMode
    GameTooltip.tooltipData = data
    GameTooltip.tooltipOwner = owner
    NoInfo.Update()
    local handler = GameTooltip:GetScript("OnShow")
    assert(handler == originalTooltipOnShow, "NoInfo benchmark must keep the original OnShow intact: " .. name)
    for _ = 1, warmup do GameTooltip:TriggerScript("OnShow") end
    local elapsed = runTimed(function(count)
        for _ = 1, count do GameTooltip:TriggerScript("OnShow") end
    end, iterations)
    appendMetric(results, name, elapsed, iterations)
end

benchmarkNoInfoState("NoInfo OFF", true, 0, genericData, nil)
benchmarkNoInfoState("NoInfo normal inspection", true, 1, genericData, nil)
benchmarkNoInfoState("NoInfo inspection + rating", true, 2, genericData, nil)

noInfoDB.enabled = false
noInfoDB.inspectMode = 0
NoInfo.Update()
local disabledHandler = GameTooltip:GetScript("OnShow")
assert(disabledHandler == originalTooltipOnShow, "NoInfo disabled path must leave the Blizzard OnShow unchanged")
for _ = 1, warmup do disabledHandler(GameTooltip) end
appendMetric(results, "NoInfo disabled: original OnShow", runTimed(function(count)
    for _ = 1, count do disabledHandler(GameTooltip) end
end, iterations), iterations)

results[#results + 1] = ""
results[#results + 1] = "QueueAutoAccept benchmarks"
results[#results + 1] = "-------------------------"

local function benchmarkQueueAutoAcceptInvite()
    queueAutoAcceptDB.enabled = true
    local function makeRoleButton()
        local button = CreateFrame("Button")
        button.checkButton = button
        function button:SetChecked(value) self.checked = value end
        function button:GetChecked() return self.checked end
        return button
    end

    _G.LFGInvitePopupRoleButtonTank = { checkButton = makeRoleButton() }
    _G.LFGInvitePopupRoleButtonHealer = { checkButton = makeRoleButton() }
    _G.LFGInvitePopupRoleButtonDPS = { checkButton = makeRoleButton() }
    GetSpecialization = function() return 1 end
    GetSpecializationRole = function() return "HEALER" end
    AcceptGroup = function() end

    for _ = 1, warmup do AutoInvite:AcceptPartyInvite(nil, nil, nil) end
    local elapsed = runTimed(function(count)
        for _ = 1, count do
            AutoInvite:AcceptPartyInvite(nil, nil, nil)
        end
    end, iterations)
    return elapsed
end

appendMetric(results, "QueueAutoAccept ACCEPT_PARTY_INVITE", benchmarkQueueAutoAcceptInvite(), iterations)

results[#results + 1] = ""
results[#results + 1] = "Permalogging benchmarks"
results[#results + 1] = "----------------------"

local function benchmarkPermaloggingUpdate()
    local originalPrint = print
    local originalLoggingCombat = _G.LoggingCombat
    local originalIsInInstance = _G.IsInInstance
    print = function() end
    _G.IsInInstance = function() return true, "party" end
    _G.LoggingCombat = function(force)
        if force == true then
            return true
        end
        return false
    end

    permaloggingDB.enabled = true
    for _ = 1, warmup do
        Permalogging:Disable()
        Permalogging:Enable()
    end

    local elapsed = runTimed(function(count)
        for _ = 1, count do
            Permalogging:Disable()
            Permalogging:Enable()
        end
    end, iterations)

    print = originalPrint
    _G.IsInInstance = originalIsInInstance
    _G.LoggingCombat = originalLoggingCombat
    return elapsed
end

appendMetric(results, "Permalogging UPDATE", benchmarkPermaloggingUpdate(), iterations)

results[#results + 1] = ""
results[#results + 1] = "Allocations: NOT AVAILABLE (Lua benchmark environment does not expose a reliable per-call allocation metric)."
results[#results + 1] = "Generated by test/perf/benchmark.lua"

local output = assert(io.open("test/results/benchmark.txt", "w"))
output:write(table.concat(results, "\n"), "\n")
output:close()

print(table.concat(results, "\n"))
print("Benchmark results written to test/results/benchmark.txt")
