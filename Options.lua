local ADDON_NAME, ManaTools = ...

local cinematicSkipDB = ManaTools.DB.CinematicSkip
local noInfoDB = ManaTools.DB.NoInfo
local chatCopyDB = ManaTools.DB.ChatCopy

local panel = CreateFrame("Frame")
panel.name = "ManaTools"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ManaTools")

local cinematicSkipTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
cinematicSkipTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
cinematicSkipTitle:SetText("Cinematic Skip")

local cinematicSkip = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
cinematicSkip:SetPoint("TOPLEFT", cinematicSkipTitle, "BOTTOMLEFT", 0, -8)
cinematicSkip.Text:SetText("Enable Cinematic Skip")
cinematicSkip:SetScript("OnClick", function(self)
    cinematicSkipDB.enabled = self:GetChecked() == true
    ManaTools.CinematicSkip:UpdateEvents()
end)

local noInfoTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
noInfoTitle:SetPoint("TOPLEFT", cinematicSkip, "BOTTOMLEFT", 0, -18)
noInfoTitle:SetText("NoInfo")

local noInfo = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
noInfo:SetPoint("TOPLEFT", noInfoTitle, "BOTTOMLEFT", 0, -8)
noInfo.Text:SetText("Hide unnecessary tooltips")
noInfo:SetScript("OnClick", function(self)
    noInfoDB.enabled = self:GetChecked() == true
    ManaTools.NoInfo.Update()
end)

local chatCopyTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
chatCopyTitle:SetPoint("TOPLEFT", noInfo, "BOTTOMLEFT", 0, -18)
chatCopyTitle:SetText("Chat Copy")

local chatCopy = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
chatCopy:SetPoint("TOPLEFT", chatCopyTitle, "BOTTOMLEFT", 0, -8)
chatCopy.Text:SetText("Enable Chat Copy (General only)")
chatCopy:SetScript("OnClick", function(self)
    chatCopyDB.enabled = self:GetChecked() == true
    if ManaTools.ChatCopy and ManaTools.ChatCopy.Update then
        ManaTools.ChatCopy:Update()
    end
end)

panel:SetScript("OnShow", function()
    cinematicSkip:SetChecked(cinematicSkipDB.enabled)
    noInfo:SetChecked(noInfoDB.enabled)
    chatCopy:SetChecked(chatCopyDB.enabled)
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "ManaTools")
    Settings.RegisterAddOnCategory(category)
    ManaTools.settingsCategory = category
else
    InterfaceOptions_AddCategory(panel)
end
