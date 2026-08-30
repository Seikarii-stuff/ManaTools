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

local function UpdateRollButton()
    if not BonusRollFrame or not BonusRollFrame.RollButton then
        return
    end

    local allowed = IsAllowedContent()
    local button = BonusRollFrame.RollButton

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
    if not BonusRollFrame or not BonusRollFrame.RollButton then
        return false
    end

    if hookedFrame ~= BonusRollFrame then
        hookedFrame = BonusRollFrame
        BonusRollFrame:HookScript("OnShow", UpdateRollButton)
    end

    if hookedButton ~= BonusRollFrame.RollButton then
        hookedButton = BonusRollFrame.RollButton
        BonusRollFrame.RollButton:HookScript("OnShow", UpdateRollButton)
    end

    UpdateRollButton()
    return true
end

function NoWasteCoin.Initialize()
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
    HookBonusRollUI()
end)

NoWasteCoin.Initialize()
