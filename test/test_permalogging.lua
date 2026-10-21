-- Permalogging behavior and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_permalogging.lua

local loader = loadstring or load

local function runTest()
    local globalState = {
        SetCVarValues = {},
        slashCommands = {},
        combatLogEnabled = false,
    }

    local function resetGlobals()
        _G.SetCVar = function(name, value)
            globalState.SetCVarValues[name] = value
        end
        _G.GetCVar = function(name)
            if name == "advancedCombatLogging" then
                return globalState.SetCVarValues[name] or "0"
            end
            if name == "showCombatLog" then
                return globalState.SetCVarValues[name] or "0"
            end
            return "0"
        end
        _G.IsCombatLogEnabled = function()
            return globalState.combatLogEnabled == true
        end
        _G.RunSlashCmd = function(command)
            table.insert(globalState.slashCommands, command)
        end
    end

    resetGlobals()

    local db = { enabled = true }
    local namespace = { DB = { Permalogging = db }, Permalogging = {} }

    local file = assert(io.open("Permalogging/Permalogging.lua", "r"))
    local script = file:read("*a")
    file:close()

    assert((loader or load)(script, "Permalogging/Permalogging.lua"))("ManaTools", namespace)
    assert(namespace.Permalogging and namespace.Permalogging.Update, "Permalogging module is loaded")

    namespace.Permalogging:Update()
    assert(globalState.SetCVarValues["advancedCombatLogging"] == "1", "advancedCombatLogging is enabled when inactive")
    assert(globalState.SetCVarValues["showCombatLog"] == "1", "showCombatLog is enabled when inactive")

    globalState.SetCVarValues = {}
    globalState.combatLogEnabled = true
    namespace.Permalogging:Update()
    assert(globalState.SetCVarValues["advancedCombatLogging"] == nil, "enabled combat log is not toggled again")
    assert(globalState.SetCVarValues["showCombatLog"] == nil, "enabled showCombatLog is not toggled again")

    print("Permalogging tests: PASS")
end

runTest()
