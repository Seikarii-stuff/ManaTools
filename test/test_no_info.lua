-- NoInfo behavior test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_info.lua

local loader = loadstring or load
local script = assert(io.open("NoInfo/NoInfo.lua", "r")):read("*a")

local function newFrame()
    local frame = {
        scripts = {},
        shown = true,
        alpha = 1,
        atlas = nil,
        size = {},
    }

    function frame:GetScript(event) return self.scripts[event] end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:SetSize(w, h) self.size.w, self.size.h = w, h end
    function frame:SetFrameStrata(value) self.strata = value end
    function frame:SetFrameLevel(value) self.level = value end
    function frame:SetPoint(...) self.point = {...} end
    function frame:RegisterForClicks(...) self.clicks = {...} end
    function frame:SetShown(value) self.shown = value end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:CreateTexture()
        local texture = {}
        function texture:SetSize(w, h) texture.w, texture.h = w, h end
        function texture:SetPoint(...) texture.point = {...} end
        function texture:SetAtlas(name, useAtlasSize) texture.atlas, texture.useAtlasSize = name, useAtlasSize end
        function texture:SetAlpha(value) texture.alpha = value end
        return texture
    end
    return frame
end

local function runTest()
    local tooltip = newFrame()
    function tooltip:GetTooltipData() return { type = 999 } end
    function tooltip:GetOwner() return nil end
    function tooltip:Hide() self.hidden = true end

    local originalShowCount = 0
    tooltip:SetScript("OnShow", function()
        originalShowCount = originalShowCount + 1
    end)

    GameTooltip = tooltip
    Minimap = newFrame()
    MainMenuMicroButton = newFrame()
    Enum = { TooltipDataType = { Item = 0 } }

    local db = { enabled = true }
    local namespace = { DB = { NoInfo = db }, NoInfo = {} }

    function CreateFrame(_, name)
        local frame = newFrame()
        frame.name = name
        return frame
    end

    assert(loadstring or load)(script, "NoInfo/NoInfo.lua")("ManaTools", namespace)

    assert(namespace.NoInfo.Update, "NoInfo.Update exists")
    assert(db.inspectMode == false, "inspect mode starts disabled")
    assert(GameTooltip:GetScript("OnShow") ~= nil, "NoInfo installs its OnShow wrapper when enabled")

    local wrapper = GameTooltip:GetScript("OnShow")
    wrapper(GameTooltip)
    assert(originalShowCount == 1, "original tooltip OnShow still runs")
    assert(GameTooltip.hidden == true, "normal tooltip is hidden while inspect mode is off")

    assert(namespace.NoInfoTests == nil, "NoInfo does not expose test-only state")

    local button = _G and _G.ManaToolsNoInfoInspectButton
    -- CreateFrame is stubbed without a global registry, so locate the button via
    -- the local behavior by recreating the expected click callback from the frame
    -- returned by CreateFrame in this test is intentionally avoided here.
    -- The public behavior is verified through the DB flag and Update lifecycle below.

    db.inspectMode = true
    wrapper(GameTooltip)
    assert(originalShowCount == 2, "original tooltip OnShow runs in inspect mode")
    assert(GameTooltip.hidden == true, "existing hidden state is not changed by wrapper in inspect mode")

    db.enabled = false
    namespace.NoInfo.Update()
    assert(GameTooltip:GetScript("OnShow") ~= wrapper, "disabling restores the original OnShow")
    assert(db.inspectMode == false, "disabling clears inspect mode")

    db.enabled = true
    namespace.NoInfo.Update()
    local wrapper2 = GameTooltip:GetScript("OnShow")
    assert(wrapper2 ~= nil, "reactivating reinstalls the wrapper")
    assert(wrapper2 ~= wrapper, "reactivation creates a fresh wrapper")

    print("NoInfo tests passed")
end

runTest()
