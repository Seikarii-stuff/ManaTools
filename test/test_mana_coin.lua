-- ManaTools /coin temporary Bonus Roll override test suite.
local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

mock.reset()
local ManaTools = {}
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", ManaTools)
loadFile("SlashCmd.lua", "ManaTools", ManaTools)

local NoWasteCoin = ManaTools.NoWasteCoin
local slashOutput = {}
local originalPrint = print
print = function(message) table.insert(slashOutput, message) end

local function assertEqual(actual, expected, name)
    if actual ~= expected then
        error(string.format("FAIL: %s (expected %s, got %s)", name, tostring(expected), tostring(actual)), 0)
    end
end
local function assertTrue(value, name) assertEqual(value, true, name) end
local function assertFalse(value, name) assertEqual(value, false, name) end

-- No active Bonus Roll: command reports the error and leaves the override off.
BonusRollFrame = nil
SlashCmdList.MANACOIN()
assertEqual(slashOutput[#slashOutput], "ManaTools: No hay ninguna Bonus Roll activa.", "inactive /coin error message")

local frame = mock.newBonusRollFrame(true)
local originalClickCount = 0
frame.PromptFrame.RollButton:SetScript("OnClick", function()
    originalClickCount = originalClickCount + 1
end)
BonusRollFrame = frame
mock.defineBonusRollStart()
mock.fireEvent("ADDON_LOADED", "Blizzard_BonusRoll")
mock.startBonusRoll()

-- Tooltip reminder appears when Bonus Roll open and override not active.
-- After startBonusRoll the reminder should be present.
assertEqual(frame.PromptFrame.RollButton.tooltipText, "Usa /coin para habilitar.", "tooltip reminds to use /coin before override")

-- Basic override: /coin should report success when a Bonus Roll is active.
SlashCmdList.MANACOIN()
assertEqual(slashOutput[#slashOutput], "ManaTools: Bonus Roll desbloqueada para esta tirada.", "successful /coin message")
assertTrue(NoWasteCoin.EnableCurrentRollOverride(), "EnableCurrentRollOverride returns true when frame active")

-- Clicking should execute the original callback.
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "click executes original callback")

-- After consuming the override, the tooltip should return to the reminder when frame still active.
assertEqual(frame.PromptFrame.RollButton.tooltipText, "Usa /coin para habilitar.", "tooltip reminder restored after override consumed")

-- Clicking again still executes original (no blocking behavior remains).
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 2, "second click executes original callback")

print = originalPrint
print("ManaTools /coin tests passed: basic scenarios")
