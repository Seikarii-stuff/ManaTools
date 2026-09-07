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
    _G["ManaToolsChatCopyScrollFrame"] = nil
    _G["ManaToolsChatCopyCloseButton"] = nil
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
    function frame:SetMovable(v) self.movable = v end
    function frame:RegisterForDrag(...) self.dragButtons = {...} end
    function frame:StartMoving() self.moving = true end
    function frame:StopMovingOrSizing() self.moving = false; self.stoppedMoving = true end
    function frame:SetText(v) self.text = v end
    function frame:GetText() return self.text end
    function frame:SetCursorPosition(v) self.cursorPosition = v end
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    function frame:SetBackdrop(v) self.backdrop = v end
    function frame:SetScrollChild(v) self.scrollChild = v end
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
    assert(namespace.DB.ChatCopy.enabled == false, "ChatCopy enabled default is false")
end

-- 1b. /mana copy toggles the feature
 do
    local namespace = {
        DB = { ChatCopy = { enabled = false } },
        ChatCopy = { Update = function() end },
    }
    local output = {}
    local originalPrint = print
    print = function(msg) table.insert(output, msg) end
    loadFile("SlashCmd.lua", "ManaTools", namespace)
    SlashCmdList.MANATOOLS("copy")
    assert(namespace.DB.ChatCopy.enabled == true, "First /mana copy enables ChatCopy")
    assert(output[#output] == "ManaTools: Chat Copy activado.", "First /mana copy prints enabled status")
    SlashCmdList.MANATOOLS("copy")
    assert(namespace.DB.ChatCopy.enabled == false, "Second /mana copy disables ChatCopy")
    assert(output[#output] == "ManaTools: Chat Copy desactivado.", "Second /mana copy prints disabled status")
    print = originalPrint
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

-- 8,9 Click collects all available chat messages without auto-selection
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
    assert(popup.edit.text:match("msg5"), "Popup includes the newest chat message")
    assert(popup.edit.highlightCount == 0, "Automatic HighlightText is disabled")
    _G.ChatCopyTestModule = namespace.ChatCopy
end

-- 10. Popup is a framed window with scrollable, read-only copy text, close button and drag support
do
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup.backdrop ~= nil, "Popup has a background/border backdrop")
    assert(popup.scroll ~= nil and popup.scroll.scrollChild == popup.edit, "Popup uses a ScrollFrame for the editbox")
    assert(popup.close ~= nil, "Popup has a close button")
    assert(popup.close:GetScript("OnClick") ~= nil, "Close button has an active click handler")
    assert(popup.movable == true, "Popup is movable")
    assert(popup.dragButtons and popup.dragButtons[1] == "LeftButton", "Popup registers left-button dragging")
    assert(popup:GetScript("OnDragStart") ~= nil, "Popup has an OnDragStart handler")
    assert(popup:GetScript("OnDragStop") ~= nil, "Popup has an OnDragStop handler")

    popup:TriggerScript("OnDragStart")
    assert(popup.moving == true, "OnDragStart starts moving the popup")
    popup:TriggerScript("OnDragStop")
    assert(popup.moving == false and popup.stoppedMoving == true, "OnDragStop stops moving the popup")

    local originalText = popup.edit.text
    popup.edit:SetText("user input should not persist")
    popup.edit:TriggerScript("OnTextChanged", true)
    assert(popup.edit.text == originalText, "User input cannot modify the copied chat text")
end

-- 11. HighlightText is optional for compatibility with mocks/APIs
do
    local popup = _G.ManaToolsChatCopyPopup
    popup.edit.HighlightText = nil
    local ok = pcall(function() _G.ChatCopyTestModule:OpenPopup() end)
    assert(ok, "OpenPopup must work without HighlightText")
end

-- 12. Escape closes popup and popup is registered in UISpecialFrames
do
    local popup = _G.ManaToolsChatCopyPopup
    assert(popup ~= nil, "popup exists for escape test")
    assert(UISpecialFrames and UISpecialFrames[1] == "ManaToolsChatCopyPopup", "Popup is registered in UISpecialFrames")
    popup.edit:TriggerScript("OnEscapePressed")
    assert(popup.shown == false, "Escape hides the popup")
end

-- 12b. Close via X clears temporary text and empties EditBox
do
    local module = _G.ChatCopyTestModule
    assert(module, "ChatCopy module available for close tests")
    module:OpenPopup()
    local popup = module.popup
    assert(popup and popup.edit and popup.edit._chatCopyText ~= nil, "Popup edit has _chatCopyText before close")
    popup.close:TriggerScript("OnClick")
    assert(popup.edit._chatCopyText == nil, "Close button clears _chatCopyText")
    assert((popup.edit.text or "") == "", "EditBox text is empty after close")
    assert(popup.shown == false, "Popup is hidden after close")
end

-- 12c. Escape clears temporary text and empties EditBox
do
    local module = _G.ChatCopyTestModule
    module:OpenPopup()
    local popup = module.popup
    assert(popup and popup.edit and popup.edit._chatCopyText ~= nil, "Popup edit has _chatCopyText before escape clear")
    popup.edit:TriggerScript("OnEscapePressed")
    assert(popup.edit._chatCopyText == nil, "Escape clears _chatCopyText")
    assert((popup.edit.text or "") == "", "EditBox text is empty after escape")
    assert(popup.shown == false, "Popup is hidden after escape clear")
end

-- 12d. Reopen rebuilds text via BuildTextFromGeneral
do
    local module = _G.ChatCopyTestModule
    -- Set a predictable general for reopen
    local general = newFrame()
    function general:GetNumMessages() return 3 end
    function general:GetMessageInfo(i) return "reopen" .. tostring(i) end
    _G["ChatFrame1"] = general
    module:OpenPopup()
    local popup = module.popup
    assert(popup.edit and popup.edit._chatCopyText ~= nil, "Reopen sets new _chatCopyText")
    assert(popup.edit.text:match("reopen1"), "Reopen rebuilds text from general")
end

-- 13. Disable is idempotent and clears all module-created scripts/active UI
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
    assert(popup.edit:GetScript("OnEscapePressed") == nil, "Popup has no active escape script after repeated Disable")
    assert(popup.edit:GetScript("OnTextChanged") == nil, "Popup has no active text-change script after repeated Disable")
    assert(popup.close:GetScript("OnClick") == nil, "Close button has no active script after Disable")
    assert(popup:GetScript("OnDragStart") == nil, "Popup has no active drag-start script after Disable")
    assert(popup:GetScript("OnDragStop") == nil, "Popup has no active drag-stop script after Disable")
end

-- 14. Disable also cleans up when internal references are stale
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    local general = newFrame()
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)
    local module = namespace.ChatCopy
    local button = module.button
    module:OpenPopup()
    local popup = module.popup

    module.button = nil
    module.popup = nil
    module._enabled = false
    module:Disable()

    assert(button.shown == false, "Disable hides a button found through the global")
    assert(button:GetScript("OnClick") == nil, "Disable clears a stale button script")
    assert(popup.shown == false, "Disable hides a popup found through the global")
    assert(popup.edit:GetScript("OnEscapePressed") == nil, "Disable clears a stale popup escape script")
    assert(popup.close:GetScript("OnClick") == nil, "Disable clears a stale popup close script")
    assert(popup:GetScript("OnDragStart") == nil, "Disable clears a stale popup drag-start script")
    assert(popup:GetScript("OnDragStop") == nil, "Disable clears a stale popup drag-stop script")
end

-- 15. Repeated OFF/ON cycles reuse one button and never duplicate UI
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
end

-- 16. Re-enabling after OFF restores popup scripts for the reused window
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
    module:OpenPopup()
    local popup = module.popup

    module:Disable()
    module:Enable()
    module:OpenPopup()

    assert(module.popup == popup, "Popup is reused after ON/OFF")
    assert(popup.close:GetScript("OnClick") ~= nil, "Close button is restored after re-enable")
    assert(popup.edit:GetScript("OnTextChanged") ~= nil, "Read-only protection is restored after re-enable")
    assert(popup.edit:GetScript("OnEscapePressed") ~= nil, "Escape handler is restored after re-enable")
    assert(popup:GetScript("OnDragStart") ~= nil, "Drag-start handler is restored after re-enable")
    assert(popup:GetScript("OnDragStop") ~= nil, "Drag-stop handler is restored after re-enable")
end

-- 17. Secret chat entries are ignored instead of being copied
do
    clearChatCopyGlobals()
    CreateFrame = CreateFrameMock
    issecretvalue = function(value) return value == "secret" end
    local general = newFrame()
    function general:GetNumMessages() return 3 end
    function general:GetMessageInfo(index)
        local messages = { "hello", "secret", "world" }
        return messages[index]
    end
    _G["ChatFrame1"] = general
    local namespace = { DB = { ChatCopy = { enabled = true } } }
    loadFile("ChatCopy/ChatCopy.lua", "ManaTools", namespace)

    local text = namespace.ChatCopy:BuildTextFromGeneral()
    assert(text == "hello\nworld", "Secret chat messages should be skipped")
end

print("ChatCopy tests passed")
