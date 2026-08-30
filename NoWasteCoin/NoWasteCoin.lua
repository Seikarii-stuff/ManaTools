local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoWasteCoin
if db.allowHeroicRaid == nil then
    db.allowHeroicRaid = false
end
if db.allowMythicPlus == nil then
    db.allowMythicPlus = false
end

local NoWasteCoin = ManaTools.NoWasteCoin
local hookedFrame
local hookedButton
local bonusRollStartHooked = false

local function IsAllowedContent()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end

    local _, _, difficultyID = GetInstanceInfo()

    if instanceType == "raid" and difficultyID == 16 then
        return true
    end

    if instanceType == "raid" and difficultyID == 15 then
        return db.allowHeroicRaid == true
    end

    if instanceType == "party" and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return db.allowMythicPlus == true and C_ChallengeMode.IsChallengeModeActive()
    end

    return false
end

local function GetRollButton()
    if not BonusRollFrame then
        return nil
    end

    return (BonusRollFrame.PromptFrame and BonusRollFrame.PromptFrame.RollButton)
        or BonusRollFrame.RollButton
end

local function UpdateRollButton()
    local button = GetRollButton()
    if not button then
        return
    end

    local allowed = IsAllowedContent()

    if allowed then
        button:Enable()
        button:SetAlpha(1)
        button.tooltipText = nil
    else
        button:Disable()
        button:SetAlpha(0.4)
        button.tooltipText = "NoWasteCoin: Bonus Roll disabled here."
    end
end

local function HookBonusRollUI()
    local button = GetRollButton()
    if not button then
        return false
    end

    if hookedFrame ~= BonusRollFrame then
        hookedFrame = BonusRollFrame
        BonusRollFrame:HookScript("OnShow", UpdateRollButton)
    end

    if hookedButton ~= button then
        hookedButton = button
        button:HookScript("OnShow", UpdateRollButton)
        button:HookScript("OnEnable", function()
            if not IsAllowedContent() then
                button:Disable()
                button:SetAlpha(0.4)
                button.tooltipText = "NoWasteCoin: Bonus Roll disabled here."
            end
        end)
    end

    UpdateRollButton()
    return true
end

local function InstallBonusRollStartHook()
    if bonusRollStartHooked or not BonusRollFrame_StartBonusRoll or not hooksecurefunc then
        return false
    end

    hooksecurefunc("BonusRollFrame_StartBonusRoll", HookBonusRollUI)
    bonusRollStartHooked = true
    return true
end

function NoWasteCoin.Initialize()
    InstallBonusRollStartHook()
    return HookBonusRollUI()
end

function NoWasteCoin.IsAllowedContent()
    return IsAllowedContent()
end

function NoWasteCoin.Update()
    return UpdateRollButton()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Blizzard_BonusRoll" then
        return
    end

    InstallBonusRollStartHook()
    HookBonusRollUI()
end)

NoWasteCoin.Initialize()
