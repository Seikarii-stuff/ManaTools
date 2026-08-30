-- Minimal WoW API mock used by the ManaTools tests.

IsInInstance = function()
    return false, nil
end

GetInstanceInfo = function()
    return "Mock Instance", "none", 0
end

C_ChallengeMode = {
    IsChallengeModeActive = function()
        return false
    end,
}

C_Timer = {
    After = function(_, fn)
        if fn then fn() end
    end,
}

CreateFrame = function()
    local frame = {
        RegisterEvent = function() end,
        SetScript = function() end,
        HookScript = function() end,
        SetPoint = function() end,
        SetText = function() end,
        SetJustifyH = function() end,
        SetChecked = function() end,
    }
    frame.CreateFontString = function()
        return {
            SetPoint = function() end,
            SetText = function() end,
            SetJustifyH = function() end,
        }
    end
    return frame
end

Settings = {
    RegisterCanvasLayoutCategory = function(_, name)
        return { GetID = function() return 1 end, name = name }
    end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function() end,
}

InterfaceOptions_AddCategory = function() end
InterfaceOptionsFrame_OpenToCategory = function() end

SlashCmdList = {}
BonusRollFrame = nil
NoWasteCoinDB = {}
