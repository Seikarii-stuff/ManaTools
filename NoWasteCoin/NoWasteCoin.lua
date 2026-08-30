local ADDON_NAME = ...

NoWasteCoinDB = NoWasteCoinDB or {}
NoWasteCoinDB.allowHeroicRaid = NoWasteCoinDB.allowHeroicRaid or false
NoWasteCoinDB.allowMythicPlus = NoWasteCoinDB.allowMythicPlus or false

local function IsAllowedContent()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end

    local _, _, difficultyID = GetInstanceInfo()

    -- Mythic raid is always allowed.
    if instanceType == "raid" and difficultyID == 16 then
        return true
    end

    -- Heroic raid is optional.
    if instanceType == "raid" and difficultyID == 15 then
        return NoWasteCoinDB.allowHeroicRaid
    end

    -- Mythic+ is optional.
    if instanceType == "party" and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return NoWasteCoinDB.allowMythicPlus and C_ChallengeMode.IsChallengeModeActive()
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

    if not BonusRollFrame.NoWasteCoinHooked then
        BonusRollFrame.NoWasteCoinHooked = true

        BonusRollFrame:HookScript("OnShow", UpdateRollButton)
        BonusRollFrame.RollButton:HookScript("OnShow", UpdateRollButton)
    end

    UpdateRollButton()
    return true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")

eventFrame:SetScript("OnEvent", function()
    HookBonusRollUI()
end)

C_Timer.After(0, HookBonusRollUI)
C_Timer.After(1, HookBonusRollUI)

function NoWasteCoin_IsAllowedContent()
    return IsAllowedContent()
end

function NoWasteCoin_Update()
    UpdateRollButton()
end
