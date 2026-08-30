local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load
local function loadFile(path, ...)
  local f = assert(io.open(path, "r")); local s = f:read("*a"); f:close(); assert(loader(s, path))(...)
end
local function assertEq(a,b,n) if a~=b then error(("FAIL: %s (expected %s, got %s)"):format(n,tostring(b),tostring(a)),0) end end
local function assertTrue(v,n) assertEq(v,true,n) end
local function assertFalse(v,n) assertEq(v,false,n) end

local db={NoWasteCoin={allowHeroicRaid=false,allowMythicPlus=false}}
mock.reset(db)
local ManaTools={}
loadFile("Bootstrap.lua","ManaTools",ManaTools)
loadFile("NoWasteCoin/NoWasteCoin.lua","ManaTools",ManaTools)
loadFile("SlashCmd.lua","ManaTools",ManaTools)
local N=ManaTools.NoWasteCoin
mock.defineBonusRollStart()
mock.fireEvent("ADDON_LOADED","Blizzard_BonusRoll")

-- Basic override: blocked Heroic becomes clickable exactly once.
local frame=mock.newBonusRollFrame(true); BonusRollFrame=frame
local clicks=0
frame.PromptFrame.RollButton:SetScript("OnClick",function() clicks=clicks+1 end)
mock.setContent("raid",15,false); mock.startBonusRoll()
assertFalse(frame.PromptFrame.RollButton.enabled,"Heroic starts blocked")
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled,"override enables button")
assertEq(frame.PromptFrame.RollButton.alpha,1,"override alpha")
assertEq(frame.PromptFrame.RollButton.tooltipText,nil,"override clears tooltip")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(clicks,1,"override click reaches original once")
assertFalse(frame.PromptFrame.RollButton.enabled,"consumed override restores blocked visual state")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(clicks,1,"second click does not reuse override")

-- No active frame: no state is changed.
BonusRollFrame=nil
SlashCmdList.MANATOOLS("coin")
assertFalse(N.EnableCurrentRollOverride(),"no active Bonus Roll rejected")

-- New Bonus Roll clears previous override.
BonusRollFrame=frame; frame:Show(); mock.setContent("raid",15,false); mock.startBonusRoll()
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled,"override active before new roll")
mock.startBonusRoll()
assertFalse(frame.PromptFrame.RollButton.enabled,"new roll clears override")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(clicks,1,"new roll does not inherit override")

-- Closing the frame clears it.
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled,"override active before close")
frame:Hide()
assertFalse(frame.PromptFrame.RollButton.enabled,"close clears override")

-- Mythic remains allowed and unaffected.
frame:Show(); mock.setContent("raid",16,false); mock.startBonusRoll()
assertTrue(frame.PromptFrame.RollButton.enabled,"Mythic remains allowed")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(clicks,2,"Mythic click still reaches original once")

-- Recreated button is wrapped for the current roll.
frame.PromptFrame.RollButton=mock.newBonusRollFrame(false).RollButton
local recreatedClicks=0
frame.PromptFrame.RollButton:SetScript("OnClick",function() recreatedClicks=recreatedClicks+1 end)
mock.setContent("raid",15,false); mock.startBonusRoll()
SlashCmdList.MANATOOLS("coin")
assertTrue(frame.PromptFrame.RollButton.enabled,"override enables recreated button")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(recreatedClicks,1,"recreated button executes original once")
frame.PromptFrame.RollButton:TriggerScript("OnClick")
assertEq(recreatedClicks,1,"recreated button override is consumed")

print("ManaTools coin override tests passed")
