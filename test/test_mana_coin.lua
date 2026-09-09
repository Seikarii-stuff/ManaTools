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

-- No active Bonus Roll: /coin must fail and no override is created.
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

local button = frame.PromptFrame.RollButton

-- Default-deny: no content is allowed implicitly. The button must start disabled.
assertFalse(button:IsEnabled(), "button disabled by default")
assertEqual(button:GetAlpha(), 0.4, "button dimmed by default")
assertEqual(button.tooltipText, "Usa /coin para habilitar.", "tooltip reminds to use /coin before override")

-- Clicking without /coin must not spend the Bonus Roll.
button:TriggerScript("OnClick")
assertEqual(originalClickCount, 0, "click is blocked without override")

-- Basic override: /coin should report success when a Bonus Roll is active.
SlashCmdList.MANACOIN()
assertEqual(slashOutput[#slashOutput], "ManaTools: Bonus Roll desbloqueada para esta tirada.", "successful /coin message")
assertTrue(NoWasteCoin.EnableCurrentRollOverride(), "EnableCurrentRollOverride returns true when frame active")
assertTrue(button:IsEnabled(), "button enabled after /coin")
assertEqual(button:GetAlpha(), 1, "button restored after /coin")
assertEqual(button.tooltipText, nil, "tooltip cleared after /coin")

-- The one-shot override is consumed by the first successful click.
button:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "click executes original callback with override")
assertFalse(button:IsEnabled(), "button disabled after override is consumed")
assertEqual(button:GetAlpha(), 0.4, "button dimmed after override is consumed")
assertEqual(button.tooltipText, "Usa /coin para habilitar.", "tooltip reminder restored after override consumed")

-- A second click without another /coin must remain blocked.
button:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "second click is blocked without a new override")

-- Starting a new Bonus Roll clears any previous override and returns to default-deny.
mock.startBonusRoll()
assertFalse(button:IsEnabled(), "new Bonus Roll starts disabled")
assertEqual(button.tooltipText, "Usa /coin para habilitar.", "new Bonus Roll requires /coin")
button:TriggerScript("OnClick")
assertEqual(originalClickCount, 1, "new Bonus Roll remains blocked until /coin")

print = originalPrint
print("ManaTools /coin tests passed: default-deny and one-shot override scenarios")
