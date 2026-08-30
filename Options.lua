local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoWasteCoin
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

panel:SetScript("OnShow", function()
    heroic:SetChecked(db.allowHeroicRaid)
    mythicPlus:SetChecked(db.allowMythicPlus)
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "ManaTools")
    Settings.RegisterAddOnCategory(category)
    ManaTools.settingsCategory = category
else
    InterfaceOptions_AddCategory(panel)
end
