-- NoInfo regression tests.
-- Run in-game with: /run ManaTools.NoInfoTests.Run()
-- The tests use lightweight stubs so they do not depend on the live tooltip UI.

local Tests = {}
local passed, failed = 0, 0

local function Assert(name, condition)
    if condition then
        passed = passed + 1
        print("|cff00ff00[NoInfo TEST PASS]|r " .. name)
    else
        failed = failed + 1
        print("|cffff0000[NoInfo TEST FAIL]|r " .. name)
    end
end

function Tests.Run()
    passed, failed = 0, 0

    Assert("DB exists", ManaTools and ManaTools.DB and ManaTools.DB.NoInfo ~= nil)
    Assert("NoInfo API exists", ManaTools.NoInfo and ManaTools.NoInfo.Update ~= nil)
    Assert("default is enabled", ManaTools.DB.NoInfo.enabled == true)

    -- The regression that originally failed: Update() must not call a nil UnhookScript.
    local oldTooltip = GameTooltip
    local oldHookScript = oldTooltip.HookScript
    local oldUnhookScript = oldTooltip.UnhookScript
    local oldHide = oldTooltip.Hide
    local hooks = {}
    local hidden = false

    oldTooltip.HookScript = function(self, event, callback)
        hooks[event] = callback
    end
    oldTooltip.UnhookScript = function(self, event, callback)
        Assert("UnhookScript receives OnShow", event == "OnShow")
        Assert("UnhookScript receives our callback", hooks[event] == callback)
        hooks[event] = nil
    end
    oldTooltip.Hide = function()
        hidden = true
    end

    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()
    Assert("enable installs OnShow", hooks.OnShow ~= nil)

    ManaTools.DB.NoInfo.enabled = false
    ManaTools.NoInfo.Update()
    Assert("disable removes OnShow", hooks.OnShow == nil)
    Assert("disable hides current tooltip", hidden == true)

    hidden = false
    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()
    Assert("reactivate reinstalls OnShow", hooks.OnShow ~= nil)

    -- Repeated state changes must be idempotent.
    local installedCallback = hooks.OnShow
    ManaTools.NoInfo.Update()
    Assert("repeated enable keeps one hook", hooks.OnShow == installedCallback)

    ManaTools.DB.NoInfo.enabled = false
    ManaTools.NoInfo.Update()
    ManaTools.NoInfo.Update()
    Assert("repeated disable stays disabled", hooks.OnShow == nil)

    oldTooltip.HookScript = oldHookScript
    oldTooltip.UnhookScript = oldUnhookScript
    oldTooltip.Hide = oldHide

    -- Leave the addon in its configured/default enabled state after tests.
    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()

    print(string.format("[NoInfo TEST] %d passed, %d failed", passed, failed))
    return failed == 0
end

ManaTools.NoInfoTests = Tests
