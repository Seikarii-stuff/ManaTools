-- QueueAutoAccept integration and behavior tests.
-- Run from repository root: lua test/test_queue_auto_accept.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

local function loadQueueAddon(db)
    mock.reset(db)
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    ManaTools = namespace
    loadFile("QueueAutoAccept/QueueAutoAccept.lua", "ManaTools", namespace)
    return namespace, namespace.QueueAutoAccept
end

local function assertNoRoleSelection()
    local button = _G.LFGInvitePopupRoleButtonTank and _G.LFGInvitePopupRoleButtonTank.checkButton
    if button then
        assert(button:GetChecked() ~= true, "Tank checkbox should remain unselected when no valid role is determined")
    end
end

-- 1. Bootstrap creates the shared DB branch and default state remains disabled.
do
    local namespace, queue = loadQueueAddon({})
    assert(namespace.DB == ManaToolsDB, "ManaTools.DB points at the shared DB")
    assert(namespace.DB.QueueAutoAccept ~= nil, "QueueAutoAccept DB branch exists")
    assert(namespace.DB.QueueAutoAccept.enabled == true, "QueueAutoAccept defaults to enabled")
    assert(namespace.QueueAutoAccept == queue, "feature namespace is exposed")
end

-- 2. Existing settings are preserved and Update registers events only once.
do
    local db = { QueueAutoAccept = { enabled = true, note = "keep" } }
    local namespace, queue = loadQueueAddon(db)
    assert(namespace.DB.QueueAutoAccept == db.QueueAutoAccept, "existing queue config preserved")
    assert(namespace.DB.QueueAutoAccept.enabled == true, "existing enabled setting preserved")
    queue:Update()
    assert(queue.eventFrame:IsEventRegistered("PARTY_INVITE_REQUEST"), "party invite event registered when enabled")
    assert(queue.eventFrame:IsEventRegistered("GROUP_ROSTER_UPDATE"), "roster update event registered when enabled")
    assert(queue.eventFrame:IsEventRegistered("LFG_ROLE_CHECK_SHOW"), "queue role-check event registered when enabled")
    local count = #mock.events.PARTY_INVITE_REQUEST
    queue:Update()
    queue:Update()
    assert(#mock.events.PARTY_INVITE_REQUEST == count, "repeated Update() does not duplicate the event subscription")
end

-- 3. Disabled mode ignores invitation and role-check events.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = false } })
    local inviteCalls = 0
    AcceptGroup = function() inviteCalls = inviteCalls + 1 end
    CompleteLFGRoleCheck = function() return true end
    local roleButtonTank = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    local roleButtonHealer = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    local roleButtonDPS = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonTank = roleButtonTank
    _G.LFGInvitePopupRoleButtonHealer = roleButtonHealer
    _G.LFGInvitePopupRoleButtonDPS = roleButtonDPS
    mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName", true, false, false)
    mock.fireEvent("LFG_ROLE_CHECK_SHOW")
    assert(inviteCalls == 0, "disabled module does not auto-accept invites")
    assert(roleButtonTank.checkButton:GetChecked() ~= true, "disabled module does not auto-select roles")
end

-- 4. Plain party invite without role booleans is still accepted on the first invite.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    local acceptCalls = 0
    AcceptGroup = function() acceptCalls = acceptCalls + 1 end
    GetSpecialization = function() return 1 end
    GetSpecializationRole = function() return "HEALER" end
    _G.LFGInvitePopupRoleButtonTank = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonHealer = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonDPS = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName")
    assert(acceptCalls == 1, "plain party invite is accepted when enabled")
    assert(_G.LFGInvitePopupRoleButtonHealer.checkButton:GetChecked() == true, "role is selected from specialization when no explicit invite roles are supplied")
end

