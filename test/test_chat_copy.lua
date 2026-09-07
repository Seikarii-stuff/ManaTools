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

local function clearChatCopyGlobals()
    _G["ManaToolsChatCopyButton"] = nil
    _G["ManaToolsChatCopyPopup"] = nil
    _G["ManaToolsChatCopyEditBox"] = nil
    _G["UISpecialFrames"] = nil
end

local function newFrame()
    local frame = { scripts = {}, shown = true, text = nil, highlightCount = 0 }
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
    function frame:SetFocus() self.focused = true end
    function frame:HighlightText() self.highlightCount = self.highlightCount + 1 end
    return frame
end

local function CreateFrameMock(_, name)
    local f = newFrame()
    if name then _G[name] = f end
    return f
end

-- 1. Default DB value via Bootstrap
do
    mock.reset({})
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    assert(namespace.DB.ChatCopy ~= nil, "ChatCopy DB exists")
    assert(namespace.DB.ChatCopy.enabled == true, "ChatCopy enabled default is true")
end

-- 2,3 OFF means no button or popup is active
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local namespace = { DB = { ChatCopy = { enabled = false } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    assert(_G.ManaToolsChatCopyButton == nil, "No button created when initially disabled")
    assert(_G.ManaToolsChatCopyPopup == nil, "No popup created when initially disabled")
end

-- 4. OFF registers no chat events
do
    clearChatCopyGlobals()
    mock.reset({})
    loadFile("Bootstrap.lua", "ManaTools", {})
    ManaToolsDB.ChatCopy = { enabled = false }
    local namespace = { DB = ManaToolsDB }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    for k,_ in pairs(mock.events) do
        assert(not k:match("^CHAT_MSG_"), "No CHAT_MSG_* events should be registered when disabled")
    end
end

-- 5,6 ON creates a single button labelled 'copy'
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    _G["ChatFrame1"] = newFrame()
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local btn = _G.ManaToolsChatCopyButton
    assert(btn ~= nil, "Button created when enabled")
    assert(btn.fs and btn.fs.text == "copy", "Button fontstring contains 'copy'")
    assert(btn.shown == true, "Button is shown when enabled")
end

-- 7. No processing in standby
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 0 end
    function general:GetMessageInfo() error("GetMessageInfo should not be called until click") end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    local ok = pcall(function() loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace) end)
    assert(ok, "Module loading must not call GetMessageInfo")
end

-- 8,9 Click collects messages and respects limit
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 5 end
    function general:GetMessageInfo(i) return "msg" .. tostring(i) end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local btn = _G.ManaToolsChatCopyButton
    btn:TriggerScript("OnClick")
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup ~= nil and popup.edit and popup.edit.text ~= nil, "Popup created and editbox filled on click")
    assert(popup.edit.text:match("msg1"), "Popup contains chat text from general")
    assert(popup.edit.highlightCount == 1, "HighlightText is called when available")
end

-- 10. HighlightText is optional for compatibility with mocks/APIs
do
    local popup = _G.ManaToolsChatCopyPopup
    popup.edit.HighlightText = nil
    local ok = pcall(function() namespace.ChatCopy:OpenPopup() end)
    assert(ok, "OpenPopup must work without HighlightText")
end

-- 11. Escape closes popup and popup is registered in UISpecialFrames
do
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup ~= nil, "popup exists for escape test")
    assert(UISpecialFrames and UISpecialFrames[1] == "ManaToolsChatCopyPopup", "Popup is registered in UISpecialFrames")
    popup.edit:TriggerScript("OnEscapePressed")
    assert(popup.shown == false, "Escape hides the popup")
end

-- 12. Disable is idempotent and clears all module-created scripts/active UI
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 1 end
    function general:GetMessageInfo() return "msg" end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local module = namespace.ChatCopy
    local button = module.button
    button:TriggerScript("OnClick")
    local popup = module.popup
    assert(button.shown and popup.shown, "UI is active before Disable")

    module:Disable()
    module:Disable()
    module:Disable()

    assert(module._enabled == false, "Disable leaves module disabled")
    assert(button.shown == false, "Button remains hidden after repeated Disable")
    assert(button:GetScript("OnClick") == nil, "Button has no active script after repeated Disable")
    assert(popup.shown == false, "Popup remains hidden after repeated Disable")
    assert(popup.edit:GetScript("OnEscapePressed") == nil, "Popup has no active script after repeated Disable")
end

-- 13. Repeated OFF/ON cycles reuse one button and never duplicate UI
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local general = newFrame()
    function general:GetNumMessages() return 0 end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = false } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local module = namespace.ChatCopy

    module:Disable()
    module:Enable()
    local firstButton = module.button
    module:Disable()
    module:Enable()
    local secondButton = module.button
    module:Disable()
    module:Enable()
    local thirdButton = module.button
    module:Disable()

    assert(firstButton == secondButton and secondButton == thirdButton, "ON/OFF cycles reuse the same button")
    assert(_G.ManaToolsChatCopyButton == firstButton, "Only one button instance exists")
    assert(firstButton.shown == false, "Final OFF leaves button hidden")
    assert(firstButton:GetScript("OnClick") == nil, "Final OFF leaves button script inactive")

    local popup = module:CreatePopup()
    module:DestroyPopup()
    module:DestroyPopup()
    assert(popup.shown == false, "Repeated popup cleanup leaves it hidden")
    assert(popup.edit:GetScript("OnEscapePressed") == nil, "Repeated popup cleanup leaves scripts inactive")
end

print("ChatCopy tests passed")
