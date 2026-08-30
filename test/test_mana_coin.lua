-- ManaTools /mana coin temporary Bonus Roll override test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_mana_coin.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

local db = {
    NoWasteCoin = { allowHeroicRaid = false, allowMythicPlus = false },
}
mock.reset(db)
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
SlashCmdList.MANATOOLS("coin")
assertEqual(slashOutput[#slashOutput], "ManaTools: No hay ninguna Bonus Roll activa.", "inactive /mana coin error message")

local frame = mock.newBonusRollFrame(true)
local originalClickCount = 0
frame.PromptFrame.RollButton:SetScript("OnClick", function()
    originalClickCount = originalClickCount + 1
end)
BonusRollFrame = frame
mock.defineBonusRollStart()
mock.fireEvent("ADDON_LOADED", "Blizzard_BonusRoll")
mock.setContent("raid", 15, false)
mock.startBonusRoll()

assertFalse(frame.PromptFrame.RollButton.enabled, "blocked Heroic button starts disabled")

-- Basic override: the blocked Heroic roll can be deliberately spent once.
SlashCmdList.MANATOOLS("coin")
assertEqual(slashOutput[#slashOutput], "ManaTools: Bonus Roll desbloqueada para esta tirada.", "successful /mana coin message")
assertTrue(frame.PromptFrame.RollButton.enabled, "override enables blocked Heroic button")
assertEqual(frame.PromptFrame.RollButton.alpha, 1, "override restores normal alpha")
assertEqual(frame.PromptFrame.RollButton.tooltipText, nil, "override clears blocking tooltip")

frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "override click executes original exactly once")
assertFalse(frame.PromptFrame.RollButton.enabled, "consumed override restores blocked state")
assertEqual(frame.PromptFrame.RollButton.alpha, 0.4, "consumed override restores blocked alpha")
assertEqual(frame.PromptFrame.RollButton.tooltipText, "NoWasteCoin: Bonus Roll disabled here.", "consumed override restores tooltip")

frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "second click cannot reuse override")

-- The invalid command did not arm a future roll.
frame:Hide()
frame:Show()
mock.setContent("raid", 15, false)
NoWasteCoin.Update()
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "inactive command does not arm a later roll")

-- A new Bonus Roll always invalidates the old override.
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled, "override arms current roll")
mock.startBonusRoll()
assertFalse(frame.PromptFrame.RollButton.enabled, "new Bonus Roll clears previous override")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "cleared override cannot spend new roll")

-- Closing the frame also invalidates the override.
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled, "override arms before close")
frame:Hide()
assertFalse(frame.PromptFrame.RollButton.enabled, "closing frame clears override")
frame:Show()
mock.setContent("raid", 15, false)
NoWasteCoin.Update()
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "closed-frame override cannot survive close")

-- Mythic remains governed by the existing content rules.
mock.setContent("raid", 16, false)
NoWasteCoin.Update()
assertTrue(frame.PromptFrame.RollButton.enabled, "Mythic remains allowed")
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled, "coin command does not break Mythic allowed state")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEqual(originalClickCount, 2, "Mythic click still executes original once")

-- Button replacement: /mana coin hooks the currently selected replacement button.
mock.setContent("raid", 15, false)
local replacement = mock.newBonusRollFrame(false).RollButton
local replacementClickCount = 0
replacement:SetScript("OnClick", function()
    replacementClickCount = replacementClickCount + 1
end)
frame.PromptFrame.RollButton = replacement
SlashCmdList.MANATOOLS("coin")
assertTrue(replacement.enabled, "override enables recreated current RollButton")
assertEqual(replacement.alpha, 1, "recreated button gets normal alpha")
assertEqual(replacement.tooltipText, nil, "recreated button clears tooltip")
replacement:TriggerScript("OnClick")
assertEqual(replacementClickCount, 1, "recreated button executes original once")
replacement:TriggerScript("OnClick")
assertEqual(replacementClickCount, 1, "recreated button consumes override after one click")

print = originalPrint
print("ManaTools /mana coin tests passed: 9 scenarios")
