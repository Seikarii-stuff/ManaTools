local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.Permalogging or {}
ManaTools.DB.Permalogging = db
ManaTools.Permalogging = ManaTools.Permalogging or {}
local Permalogging = ManaTools.Permalogging
ManaTools.CombatLog = Permalogging

if db.enabled == nil then
    db.enabled = true
end

local lastRelevantInstanceType = nil

local function IsRelevantInstance()
    if type(IsInInstance) ~= "function" then
        return false
    end

    local inInstance, instanceType = IsInInstance()
    if inInstance ~= true then
        return false
    end

    return instanceType == "party" or instanceType == "raid"
end

function Permalogging:Update()
    if db.enabled ~= true then
        return false
    end

    if not IsRelevantInstance() then
        lastRelevantInstanceType = nil
        return false
    end

    local inInstance, instanceType = IsInInstance()
    if inInstance ~= true then
        lastRelevantInstanceType = nil
        return false
    end

    if lastRelevantInstanceType == instanceType then
        return true
    end

    lastRelevantInstanceType = instanceType

    if type(LoggingCombat) ~= "function" then
        return false
    end

    local active = LoggingCombat()
    if active == true then
        return true
    end

    if active == false then
        LoggingCombat(true)
        return true
    end

    return false
end

function Permalogging:Enable()
    db.enabled = true
    return self:Update()
end

function Permalogging:Disable()
    db.enabled = false
end

function Permalogging:OnEvent()
    if self and self.Update then
        self:Update()
    end
end

if CreateFrame and type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame")
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
