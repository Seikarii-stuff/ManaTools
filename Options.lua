local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoWasteCoin
local manaInviteDB = ManaTools.DB.ManaInvite
local cinematicSkipDB = ManaTools.DB.CinematicSkip
local noInfoDB = ManaTools.DB.NoInfo

local function Refresh()
    ManaTools.NoWasteCoin.Update()
end

local panel = CreateFrame("Frame")
panel.name = "ManaTools"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ManaTools")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("NoWasteCoin")

local info = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
info:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
info:SetJustifyH("LEFT")
info:SetText("La moneda solo se permite en Banda Mítica. Banda Heroica y Mítico+ pueden habilitarse con las excepciones siguientes.")

local heroic = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
heroic:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -16)
heroic.Text:SetText("Permitir Bonus Roll en Banda Heroica")
heroic:SetScript("OnClick", function(self)
    db.allowHeroicRaid = self:GetChecked()
    Refresh()
end)

local mythicPlus = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
mythicPlus:SetPoint("TOPLEFT", heroic, "BOTTOMLEFT", 0, -8)
mythicPlus.Text:SetText("Permitir Bonus Roll en Mítico+")
mythicPlus:SetScript("OnClick", function(self)
    db.allowMythicPlus = self:GetChecked()
    Refresh()
end)

local inviteTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
inviteTitle:SetPoint("TOPLEFT", mythicPlus, "BOTTOMLEFT", 0, -18)
inviteTitle:SetText("Mana Invite")

local invite = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
invite:SetPoint("TOPLEFT", inviteTitle, "BOTTOMLEFT", 0, -8)
invite.Text:SetText("Automatically invite guild members who whisper \"mana\"")
invite:SetScript("OnClick", function(self)
    manaInviteDB.enabled = self:GetChecked() == true
    ManaTools.ManaInvite.UpdateEvents()
end)

local cinematicSkipTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
cinematicSkipTitle:SetPoint("TOPLEFT", invite, "BOTTOMLEFT", 0, -18)
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

panel:SetScript("OnShow", function()
    heroic:SetChecked(db.allowHeroicRaid)
    mythicPlus:SetChecked(db.allowMythicPlus)
    invite:SetChecked(manaInviteDB.enabled)
    cinematicSkip:SetChecked(cinematicSkipDB.enabled)
    noInfo:SetChecked(noInfoDB.enabled)
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "ManaTools")
    Settings.RegisterAddOnCategory(category)
    ManaTools.settingsCategory = category
else
    InterfaceOptions_AddCategory(panel)
end
