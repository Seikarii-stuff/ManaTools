local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.Permalogging or {}
ManaTools.DB.Permalogging = db
ManaTools.Permalogging = ManaTools.Permalogging or {}
local Permalogging = ManaTools.Permalogging
ManaTools.CombatLog = Permalogging

if db.enabled == nil then
    db.enabled = true
end

local currentEntryState = {
    active = false,
    pending = false,
    instanceType = nil,
}

local function ResetEntryState()
    currentEntryState.active = false
    currentEntryState.pending = false
    currentEntryState.instanceType = nil
end

local function IsRelevantInstance(inInstance, instanceType)
    if inInstance ~= true then
        return false
    end

    return instanceType == "party" or instanceType == "raid"
end

local function TryActivateCombatLog()
    local loggingCombat = _G.LoggingCombat
    if type(loggingCombat) ~= "function" then
        return false
    end

    local activationResult = loggingCombat(true)
    if activationResult ~= true then
        return false
    end

    local confirmed = loggingCombat()
    if confirmed ~= true then
        return false
    end

    print("|cff00ff00ManaTools: Combat log activo.|r")
    return true
end

function Permalogging:Update()
    if db.enabled ~= true then
        return false
    end

    local inInstance, instanceType
    local isInInstance = _G.IsInInstance
    if type(isInInstance) == "function" then
        inInstance, instanceType = isInInstance()
    else
        inInstance = false
        instanceType = nil
    end

    if not IsRelevantInstance(inInstance, instanceType) then
        ResetEntryState()
        return false
    end

    if currentEntryState.active == true and currentEntryState.instanceType == instanceType then
        return true
    end

    local loggingCombat = _G.LoggingCombat
    if type(loggingCombat) ~= "function" then
        return false
    end

    local active = loggingCombat()
    if active == true then
        currentEntryState.active = true
        currentEntryState.pending = false
        currentEntryState.instanceType = instanceType
        return true
    end

    if active == false then
        currentEntryState.pending = true
        currentEntryState.instanceType = instanceType
        if TryActivateCombatLog() then
            currentEntryState.active = true
            currentEntryState.pending = false
            return true
        end
        return false
    end

    currentEntryState.pending = true
    currentEntryState.instanceType = instanceType
    return false
end

function Permalogging:Enable()
    db.enabled = true
    return self:Update()
end

function Permalogging:Disable()
    db.enabled = false
    ResetEntryState()
end

function Permalogging:OnEvent()
    if self and self.Update then
        self:Update()
    end
end

local createFrame = _G.CreateFrame
if type(createFrame) == "function" then
    local frame = createFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:SetScript("OnEvent", function(_, event)
        if event ~= "PLAYER_ENTERING_WORLD" and event ~= "ZONE_CHANGED_NEW_AREA" then
            return
        end

        if Permalogging and Permalogging.Update then
            Permalogging:Update()
        end
    end)
    Permalogging.frame = frame
end

Permalogging.Update = Permalogging.Update
