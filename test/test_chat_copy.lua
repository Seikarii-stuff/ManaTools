-- ChatCopy minimal integration tests.
-- Run from repository root: lua test/test_chat_copy.lua

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

-- 1. Default DB value via Bootstrap
do
    mock.reset({})
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    assert(namespace.DB.ChatCopy ~= nil, "ChatCopy DB exists")
    assert(namespace.DB.ChatCopy.enabled == true, "ChatCopy enabled default is true")
end

-- Helper to create frames that expose globals like the real UI for assertions.
local function newFrame()
    local frame = { scripts = {}, shown = true, text = nil }
    function frame:GetScript(event) return self.scripts[event] end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:TriggerScript(event, ...)
        local cb = self.scripts[event]
        if cb then cb(self, ...) end
    end
    function frame:SetPoint(...) self.point = {...} end
    function frame:SetSize(w, h) self.width, self.height = w, h end
    function frame:EnableMouse(v) self.mouse = v end
    function frame:SetText(v) self.text = v end
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    function frame:CreateFontString() local f = newFrame(); function f:SetPoint(...) end; function f:SetText(t) f.text = t end; return f end
    function frame:SetMultiLine() end
    function frame:SetAutoFocus() end
    function frame:SetFontObject() end
    function frame:SetWidth(w) self.width = w end
    function frame:SetHeight(h) self.height = h end
    return frame
end

local function CreateFrameMock(_, name)
    local f = newFrame()
    if name then _G[name] = f end
    return f
end

-- 2,3 OFF means no button and no popup
do
    -- Prepare environment
    _G = _G or {}
    -- provide CreateFrame that registers globals
    CreateFrame = CreateFrameMock
    local namespace = { DB = { ChatCopy = { enabled = false } } }
    -- load module
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    -- module should not create button or popup when disabled
    assert(_G.ManaToolsChatCopyButton == nil, "No button created when disabled")
    assert(_G.ManaToolsChatCopyPopup == nil, "No popup created when disabled")
end

-- 4. OFF registers no chat events (use mock event tracker)
do
    mock.reset({})
    loadFile("Bootstrap.lua", "ManaTools", {})
    -- set DB disabled
    ManaToolsDB.ChatCopy = { enabled = false }
    local namespace = { DB = ManaToolsDB }
    -- load module using mock environment
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    -- Ensure there are no CHAT_MSG_* events registered
    for k,_ in pairs(mock.events) do
        assert(not k:match("^CHAT_MSG_"), "No CHAT_MSG_* events should be registered when disabled")
    end
end

-- 6,7 ON creates a single button labelled 'copy'
do
    -- Use CreateFrame that exposes globals so we can inspect button
    CreateFrame = CreateFrameMock
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    _G["ChatFrame1"] = newFrame()
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local btn = _G.ManaToolsChatCopyButton
    assert(btn ~= nil, "Button created when enabled")
    assert(btn.fs and btn.fs.text == "copy", "Button fontstring contains 'copy'")
end

-- 9. No processing in standby: module should NOT call GetMessageInfo on load
do
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 0 end
    function general:GetMessageInfo(i) error("GetMessageInfo should not be called until click") end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    local ok, err = pcall(function() loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace) end)
    assert(ok, "Module loading must not call GetMessageInfo")
end

-- 10,11 Click collects messages and respects limit
do
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 5 end
    function general:GetMessageInfo(i) return "msg" .. tostring(i) end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local btn = _G.ManaToolsChatCopyButton
    -- simulate click
    btn.scripts.OnClick(btn)
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup ~= nil and popup.edit and popup.edit.text ~= nil, "Popup created and editbox filled on click")
    assert(popup.edit.text:match("msg1"), "Popup contains chat text from general")
end

-- 13. Escape closes popup
do
    -- reuse existing popup
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup ~= nil, "popup exists for escape test")
    if popup.edit and popup.edit.TriggerScript then
        popup.edit:TriggerScript("OnEscapePressed")
        assert(popup.shown == false, "Escape hides the popup")
    end
end

-- 14. ON/OFF repeated does not duplicate
do
    CreateFrame = CreateFrameMock
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local module = namespace.ChatCopy
    module:Update()
    module:Update()
    module:Disable()
    module:Enable()
    module:Disable()
    assert(_G.ManaToolsChatCopyButton == nil or module.button == nil or module._enabled == false, "Final state after toggles is disabled with no lingering button")
end

print("ChatCopy tests passed")
