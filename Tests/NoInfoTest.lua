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

    local tooltip = GameTooltip
    local oldGetScript = tooltip.GetScript
    local oldSetScript = tooltip.SetScript
    local oldHide = tooltip.Hide
    local original = function() end
    local current = original
    local hidden = false
    local setCount = 0

    tooltip.GetScript = function(self, scriptType)
        Assert("GetScript requests OnShow", scriptType == "OnShow")
        return current
    end
    tooltip.SetScript = function(self, scriptType, handler)
        Assert("SetScript requests OnShow", scriptType == "OnShow")
        current = handler
        setCount = setCount + 1
    end
    tooltip.Hide = function()
        hidden = true
    end

    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()
    local wrapper = current
    Assert("enable installs reversible wrapper", wrapper ~= original)
    Assert("enable installs exactly once", setCount == 1)

    hidden = false
    wrapper(tooltip)
    Assert("wrapper preserves original OnShow", current == wrapper)
    Assert("wrapper hides non-exempt tooltip", hidden == true)

    hidden = false
    ManaTools.DB.NoInfo.enabled = false
    ManaTools.NoInfo.Update()
    Assert("disable restores original OnShow", current == original)
    Assert("disable hides current tooltip", hidden == true)

    local disabledSetCount = setCount
    ManaTools.NoInfo.Update()
    Assert("repeated disable does not touch script", setCount == disabledSetCount)

    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()
    Assert("reactivate installs a fresh wrapper", current ~= original)
    Assert("reactivation does not accumulate wrappers", setCount == disabledSetCount + 1)

    local secondWrapper = current
    ManaTools.NoInfo.Update()
    Assert("repeated enable does not replace wrapper", current == secondWrapper)
    Assert("repeated enable does not add work", setCount == disabledSetCount + 1)

    tooltip.GetScript = oldGetScript
    tooltip.SetScript = oldSetScript
    tooltip.Hide = oldHide

    ManaTools.DB.NoInfo.enabled = true
    ManaTools.NoInfo.Update()

    print(string.format("[NoInfo TEST] %d passed, %d failed", passed, failed))
    return failed == 0
end

ManaTools.NoInfoTests = Tests
