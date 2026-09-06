local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.ChatCopy
local ChatCopy = ManaTools.ChatCopy or {}
ManaTools.ChatCopy = ChatCopy

-- Config
local MAX_LINES = 200

local function GetGeneralChatFrame()
    return _G["ChatFrame1"] or DEFAULT_CHAT_FRAME or _G["DEFAULT_CHAT_FRAME"]
end

function ChatCopy:CreateButton()
    if self.button then return end
    local general = GetGeneralChatFrame()
    if not general then return end

    local btn = CreateFrame("Button", "ManaToolsChatCopyButton", general)
    btn:SetPoint("BOTTOMRIGHT", general, "BOTTOMRIGHT", -2, -3)
    btn:SetSize(40, 16)
    btn:EnableMouse(true)
    local fs = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("copy")
    btn.fs = fs

    btn:SetScript("OnClick", function()
        ChatCopy:OpenPopup()
    end)

    self.button = btn
end

function ChatCopy:RemoveButton()
    if not self.button then return end
    self.button:SetScript("OnClick", nil)
    self.button:Hide()
    _G["ManaToolsChatCopyButton"] = nil
    self.button = nil
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

function ChatCopy:OpenPopup()
    -- Build text on demand only when user clicks
    local text = self:BuildTextFromGeneral()
    if not self.popup then
        local popup = CreateFrame("Frame", "ManaToolsChatCopyPopup", UIParent)
        popup:SetSize(600, 300)
        popup:SetPoint("CENTER", UIParent, "CENTER", -100, 100)
        popup:EnableMouse(true)

        local edit = CreateFrame("EditBox", "ManaToolsChatCopyEditBox", popup)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject("ChatFontNormal")
        edit:SetWidth(560)
        edit:SetHeight(260)
        edit:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -10)
        edit:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
        edit:EnableMouse(true)
        edit:SetScript("OnEscapePressed", function(self) popup:Hide() end)

        popup.edit = edit
        self.popup = popup
    end

    if self.popup and self.popup.edit then
        self.popup.edit:SetText(text)
        -- Mock environments may not implement SetFocus/HighlightText; call if available
        if self.popup.edit.SetFocus then
            self.popup.edit:SetFocus()
        end
    end

    if self.popup and self.popup.Show then
        self.popup:Show()
    end
end

function ChatCopy:DestroyPopup()
    if not self.popup then return end
    if self.popup.edit and self.popup.edit.SetScript then
        self.popup.edit:SetScript("OnEscapePressed", nil)
    end
    if self.popup.SetScript then
        self.popup:SetScript("OnHide", nil)
    end
    if self.popup.Hide then
        self.popup:Hide()
    end
    _G["ManaToolsChatCopyPopup"] = nil
    _G["ManaToolsChatCopyEditBox"] = nil
    self.popup = nil
end

function ChatCopy:Enable()
    if self._enabled then return end
    self._enabled = true
    -- create minimal UI for general only
    self:CreateButton()
end

function ChatCopy:Disable()
    if not self._enabled then return end
    self._enabled = false
    -- remove all UI and scripts created
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
