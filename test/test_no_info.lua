-- NoInfo behavior and lifecycle test suite.
-- Requires Lua 5.1+.
-- Run from repository root: lua test/test_no_info.lua

local loader = loadstring or load
local file = assert(io.open("NoInfo/NoInfo.lua", "r"))
local script = file:read("*a")
file:close()

local function newFrame()
    local frame = { scripts = {}, shown = true, alpha = 1, size = {} }

    function frame:GetScript(event) return self.scripts[event] end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:SetSize(w, h) self.size.w, self.size.h = w, h end
    function frame:SetFrameStrata(value) self.strata = value end
    function frame:SetFrameLevel(value) self.level = value end
    function frame:SetPoint(...) self.point = {...} end
    function frame:ClearAllPoints() self.point = nil end
    function frame:RegisterForClicks(...) self.clicks = {...} end
    function frame:RegisterForDrag(...) self.dragButtons = {...} end
    function frame:EnableMouse(value) self.mouseEnabled = value end
    function frame:SetShown(value) self.shown = value end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:GetCenter() return 500, 500 end
    function frame:GetWidth() return 100 end
    function frame:CreateTexture()
        local texture = {}
        function texture:SetSize(w, h) texture.w, texture.h = w, h end
        function texture:SetPoint(...) texture.point = {...} end
        function texture:SetAtlas(name, useAtlasSize) texture.atlas, texture.useAtlasSize = name, useAtlasSize end
        function texture:SetAlpha(value) texture.alpha = value end
        return texture
    end
    function frame:Hide() self.hidden = true end
    return frame
end

local function runTest()
    local tooltip = newFrame()
    function tooltip:GetTooltipData() return { type = 999 } end
    function tooltip:GetOwner() return nil end

    local originalShowCount = 0
    local originalOnShow = function()
        originalShowCount = originalShowCount + 1
    end
    tooltip:SetScript("OnShow", originalOnShow)

    GameTooltip = tooltip
    Minimap = newFrame()
    MainMenuMicroButton = newFrame()
    Enum = { TooltipDataType = { Item = 0 } }
    GetCursorPosition = function() return 600, 500 end
    UIParent = newFrame()
    function UIParent:GetEffectiveScale() return 1 end
    IsShiftKeyDown = function() return true end
    _G.ManaToolsNoInfoInspectButton = nil

    local db = { enabled = true }
    local namespace = { DB = { NoInfo = db }, NoInfo = {} }

    function CreateFrame(_, name)
        local frame = newFrame()
        frame.name = name
        _G[name] = frame
        return frame
    end

    assert((loader or load)(script, "NoInfo/NoInfo.lua"))("ManaTools", namespace)

    assert(namespace.NoInfo.Update, "NoInfo.Update exists")
    assert(db.inspectMode == false, "inspect mode starts disabled")
    assert(GameTooltip:GetScript("OnShow") ~= nil, "NoInfo installs its OnShow wrapper when enabled")

    local wrapper = GameTooltip:GetScript("OnShow")
    wrapper(GameTooltip)
    assert(originalShowCount == 1, "original tooltip OnShow still runs")
    assert(GameTooltip.hidden == true, "normal tooltip is hidden while inspect mode is off")

    local button = _G.ManaToolsNoInfoInspectButton
    assert(button ~= nil, "inspect button is created")
    assert(button.shown == true, "inspect button is shown while NoInfo is enabled")
    assert(button.point[2] == Minimap, "inspect button is anchored to Minimap")
    assert(button.icon.atlas == "talents-search-match", "inspect button uses Blizzard search/magnifier atlas")
    assert(button.dragButtons and button.dragButtons[1] == "LeftButton", "inspect button registers left-button drag")

    -- Normal left click toggles inspect mode.
    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == true, "left click enables inspect mode")
    assert(button.alpha == 1, "inspect button is highlighted while active")

    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(originalShowCount == 2, "original tooltip OnShow still runs in inspect mode")
    assert(GameTooltip.hidden == false, "inspect mode allows normal tooltips")

    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == false, "second left click disables inspect mode")
    assert(button.alpha == 0.55, "inspect button is dimmed while inactive")

    -- Shift + drag follows the cursor and persists the angle.
    button.scripts.OnDragStart(button)
    assert(button.scripts.OnUpdate ~= nil, "drag installs temporary OnUpdate")
    button.scripts.OnUpdate(button)
    assert(db.minimapAngle == 0, "drag computes the expected angle")
    button.scripts.OnDragStop(button)
    assert(button.scripts.OnUpdate == nil, "drag removes temporary OnUpdate")

    -- Disabling restores Blizzard's original OnShow and removes the button.
    db.enabled = false
    namespace.NoInfo.Update()
    assert(GameTooltip:GetScript("OnShow") == originalOnShow, "disabling restores the original OnShow")
    assert(db.inspectMode == false, "disabling clears inspect mode")
    assert(button.shown == false, "inspect button is hidden while NoInfo is disabled")
    assert(button.scripts.OnUpdate == nil, "disabled state has no drag OnUpdate")

    -- Re-enable and verify a clean wrapper lifecycle without accumulating handlers.
    db.enabled = true
    namespace.NoInfo.Update()
    local wrapper2 = GameTooltip:GetScript("OnShow")
    assert(wrapper2 ~= nil, "reactivating reinstalls the wrapper")
    assert(wrapper2 ~= wrapper, "reactivation creates a fresh wrapper")
    assert(button.shown == true, "reactivating shows the inspect button")

    db.enabled = false
    namespace.NoInfo.Update()
    assert(GameTooltip:GetScript("OnShow") == originalOnShow, "second disable restores original OnShow")

    print("NoInfo tests passed")
end

runTest()
