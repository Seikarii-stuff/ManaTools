-- NoInfo regression tests.
-- Run in-game with: /run ManaTools.NoInfoTests.Run()

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

    local originalOnShow = GameTooltip:GetScript("OnShow")
    local db = ManaTools.DB.NoInfo

    db.enabled = true
    ManaTools.NoInfo.Update()
    Assert("enable installs a wrapper", GameTooltip:GetScript("OnShow") ~= originalOnShow)

    local button = _G.ManaToolsNoInfoInspectButton
    Assert("inspect button is created", button ~= nil)
    Assert("button is visible while enabled", button and button:IsShown() == true)

    if button then
        button:Click()
        Assert("left click toggles inspect mode", db.inspectMode == true)
        button:Click()
        Assert("second click disables inspect mode", db.inspectMode == false)
    end

    db.enabled = false
    ManaTools.NoInfo.Update()
    Assert("disable restores the original handler", GameTooltip:GetScript("OnShow") == originalOnShow)
    Assert("disable clears inspect mode", db.inspectMode == false)

    print(string.format("[NoInfo TEST] %d passed, %d failed", passed, failed))
    return failed == 0
end

ManaTools.NoInfoTests = Tests
