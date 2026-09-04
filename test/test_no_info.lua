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
    return frame
end

local function runTest()
    local tooltip = newFrame()
    function tooltip:GetTooltipData() return { type = 999 } end
    function tooltip:GetOwner() return nil end

    local originalShowCount = 0
    local originalOnShow = function() originalShowCount = originalShowCount + 1 end
    tooltip:SetScript("OnShow", originalOnShow)

    GameTooltip = tooltip
    Minimap = newFrame()
    MainMenuMicroButton = newFrame()
    Enum = { TooltipDataType = { Item = 0 } }

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

    local wrapper = GameTooltip:GetScript("OnShow")
    assert(wrapper ~= nil, "enabled NoInfo installs its wrapper")

    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(originalShowCount == 1, "original OnShow still runs")
    assert(GameTooltip.hidden == true, "generic tooltip is hidden")

    local button = _G.ManaToolsNoInfoInspectButton
    assert(button ~= nil, "inspect button is created")
    assert(button.shown == true, "button is shown while enabled")
    assert(button.point[2] == Minimap, "button is anchored to Minimap")
    assert(button.icon.atlas == "talents-search-match", "button uses the Blizzard magnifier atlas")
    assert(button.alpha == 0.55, "button starts dimmed outside inspect mode")

    -- Test toggle behavior: Shift+LeftButton enables, LeftButton disables
    _G.IsShiftKeyDown = function() return true end
    button.scripts.OnClick(button, "LeftButton")
    assert(db.inspectMode == true, "shift+left click enables inspect mode")
    assert(button.alpha == 1, "button is highlighted in inspect mode")

    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(originalShowCount == 2, "original OnShow runs in inspect mode")
    assert(GameTooltip.hidden == false, "inspect mode lets generic tooltips show")

    tooltip.GetTooltipData = function() return { type = Enum.TooltipDataType.Item } end
    GameTooltip.hidden = false
    wrapper(GameTooltip)
    assert(GameTooltip.hidden == false, "item tooltip data stays exempt")
    -- now disable inspect mode via normal click
    _G.IsShiftKeyDown = function() return false end
    local onClick = button:GetScript("OnClick")
    if onClick then onClick(button, "LeftButton") end
    assert(db.inspectMode == false, "left click disables inspect mode")

    db.enabled = false
    namespace.NoInfo.Update()
    assert(GameTooltip:GetScript("OnShow") == originalOnShow, "disable restores the original OnShow")
    assert(db.inspectMode == false, "disable clears inspect mode")
    assert(button.shown == false, "button is hidden while disabled")

    db.enabled = true
    namespace.NoInfo.Update()
    local wrapper2 = GameTooltip:GetScript("OnShow")
    assert(wrapper2 == wrapper, "reactivation reuses the shared wrapper")
    assert(button.shown == true, "reactivation shows the button again")

    -- Now test OnTooltipSetUnit behavior for Mythic+ enrichment
    local calls = 0
    C_PlayerInfo = { GetPlayerMythicPlusRatingSummary = function(unit) calls = calls + 1; return { currentSeasonScore = 2450 } end }
    UnitIsPlayer = function(unit) return unit == "player_unit" end
    GameTooltip.tooltipLines = 0
    function GameTooltip:AddLine(text) self.tooltipText = text; self.tooltipLines = (self.tooltipLines or 0) + 1 end

    -- OFF: should not call the API
    db.inspectMode = false
    GameTooltip:TriggerScript("OnTooltipSetUnit", "player_unit")
    assert(calls == 0, "OFF mode does not call GetPlayerMythicPlusRatingSummary")

    -- ON + NPC: should not call API or add line
    db.inspectMode = true
    UnitIsPlayer = function(unit) return false end
    GameTooltip.tooltipLines = 0
    GameTooltip:TriggerScript("OnTooltipSetUnit", "npc_unit")
    assert(calls == 0, "NPC does not trigger GetPlayerMythicPlusRatingSummary")
    assert((GameTooltip.tooltipLines or 0) == 0, "NPC does not add tooltip lines")

    -- ON + player + score
    UnitIsPlayer = function(unit) return true end
    GameTooltip.tooltipLines = 0
    GameTooltip:TriggerScript("OnTooltipSetUnit", "player_unit")
    assert(calls > 0, "player triggers GetPlayerMythicPlusRatingSummary")
    assert(GameTooltip.tooltipLines == 1, "player with score adds one tooltip line")
    assert(GameTooltip.tooltipText == "Mythic+ Rating: 2450")

    -- ON + player without score
    C_PlayerInfo.GetPlayerMythicPlusRatingSummary = function(unit) return { currentSeasonScore = nil } end
    GameTooltip.tooltipLines = 0
    GameTooltip:TriggerScript("OnTooltipSetUnit", "player_unit")
    assert(GameTooltip.tooltipLines == 0, "player without score adds no line")

    -- hook duplication: Update() multiple times should not add multiple hooks
    db.inspectMode = true
    namespace.NoInfo.Update()
    namespace.NoInfo.Update()
    local hooks = (GameTooltip.hooks and GameTooltip.hooks["OnTooltipSetUnit"]) or {}
    assert(#hooks == 1, "OnTooltipSetUnit hook installed only once")

    print("NoInfo tests passed")
end

runTest()
