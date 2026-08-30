-- Stateful WoW API mock used by the ManaTools test suite.

local MockWoW = {
    events = {},
}

local function newFrame()
    local frame = {
        hooks = {},
        enabled = true,
        alpha = 1,
        tooltipText = nil,
    }

    function frame:RegisterEvent(event)
        MockWoW.events[event] = MockWoW.events[event] or {}
        table.insert(MockWoW.events[event], self)
    end

    function frame:SetScript(script, callback)
        self.scripts = self.scripts or {}
        self.scripts[script] = callback
    end

    function frame:HookScript(script, callback)
        self.hooks[script] = self.hooks[script] or {}
        table.insert(self.hooks[script], callback)
    end

    function frame:TriggerScript(script, ...)
        local callback = self.scripts and self.scripts[script]
        if callback then
            callback(self, ...)
        end
        for _, hook in ipairs(self.hooks[script] or {}) do
            hook(self, ...)
        end
    end

    function frame:SetPoint() end
    function frame:SetText() end
    function frame:SetJustifyH() end
    function frame:SetChecked(value) self.checked = value end
    function frame:GetChecked() return self.checked end
    function frame:Enable() self.enabled = true end
    function frame:Disable() self.enabled = false end
    function frame:SetAlpha(value) self.alpha = value end

    function frame:CreateFontString()
        return newFrame()
    end

    return frame
end

function MockWoW.reset(db)
    ManaToolsDB = db or {}
    MockWoW.events = {}
    MockWoW.inInstance = false
    MockWoW.instanceType = nil
    MockWoW.difficultyID = 0
    MockWoW.challengeActive = false

    IsInInstance = function() return MockWoW.inInstance, MockWoW.instanceType end
    GetInstanceInfo = function() return "Mock Instance", MockWoW.instanceType or "none", MockWoW.difficultyID end
    C_ChallengeMode = { IsChallengeModeActive = function() return MockWoW.challengeActive end }
    SlashCmdList = {}
    Settings = {
        RegisterCanvasLayoutCategory = function(_, name) return { GetID = function() return 1 end, name = name } end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function() end,
    }
    InterfaceOptions_AddCategory = function() end
    InterfaceOptionsFrame_OpenToCategory = function() end

    CreateFrame = function()
        return newFrame()
    end
    BonusRollFrame = nil
end

function MockWoW.newBonusRollFrame()
    local frame = newFrame()
    frame.RollButton = newFrame()
    return frame
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

function MockWoW.fireEvent(event, ...)
    for _, frame in ipairs(MockWoW.events[event] or {}) do
        local callback = frame.scripts and frame.scripts.OnEvent
        if callback then
            callback(frame, event, ...)
        end
    end
end

MockWoW.reset()
return MockWoW
