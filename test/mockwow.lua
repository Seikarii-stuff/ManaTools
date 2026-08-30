-- Minimal stateful WoW API mock used by the ManaTools test suite.

local MockWoW = {}

function MockWoW.reset()
    NoWasteCoinDB = { allowHeroicRaid = false, allowMythicPlus = false }
    MockWoW.inInstance = false
    MockWoW.instanceType = nil
    MockWoW.difficultyID = 0
    MockWoW.challengeActive = false

    IsInInstance = function() return MockWoW.inInstance, MockWoW.instanceType end
    GetInstanceInfo = function() return "Mock Instance", MockWoW.instanceType or "none", MockWoW.difficultyID end
    C_ChallengeMode = { IsChallengeModeActive = function() return MockWoW.challengeActive end }
    C_Timer = { After = function(_, callback) if callback then callback() end end }
    SlashCmdList = {}
    Settings = {
        RegisterCanvasLayoutCategory = function(_, name) return { GetID = function() return 1 end, name = name } end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function() end,
    }
    InterfaceOptions_AddCategory = function() end
    InterfaceOptionsFrame_OpenToCategory = function() end

    CreateFrame = function()
        local frame = {
            RegisterEvent = function() end, SetScript = function() end, HookScript = function() end,
            SetPoint = function() end, SetText = function() end, SetJustifyH = function() end,
            SetChecked = function() end, Enable = function() end, Disable = function() end, SetAlpha = function() end,
        }
        frame.CreateFontString = function()
            return { SetPoint = function() end, SetText = function() end, SetJustifyH = function() end }
        end
        return frame
    end
    BonusRollFrame = nil
end

function MockWoW.setContent(instanceType, difficultyID, challengeActive)
    MockWoW.inInstance = true
    MockWoW.instanceType = instanceType
    MockWoW.difficultyID = difficultyID
    MockWoW.challengeActive = challengeActive == true
end

function MockWoW.setWorld()
    MockWoW.inInstance = false
    MockWoW.instanceType = nil
    MockWoW.difficultyID = 0
    MockWoW.challengeActive = false
end

MockWoW.reset()
return MockWoW
