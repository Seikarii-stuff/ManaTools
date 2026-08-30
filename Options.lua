local ADDON_NAME, ManaTools = ...

ManaTools = ManaTools or {}

local function GetDB()
    NoWasteCoinDB = NoWasteCoinDB or {}
    if NoWasteCoinDB.allowHeroicRaid == nil then
        NoWasteCoinDB.allowHeroicRaid = false
    end
    if NoWasteCoinDB.allowMythicPlus == nil then
        NoWasteCoinDB.allowMythicPlus = false
    end
    return NoWasteCoinDB
end

local function Refresh()
    if NoWasteCoin_Update then
        NoWasteCoin_Update()
    end
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
    GetDB().allowHeroicRaid = self:GetChecked()
    Refresh()
end)

local mythicPlus = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
mythicPlus:SetPoint("TOPLEFT", heroic, "BOTTOMLEFT", 0, -8)
mythicPlus.Text:SetText("Permitir Bonus Roll en Mítico+")
mythicPlus:SetScript("OnClick", function(self)
    GetDB().allowMythicPlus = self:GetChecked()
    Refresh()
end)

panel:SetScript("OnShow", function()
    local db = GetDB()
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