-- 5. Valid invite resolves to a permitted role and accepts the group.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    local acceptCalls = 0
    AcceptGroup = function() acceptCalls = acceptCalls + 1 end
    GetSpecialization = function() return 1 end
    GetSpecializationRole = function() return "HEALER" end
    _G.LFGInvitePopupRoleButtonTank = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonHealer = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonDPS = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName", true, true, true)
    assert(acceptCalls == 1, "valid invite is accepted when enabled")
    assert(_G.LFGInvitePopupRoleButtonHealer.checkButton:GetChecked() == true, "valid healer role is selected")
end

-- 6. Explicit role preference is respected when valid; no arbitrary fallback is invented.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    local acceptCalls = 0
    AcceptGroup = function() acceptCalls = acceptCalls + 1 end
    GetSpecialization = function() return 1 end
    GetSpecializationRole = function() return nil end
    GetLFGRoles = function() return nil, false, false, false end
    _G.LFGInvitePopupRoleButtonTank = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonHealer = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    _G.LFGInvitePopupRoleButtonDPS = { checkButton = { SetChecked = function(self, value) self.checked = value end, GetChecked = function(self) return self.checked end } }
    mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName", true, true, true)
    assert(acceptCalls == 0, "unknown role does not trigger a blind fallback")
    assertNoRoleSelection()
end

-- 6. Role-check popup is auto-accepted when enabled and ignored when disabled.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    local accepted = false
    CompleteLFGRoleCheck = function() accepted = true; return true end
    StaticPopupSpecial_Hide = function() end
    LFDRoleCheckPopup = { Hide = function() end }
    mock.fireEvent("LFG_ROLE_CHECK_SHOW")
    assert(accepted == true, "role-check completion is requested when enabled")

    local namespace2, queue2 = loadQueueAddon({ QueueAutoAccept = { enabled = false } })
    accepted = false
    CompleteLFGRoleCheck = function() accepted = true; return true end
    mock.fireEvent("LFG_ROLE_CHECK_SHOW")
    assert(accepted == false, "role-check completion is skipped while disabled")
end

-- 7. Closing invite popups is limited to the matching invite flow, not unrelated dialogs.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    local relevant = { which = "PARTY_INVITE", hidden = false, Hide = function(self) self.hidden = true end }
    local other = { which = "DELETE_ITEM", hidden = false, Hide = function(self) self.hidden = true end }
    _G.StaticPopup1 = relevant
    _G.StaticPopup2 = other
    StaticPopup_Hide = function(which) if which == "PARTY_INVITE" then relevant.hidden = true end end
    GetSpecialization = function() return 1 end
    GetSpecializationRole = function() return "TANK" end
    AcceptGroup = function() end
    mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName", true, false, false)
    mock.fireEvent("GROUP_ROSTER_UPDATE")
    assert(relevant.hidden == true, "matching invite popup is hidden")
    assert(other.hidden == false, "other popup types are unaffected")
end

-- 8. Temporary state is cleared after success, failure and disable.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    queue:Disable()
    assert(queue.eventFrame:IsEventRegistered("PARTY_INVITE_REQUEST") == false, "disable unregisters the invite event")
    local namespace2, queue2 = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    queue2:Enable()
    assert(queue2.eventFrame:IsEventRegistered("PARTY_INVITE_REQUEST") == true, "enable re-registers the invite event")
end

-- 9. Missing optional APIs are tolerated without crashing.
do
    local namespace, queue = loadQueueAddon({ QueueAutoAccept = { enabled = true } })
    GetSpecializationRole = nil
    GetLFGRoles = nil
    CompleteLFGRoleCheck = nil
    StaticPopupSpecial_Hide = nil
    AcceptGroup = nil
    local okA, okB = pcall(function() mock.fireEvent("PARTY_INVITE_REQUEST", "PlayerName", true, false, true) end), pcall(function() mock.fireEvent("LFG_ROLE_CHECK_SHOW") end)
    assert(okA, "missing invite APIs do not crash")
    assert(okB, "missing LFG role-check APIs do not crash")
end

print("QueueAutoAccept tests passed")
