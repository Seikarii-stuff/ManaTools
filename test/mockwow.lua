-- Stateful WoW API mock used by the ManaTools test suite.

local MockWoW = { events = {} }

local function newFrame()
    local frame = { hooks = {}, enabled = true, alpha = 1, tooltipText = nil, registeredEvents = {} }

    function frame:RegisterEvent(event)
        if self.registeredEvents[event] then return end
        self.registeredEvents[event] = true
        MockWoW.events[event] = MockWoW.events[event] or {}
        table.insert(MockWoW.events[event], self)
    end

    function frame:UnregisterEvent(event)
        if not self.registeredEvents[event] then return end
        self.registeredEvents[event] = nil
        for i = #MockWoW.events[event], 1, -1 do
            if MockWoW.events[event][i] == self then table.remove(MockWoW.events[event], i) end
        end
    end

    function frame:IsEventRegistered(event) return self.registeredEvents[event] == true end
    function frame:SetScript(script, callback) self.scripts = self.scripts or {}; self.scripts[script] = callback end
    function frame:HookScript(script, callback) self.hooks[script] = self.hooks[script] or {}; table.insert(self.hooks[script], callback) end
    function frame:TriggerScript(script, ...)
        local callback = self.scripts and self.scripts[script]
        if callback then callback(self, ...) end
        for _, hook in ipairs(self.hooks[script] or {}) do hook(self, ...) end
    end
    function frame:SetPoint() end
    function frame:SetText() end
    function frame:SetJustifyH() end
    function frame:SetChecked(value) self.checked = value end
    function frame:GetChecked() return self.checked end
    function frame:Enable() self.enabled = true end
    function frame:Disable() self.enabled = false end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:CreateFontString() return newFrame() end
    return frame
end

function MockWoW.reset(db)
    ManaToolsDB = db or {}
    MockWoW.events = {}
    MockWoW.inInstance = false
    MockWoW.instanceType = nil
    MockWoW.difficultyID = 0
    MockWoW.challengeActive = false
    MockWoW.guildMembers = {}
    MockWoW.invites = {}

    strlower = string.lower
    strtrim = function(value) return (value:gsub("^%s*(.-)%s*$", "%1")) end
    wipe = function(value) for key in pairs(value) do value[key] = nil end end

    IsInInstance = function() return MockWoW.inInstance, MockWoW.instanceType end
    GetInstanceInfo = function() return "Mock Instance", MockWoW.instanceType or "none", MockWoW.difficultyID end
    C_ChallengeMode = { IsChallengeModeActive = function() return MockWoW.challengeActive end }
    GetNumGuildMembers = function() return #MockWoW.guildMembers end
    GetGuildRosterInfo = function(index) return MockWoW.guildMembers[index] end
    C_PartyInfo = { InviteUnit = function(name) table.insert(MockWoW.invites, name) end }
    SlashCmdList = {}
    Settings = {
        RegisterCanvasLayoutCategory = function(_, name) return { GetID = function() return 1 end, name = name } end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function() end,
    }
    InterfaceOptions_AddCategory = function() end
    InterfaceOptionsFrame_OpenToCategory = function() end
    CreateFrame = function() return newFrame() end
    BonusRollFrame = nil
end

function MockWoW.newBonusRollFrame()
    local frame = newFrame()
    frame.RollButton = newFrame()
    return frame
end

function MockWoW.setGuildMembers(...) MockWoW.guildMembers = {...} end
function MockWoW.clearInvites() MockWoW.invites = {} end
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
    local listeners = MockWoW.events[event] or {}
    for i = 1, #listeners do
        local frame = listeners[i]
        local callback = frame.scripts and frame.scripts.OnEvent
        if callback and frame.registeredEvents[event] then callback(frame, event, ...) end
    end
end

MockWoW.reset()
return MockWoW
