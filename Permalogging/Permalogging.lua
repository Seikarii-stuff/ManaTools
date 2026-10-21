local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.Permalogging or {}
ManaTools.DB.Permalogging = db
ManaTools.Permalogging = ManaTools.Permalogging or {}
local Permalogging = ManaTools.Permalogging
ManaTools.CombatLog = Permalogging

if db.enabled == nil then
    db.enabled = true
end

local function IsCombatLogActive()
    if type(IsCombatLogEnabled) == "function" then
        local active = IsCombatLogEnabled()
        if active ~= nil then
            return active == true
        end
    end

    if type(GetCVarBool) == "function" then
        if GetCVarBool("advancedCombatLogging") then
            return true
        end
        if GetCVarBool("showCombatLog") then
            return true
        end
    end

    if type(GetCVar) == "function" then
        local active = GetCVar("advancedCombatLogging")
        local visible = GetCVar("showCombatLog")
        if active == "1" or active == true then
            return true
        end
        if visible == "1" or visible == true then
            return true
        end
    end

    return false
end

local function EnableCombatLog()
    if type(SetCVar) == "function" then
        SetCVar("advancedCombatLogging", "1")
        SetCVar("showCombatLog", "1")
    end

    if type(RunSlashCmd) == "function" then
        RunSlashCmd("/combatlog")
        return
    end

    if type(SlashCmdList) == "table" and SlashCmdList.COMBATLOG then
        SlashCmdList.COMBATLOG()
    end
end

function Permalogging:Update()
    if db.enabled ~= true then
        return false
    end

    if IsCombatLogActive() then
        return true
    end

    EnableCombatLog()
    return true
end

function Permalogging:Enable()
    db.enabled = true
    return self:Update()
end

function Permalogging:Disable()
    db.enabled = false
end

function Permalogging:OnEvent()
    self:Update()
end

if CreateFrame and type(CreateFrame) == "function" then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function()
        if Permalogging and Permalogging.Update then
            Permalogging:Update()
        end
    end)
    Permalogging.frame = frame
end

Permalogging.Update = Permalogging.Update
