-- Permalogging behavior and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_permalogging.lua

local loader = loadstring or load

local function makeMockEnvironment()
    local state = {
        enabled = true,
        inInstance = false,
        instanceType = nil,
        combatLogState = false,
        activationCalls = 0,
        queryCalls = 0,
        queryIsNil = false,
        loggingResult = nil,
    }

    local events = {}

    local function fireEvent(name, ...)
        for _, frame in ipairs(events[name] or {}) do
            local callback = frame.scripts and frame.scripts.OnEvent
            if callback then
                callback(frame, name, ...)
            end
        end
    end

    _G.SetCVar = nil
    _G.GetCVar = nil
    _G.RunSlashCmd = nil
    _G.SlashCmdList = nil
    _G.IsCombatLogEnabled = nil
    _G.IsInInstance = function()
        return state.inInstance, state.instanceType
    end
    _G.LoggingCombat = function(force)
        if force == true then
            state.activationCalls = state.activationCalls + 1
            state.combatLogState = true
            return true
        end

        state.queryCalls = state.queryCalls + 1
        if state.queryIsNil == true then
            return nil
        end
        if state.loggingResult ~= nil then
            return state.loggingResult
        end
        return state.combatLogState == true
    end

    _G.CreateFrame = function()
        local frame = {
            scripts = {},
            registeredEvents = {},
        }

        function frame:RegisterEvent(event)
            if self.registeredEvents[event] then
                return
            end
            self.registeredEvents[event] = true
            events[event] = events[event] or {}
            table.insert(events[event], self)
        end

        function frame:SetScript(script, callback)
            self.scripts[script] = callback
        end

        return frame
    end

    return state, fireEvent
end

local function loadModule(state)
    local namespace = {
        DB = { Permalogging = { enabled = state.enabled } },
        Permalogging = {},
    }

    local file = assert(io.open("Permalogging/Permalogging.lua", "r"))
    local script = file:read("*a")
    file:close()

    assert((loader or load)(script, "Permalogging/Permalogging.lua"))("ManaTools", namespace)
    assert(namespace.Permalogging and namespace.Permalogging.Update, "Permalogging module is loaded")
    return namespace
end

local function runTest()
    local state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = false

    local namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 1, "party dungeon enables logging once when inactive")
    assert(namespace.Permalogging.frame and namespace.Permalogging.frame.registeredEvents["PLAYER_ENTERING_WORLD"], "PLAYER_ENTERING_WORLD is registered")
    assert(namespace.Permalogging.frame and namespace.Permalogging.frame.registeredEvents["ZONE_CHANGED_NEW_AREA"], "ZONE_CHANGED_NEW_AREA is registered")

    state = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "raid"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 1, "raid enables logging once when inactive")

    state = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = true
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "active combat log is not re-enabled")

    state = makeMockEnvironment()
    state.enabled = false
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.queryCalls == 0, "disabled option does not query combat log status")
    assert(state.activationCalls == 0, "disabled option does not activate the combat log")

    state = makeMockEnvironment()
    state.inInstance = false
    state.instanceType = nil
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "outside an instance does not enable logging")

    state = makeMockEnvironment()
    state.inInstance = false
    state.instanceType = nil
    namespace = loadModule(state)
    fireEvent("ZONE_CHANGED_NEW_AREA")
    assert(state.activationCalls == 0, "LFG join without entering an instance does not activate logging")

    state = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.queryIsNil = true
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "nil status is not treated as disabled")

    state = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "raid"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    fireEvent("ZONE_CHANGED_NEW_AREA")
    assert(state.activationCalls == 1, "duplicate event delivery in the same entry does not re-enable logging")

    state = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    state.inInstance = false
    state.instanceType = nil
    fireEvent("ZONE_CHANGED_NEW_AREA")
    state.inInstance = true
    state.instanceType = "raid"
    state.combatLogState = false
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 2, "re-entry after leaving the instance rechecks and enables again when the log is actually inactive")

    print("Permalogging tests: PASS")
end

runTest()
