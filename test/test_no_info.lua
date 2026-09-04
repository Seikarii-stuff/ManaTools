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
    function frame:HookScript(event, callback)
        self.hooks = self.hooks or {}
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], callback)
    end
    function frame:TriggerScript(event, ...)
        local cb = self.scripts[event]
        if cb then cb(self, ...) end
        for _, h in ipairs(self.hooks and (self.hooks[event] or {}) or {}) do h(self, ...) end
    end
    function frame:SetSize(w, h) self.size.w, self.size.h = w, h end
    function frame:SetFrameStrata(value) self.strata = value end
    function frame:SetFrameLevel(value) self.level = value end
    function frame:SetPoint(...) self.point = {...} end
    function frame:ClearAllPoints() self.point = nil end
    function frame:RegisterForClicks(...) self.clicks = {...} end
    function frame:EnableMouse(value) self.mouseEnabled = value end
    function frame:SetShown(value) self.shown = value end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:GetWidth() return 100 end
    function frame:CreateTexture()
        local texture = newFrame()
        function texture:SetAtlas(name, useAtlasSize) self.atlas, self.useAtlasSize = name, useAtlasSize end
        function texture:SetVertexColor(r, g, b) self.r, self.g, self.b = r, g, b end
        return texture
    end
    function frame:Hide() self.hidden = true end
    function frame:Show() self.hidden = false; if self.TriggerScript then self:TriggerScript("OnShow") end end
    function frame:GetUnit() return self.unitName, self.unit end
    return frame
end

local function runTest()
    local tooltip = newFrame()
    function tooltip:GetTooltipData() return { type = 999 } end
    function tooltip:GetOwner() return nil end
    function tooltip:NumLines() return self.tooltipLines or 0 end
    function tooltip:GetLine(index)
        local lines = self.lines or {}
        return lines[index]
    end
    function tooltip:AddLine(text)
        self.tooltipText = text
        self.tooltipLines = (self.tooltipLines or 0) + 1
        self.lines = self.lines or {}
        table.insert(self.lines, text)
    end

    local originalShowCount = 0
    local originalOnShow = function() originalShowCount = originalShowCount + 1 end
    tooltip:SetScript("OnShow", originalOnShow)

    GameTooltip = tooltip
    Minimap = newFrame()
    MainMenuMicroButton = newFrame()
    Enum = { TooltipDataType = { Item = 0 } }

    local db = { enabled = true, inspectMode = 0 }
    local namespace = { DB = { NoInfo = db }, NoInfo = {} }

    function CreateFrame(_, name)
        local frame = newFrame()
        frame.name = name
        _G[name] = frame
        return frame
    end

    assert((loader or load)(script, "NoInfo/NoInfo.lua"))("ManaTools", namespace)
    assert(namespace.NoInfo.Update, "NoInfo.Update exists")
    assert(db.inspectMode == 0, "inspect mode starts in OFF state")

    local wrapper = GameTooltip:GetScript("OnShow")
    assert(wrapper ~= nil, "enabled NoInfo installs its wrapper")

    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(originalShowCount == 1, "original OnShow still runs")
    assert(GameTooltip.hidden == true, "generic tooltip is hidden when OFF")

    local button = _G.ManaToolsNoInfoInspectButton
    assert(button ~= nil, "inspect button is created")
    assert(button.shown == true, "button is shown while enabled")
    assert(button.point[2] == Minimap, "button is anchored to Minimap")
    assert(button.icon.atlas == "talents-search-match", "button uses the Blizzard magnifier atlas")
    assert(button.alpha == 0.55, "button starts dimmed in OFF state")

    _G.IsShiftKeyDown = function() return false end
    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == 1, "normal click from OFF enables normal inspect state")
    assert(button.alpha == 1, "button is illuminated in NORMAL state")

    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(originalShowCount == 2, "original OnShow runs in NORMAL state")
    assert(GameTooltip.hidden == false, "NORMAL inspect mode lets generic tooltips show")

    tooltip.GetTooltipData = function() return { type = Enum.TooltipDataType.Item } end
    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(GameTooltip.hidden == false, "item tooltip data stays exempt")

    -- state transitions
    _G.IsShiftKeyDown = function() return true end
    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == 2, "shift+left click from NORMAL enables rating state")

    _G.IsShiftKeyDown = function() return false end
    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == 0, "normal click from RATING disables inspect mode")

    db.enabled = false
    namespace.NoInfo.Update()
    assert(GameTooltip:GetScript("OnShow") == originalOnShow, "disable restores the original OnShow")
    assert(db.inspectMode == 0, "disable clears inspect mode")
    assert(button.shown == false, "button is hidden while disabled")

    db.enabled = true
    namespace.NoInfo.Update()
    local wrapper2 = GameTooltip:GetScript("OnShow")
    assert(wrapper2 == wrapper, "reactivation reuses the shared wrapper")
    assert(button.shown == true, "reactivation shows the button again")

    local calls = 0
    C_PlayerInfo = { GetPlayerMythicPlusRatingSummary = function(unit)
        calls = calls + 1
        return { currentSeasonScore = 2450 }
    end }

    GameTooltip.tooltipLines = 0
    GameTooltip.lines = {}
    GameTooltip.unit = "npc_unit"
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(calls == 0, "OFF state never calls Mythic+ API")

    db.inspectMode = 1
    GameTooltip.tooltipLines = 0
    GameTooltip.lines = {}
    GameTooltip.unit = "mouseover"
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(calls == 0, "NORMAL state never calls Mythic+ API")

    db.inspectMode = 2
    local function setUnit(unit)
        GameTooltip.unit = unit
        GameTooltip.tooltipLines = 0
        GameTooltip.lines = {}
        GameTooltip.tooltipText = nil
    end

    setUnit("npc_unit")
    UnitIsPlayer = function(unit) return false end
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(calls == 0, "NPC in RATING state never calls Mythic+ API")

    setUnit("player_unit")
    UnitIsPlayer = function(unit) return true end
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(calls == 1, "player in RATING state calls the Mythic+ API once")
    assert(GameTooltip.tooltipLines == 1, "player with score adds exactly one tooltip line")
    assert(GameTooltip.tooltipText == "Mythic+ Rating: 2450")

    C_PlayerInfo.GetPlayerMythicPlusRatingSummary = function(unit) return { currentSeasonScore = nil } end
    setUnit("player_unit")
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(GameTooltip.tooltipLines == 0, "player without currentSeasonScore adds no lines")

    C_PlayerInfo.GetPlayerMythicPlusRatingSummary = function(unit) return nil end
    setUnit("player_unit")
    GameTooltip:TriggerScript("OnTooltipSetUnit")
    assert(GameTooltip.tooltipLines == 0, "nil summary adds no lines")

    db.inspectMode = 2
    namespace.NoInfo.Update()
    namespace.NoInfo.Update()
    local hooks = (GameTooltip.hooks and GameTooltip.hooks["OnTooltipSetUnit"]) or {}
    assert(#hooks == 1, "OnTooltipSetUnit hook installed only once")

    if db.inspectMode == true then
        assert(false, "db.inspectMode migrated to numeric state")
    end

    print("NoInfo tests passed")
end

runTest()
