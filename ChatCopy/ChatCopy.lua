local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.ChatCopy
local ChatCopy = ManaTools.ChatCopy or {}
ManaTools.ChatCopy = ChatCopy

-- Config
local BUTTON_NAME = "ManaToolsChatCopyButton"
local POPUP_NAME = "ManaToolsChatCopyPopup"
local EDITBOX_NAME = "ManaToolsChatCopyEditBox"
local SCROLL_NAME = "ManaToolsChatCopyScrollFrame"
local CLOSE_BUTTON_NAME = "ManaToolsChatCopyCloseButton"

local function GetGeneralChatFrame()
    return _G["ChatFrame1"] or DEFAULT_CHAT_FRAME or _G["DEFAULT_CHAT_FRAME"]
end

local function RegisterEscapeFrame(name)
    if not UISpecialFrames then
        UISpecialFrames = {}
    end
    for _, registeredName in ipairs(UISpecialFrames) do
        if registeredName == name then return end
    end
    table.insert(UISpecialFrames, name)
end

local function ClearPopupText(popup)
    if not popup or not popup.edit then return end
    local edit = popup.edit
    -- Clear temporary stored text and the visible contents
    edit._chatCopyText = nil
    if edit.SetText then
        edit:SetText("")
    end
end

local function ClearButtonScripts(btn)
    if btn and btn.SetScript then
        btn:SetScript("OnClick", nil)
    end
    if btn and btn.Hide then
        btn:Hide()
    end
end

local function ProtectEditBox(edit)
    if not edit then return end
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self._chatCopyText ~= nil and self:GetText() ~= self._chatCopyText then
            self:SetText(self._chatCopyText)
            if self.SetCursorPosition then
                self:SetCursorPosition(0)
            end
            if self.HighlightText then
                self:HighlightText()
            end
        end
    end)
end

local function ConfigurePopupDrag(popup)
    if not popup then return end
    if popup.SetMovable then
        popup:SetMovable(true)
    end
    if popup.RegisterForDrag then
        popup:RegisterForDrag("LeftButton")
    end
    if popup.SetScript then
        popup:SetScript("OnDragStart", function(self)
            if self.StartMoving then
                self:StartMoving()
            end
        end)
        popup:SetScript("OnDragStop", function(self)
            if self.StopMovingOrSizing then
                self:StopMovingOrSizing()
            end
        end)
    end
end

function ChatCopy:CreateButton()
    local globalButton = _G[BUTTON_NAME]
    if globalButton and globalButton ~= self.button then
        ClearButtonScripts(self.button)
        self.button = globalButton
    end

    local btn = self.button or globalButton
    if btn then
        self.button = btn
        btn:SetScript("OnClick", function()
            ChatCopy:OpenPopup()
        end)
        if btn.Show then btn:Show() end
        return
    end

    local general = GetGeneralChatFrame()
    if not general then return end

    btn = CreateFrame("Button", BUTTON_NAME, general)
    btn:SetPoint("BOTTOMRIGHT", general, "BOTTOMRIGHT", -2, -3)
    btn:SetSize(40, 16)
    btn:EnableMouse(true)
    local fs = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("copy")
    btn.fs = fs

    self.button = btn
    btn:SetScript("OnClick", function()
        ChatCopy:OpenPopup()
    end)
end

function ChatCopy:RemoveButton()
    local btn = self.button
    local globalButton = _G[BUTTON_NAME]

    -- Clean both references when they disagree, so stale state cannot leave an active frame behind.
    if btn then
        ClearButtonScripts(btn)
    end
    if globalButton and globalButton ~= btn then
        ClearButtonScripts(globalButton)
        btn = globalButton
    end

    self.button = btn
end

