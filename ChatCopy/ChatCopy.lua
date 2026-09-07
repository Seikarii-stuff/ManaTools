local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.ChatCopy
local ChatCopy = ManaTools.ChatCopy or {}
ManaTools.ChatCopy = ChatCopy

-- Config
local MAX_LINES = 200
local BUTTON_NAME = "ManaToolsChatCopyButton"
local POPUP_NAME = "ManaToolsChatCopyPopup"
local EDITBOX_NAME = "ManaToolsChatCopyEditBox"

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

function ChatCopy:CreateButton()
    local btn = self.button or _G[BUTTON_NAME]
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
    local btn = self.button or _G[BUTTON_NAME]
    if not btn then
        self.button = nil
        return
    end

    -- Keep the frame for reuse, but leave it completely inactive while disabled.
    btn:SetScript("OnClick", nil)
    if btn.Hide then btn:Hide() end
    self.button = btn
end

function ChatCopy:BuildTextFromGeneral()
    local general = GetGeneralChatFrame()
    if not general or not general.GetNumMessages then
        return ""
    end

    local max = general:GetNumMessages() or 0
    local start = math.max(1, max - (MAX_LINES - 1))
    local parts = {}
    for i = start, max do
        local msg = nil
        -- GetMessageInfo may return multiple values; first is the message
        if general.GetMessageInfo then
            msg = select(1, general:GetMessageInfo(i))
        end
        if msg then
            parts[#parts + 1] = tostring(msg)
        end
    end
    return table.concat(parts, "\n")
end

function ChatCopy:CreatePopup()
    local popup = self.popup or _G[POPUP_NAME]
    if popup then
        self.popup = popup
        RegisterEscapeFrame(POPUP_NAME)
        return popup
    end

    popup = CreateFrame("Frame", POPUP_NAME, UIParent)
    popup:SetSize(600, 300)
    popup:SetPoint("CENTER", UIParent, "CENTER", -100, 100)
    popup:EnableMouse(true)

    local edit = CreateFrame("EditBox", EDITBOX_NAME, popup)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(560)
    edit:SetHeight(260)
    edit:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -10)
    edit:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    edit:EnableMouse(true)

    popup.edit = edit
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
        edit:SetText(text)
        edit:SetScript("OnEscapePressed", function(self)
            popup:Hide()
        end)
        -- Mock environments may not implement SetFocus/HighlightText; call if available.
        if edit.SetFocus then
            edit:SetFocus()
        end
        if edit.HighlightText then
            edit:HighlightText()
        end
    end

    if popup and popup.Show then
        popup:Show()
    end
end

function ChatCopy:DestroyPopup()
    local popup = self.popup or _G[POPUP_NAME]
    if not popup then
        self.popup = nil
        return
    end

    if popup.edit and popup.edit.SetScript then
        popup.edit:SetScript("OnEscapePressed", nil)
    end
    if popup.SetScript then
        popup:SetScript("OnHide", nil)
    end
    if popup.Hide then
        popup:Hide()
    end
    -- Keep the frame for reuse; no scripts remain active while disabled.
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
