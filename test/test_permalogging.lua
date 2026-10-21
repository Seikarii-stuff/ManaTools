-- Permalogging behavior and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_permalogging.lua

local loader = loadstring or load

local function makeMockEnvironment()
    local originalPrint = _G.print
    local state = {
        enabled = true,
        inInstance = false,
        instanceType = nil,
        combatLogState = false,
        activationCalls = 0,
        queryCalls = 0,
        querySequence = {},
        activationResult = true,
        chatMessages = {},
        registeredEvents = {},
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
    _G.print = function(message)
        table.insert(state.chatMessages, message)
        if originalPrint then
            originalPrint(message)
        end
    end
    _G.IsInInstance = function()
        return state.inInstance, state.instanceType
    end
    _G.LoggingCombat = function(force)
        if force == true then
            state.activationCalls = state.activationCalls + 1
            if state.activationResult ~= nil then
                state.combatLogState = state.activationResult == true
                return state.activationResult
            end
            state.combatLogState = true
            return true
        end

        state.queryCalls = state.queryCalls + 1
        if #state.querySequence > 0 then
            local nextValue = table.remove(state.querySequence, 1)
            if nextValue == "__NIL__" then
                return nil
            end
            if nextValue == "__FALSE__" then
                state.combatLogState = false
                return false
            end
            if nextValue == "__TRUE__" then
                state.combatLogState = true
                return true
            end
            return nextValue
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
    assert(#state.chatMessages == 1, "party dungeon prints a single success message")
    assert(namespace.Permalogging.frame and namespace.Permalogging.frame.registeredEvents["PLAYER_ENTERING_WORLD"], "PLAYER_ENTERING_WORLD is registered")
    assert(namespace.Permalogging.frame and namespace.Permalogging.frame.registeredEvents["ZONE_CHANGED_NEW_AREA"], "ZONE_CHANGED_NEW_AREA is registered")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "raid"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 1, "raid enables logging once when inactive")
    assert(#state.chatMessages == 1, "raid prints the success message once")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = true
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "active combat log is not re-enabled")
    assert(#state.chatMessages == 0, "active log does not print success")

    state, fireEvent = makeMockEnvironment()
    state.enabled = false
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.queryCalls == 0, "disabled option does not query combat log status")
    assert(state.activationCalls == 0, "disabled option does not activate the combat log")
    assert(#state.chatMessages == 0, "disabled option does not print success")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = false
    state.instanceType = nil
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "outside an instance does not enable logging")
    assert(#state.chatMessages == 0, "outside an instance does not print success")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = false
    state.instanceType = nil
    namespace = loadModule(state)
    fireEvent("ZONE_CHANGED_NEW_AREA")
    assert(state.activationCalls == 0, "LFG join without entering an instance does not activate logging")
    assert(#state.chatMessages == 0, "LFG without entry does not print success")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.querySequence = {"__NIL__"}
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "nil status is not treated as disabled")
    assert(#state.chatMessages == 0, "nil status does not print success")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.querySequence = {"__NIL__", "__FALSE__"}
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 0, "first nil result remains pending before a later retry")
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 1, "a later false result can trigger activation after a pending check")
    assert(#state.chatMessages == 1, "successful retry prints the message once")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "raid"
    state.activationResult = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(state.activationCalls == 1, "a failed activation request is attempted once")
    assert(#state.chatMessages == 0, "failed activation does not print a false success message")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    state.combatLogState = false
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    fireEvent("ZONE_CHANGED_NEW_AREA")
    assert(state.activationCalls == 1, "duplicate events in the same entry do not reactivate")
    assert(#state.chatMessages == 1, "duplicate same-entry events do not print multiple success messages")

    state, fireEvent = makeMockEnvironment()
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
    assert(state.activationCalls == 2, "re-entry after leaving the instance rechecks and re-enables correctly")
    assert(#state.chatMessages == 2, "re-entry prints a success message for each confirmed activation")

    state, fireEvent = makeMockEnvironment()
    state.inInstance = true
    state.instanceType = "party"
    namespace = loadModule(state)
    fireEvent("PLAYER_ENTERING_WORLD")
    assert(namespace.Permalogging.frame and namespace.Permalogging.frame.registeredEvents["ZONE_CHANGED_NEW_AREA"], "event callbacks are registered in this environment")
    assert(state.activationCalls == 1, "registered event callback path triggers the actual update logic")

    print("Permalogging tests: PASS")
end

runTest()