function ChatCopy:BuildTextFromGeneral()
    local general = GetGeneralChatFrame()
    if not general or not general.GetNumMessages then
        return ""
    end

    local max = general:GetNumMessages() or 0
    local parts = {}
    for i = 1, max do
        local msg = nil
        -- GetMessageInfo may return multiple values; first is the message.
        -- WoW can mark secret/hidden values with a sentinel that should never be copied.
        if general.GetMessageInfo then
            msg = select(1, general:GetMessageInfo(i))
        end
        if msg ~= nil and (not issecretvalue or not issecretvalue(msg)) then
            parts[#parts + 1] = tostring(msg)
        end
    end
    return table.concat(parts, "\n")
end

function ChatCopy:CreatePopup()
    local globalPopup = _G[POPUP_NAME]
    if globalPopup and globalPopup ~= self.popup then
        self.popup = globalPopup
    end

    local popup = self.popup or globalPopup
    if popup then
        self.popup = popup
        ConfigurePopupDrag(popup)
        if popup.close and popup.close.SetScript then
            popup.close:SetScript("OnClick", function()
                ClearPopupText(popup)
                popup:Hide()
            end)
        end
        ProtectEditBox(popup.edit)
        RegisterEscapeFrame(POPUP_NAME)
        return popup
    end

    popup = CreateFrame("Frame", POPUP_NAME, UIParent, "BackdropTemplate")
    popup:SetSize(600, 320)
    popup:SetPoint("CENTER", UIParent, "CENTER", -100, 100)
    popup:EnableMouse(true)
    ConfigurePopupDrag(popup)

    if popup.SetBackdrop then
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end

    local title = popup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", popup, "TOP", 0, -12)
    title:SetText("Chat Copy")
    popup.title = title

    local close = CreateFrame("Button", CLOSE_BUTTON_NAME, popup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        ClearPopupText(popup)
        popup:Hide()
    end)
    popup.close = close

    local scroll = CreateFrame("ScrollFrame", SCROLL_NAME, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -38)
    scroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -34, 14)
    popup.scroll = scroll

    local edit = CreateFrame("EditBox", EDITBOX_NAME, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(550)
    edit:SetHeight(260)
    edit:EnableMouse(true)
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    ProtectEditBox(edit)

    popup.edit = edit
    scroll:SetScrollChild(edit)
    self.popup = popup
    RegisterEscapeFrame(POPUP_NAME)
    return popup
end

function ChatCopy:OpenPopup()
    -- Build text on demand only when user clicks
    local text = self:BuildTextFromGeneral()
    local popup = self:CreatePopup()
    local edit = popup and popup.edit

    if edit then
        edit._chatCopyText = text
        edit:SetText(text)
        ProtectEditBox(edit)
        edit:SetScript("OnEscapePressed", function()
            ClearPopupText(popup)
            popup:Hide()
        end)
        -- Keep the copied text visible without pre-selecting it.
        if edit.SetFocus then
            edit:SetFocus()
        end
    end

    if popup and popup.Show then
        popup:Show()
    end
end

function ChatCopy:DestroyPopup()
    local popup = self.popup
    local globalPopup = _G[POPUP_NAME]

    local function hidePopup(frame)
        if not frame then return end
        if frame.edit and frame.edit.SetScript then
            frame.edit:SetScript("OnEscapePressed", nil)
            frame.edit:SetScript("OnTextChanged", nil)
            frame.edit._chatCopyText = nil
        end
        if frame.close and frame.close.SetScript then
            frame.close:SetScript("OnClick", nil)
        end
        if frame.SetScript then
            frame:SetScript("OnDragStart", nil)
            frame:SetScript("OnDragStop", nil)
        end
        if frame.Hide then
            frame:Hide()
        end
    end

    hidePopup(popup)
    if globalPopup and globalPopup ~= popup then
        hidePopup(globalPopup)
        popup = globalPopup
    end

    self.popup = popup
end

function ChatCopy:Enable()
    if self._enabled then return end
    self._enabled = true
    -- create minimal UI for general only
    self:CreateButton()
end

function ChatCopy:Disable()
    -- Always run cleanup, even if the internal state is already disabled or stale.
    self._enabled = false
    self:RemoveButton()
    self:DestroyPopup()
end

function ChatCopy:Update()
    if db.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

-- Initialize on load
ChatCopy:Update()

return ChatCopy
