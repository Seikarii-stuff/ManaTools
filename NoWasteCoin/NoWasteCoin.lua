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
local visualHookedButton
local wrappedOnClicks = setmetatable({}, { __mode = "k" })
local bonusRollStartHooked = false
local currentRollOverride = false
local currentRollFrame

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

local function IsCurrentRollOverrideActive()
    return currentRollOverride and currentRollFrame == BonusRollFrame and BonusRollFrame ~= nil
end

local function ClearCurrentRollOverride()
    currentRollOverride = false
    currentRollFrame = nil
end

local function GetRollButton()
    if not BonusRollFrame then
        return nil
    end

    return (BonusRollFrame.PromptFrame and BonusRollFrame.PromptFrame.RollButton)
        or BonusRollFrame.RollButton
end

local function IsBonusRollFrameActive()
    if not BonusRollFrame then
        return false
    end

    if BonusRollFrame.IsShown then
        return BonusRollFrame:IsShown()
    end

    return true
end

local function UpdateRollButton()
    local button = GetRollButton()
    if not button then
        return
    end

    local allowed = IsCurrentRollOverrideActive() or IsAllowedContent()

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

local function HookRollButton(button)
    if not button or not button.GetScript or not button.SetScript then
        return false
    end

    local currentOnClick = button:GetScript("OnClick")
    local wrappedOnClick = wrappedOnClicks[button]

    if currentOnClick ~= wrappedOnClick then
        local originalOnClick = currentOnClick
        wrappedOnClick = function(self, ...)
            -- This remains the actual spending barrier. The temporary override
            -- only replaces the content decision for the currently open roll.
            if IsCurrentRollOverrideActive() then
                ClearCurrentRollOverride()
                UpdateRollButton()
                if originalOnClick then
                    return originalOnClick(self, ...)
                end
                return
            end

            if not IsAllowedContent() then
                return
            end

            if originalOnClick then
                return originalOnClick(self, ...)
            end
        end
        wrappedOnClicks[button] = wrappedOnClick
        button:SetScript("OnClick", wrappedOnClick)
    end

    hookedButton = button
    return true
end

local function HookBonusRollUI()
    local button = GetRollButton()
    if not button then
        return false
    end

    if hookedFrame ~= BonusRollFrame then
        hookedFrame = BonusRollFrame
        BonusRollFrame:HookScript("OnShow", function()
            HookBonusRollUI()
        end)
        BonusRollFrame:HookScript("OnHide", function(self)
            if currentRollFrame == self then
                ClearCurrentRollOverride()
            end
            UpdateRollButton()
        end)
    end

    HookRollButton(button)

    if visualHookedButton ~= button then
        visualHookedButton = button
        button:HookScript("OnShow", UpdateRollButton)
        button:HookScript("OnEnable", function(self)
            if not IsCurrentRollOverrideActive() and not IsAllowedContent() then
                self:Disable()
                self:SetAlpha(0.4)
                self.tooltipText = "NoWasteCoin: Bonus Roll disabled here."
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

    hooksecurefunc("BonusRollFrame_StartBonusRoll", function(...)
        ClearCurrentRollOverride()
        HookBonusRollUI(...)
    end)
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

function NoWasteCoin.EnableCurrentRollOverride()
    if not IsBonusRollFrameActive() then
        return false
    end

    currentRollFrame = BonusRollFrame
    currentRollOverride = true
    HookBonusRollUI()
    UpdateRollButton()
    return true
end

function NoWasteCoin.ClearCurrentRollOverride()
    ClearCurrentRollOverride()
    UpdateRollButton()
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
