local panel = CreateFrame("Frame")
panel.name = "NoWasteCoin"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("NoWasteCoin")

local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
description:SetText("Controls where the Nebulous Voidcore bonus roll can be spent.")
description:SetWidth(600)
description:SetJustifyH("LEFT")

local heroic = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
heroic:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
heroic.Text:SetText("Allow bonus roll in Heroic raids")
heroic:SetChecked(NoWasteCoinDB.allowHeroicRaid)
heroic:SetScript("OnClick", function(self)
    NoWasteCoinDB.allowHeroicRaid = self:GetChecked()
    NoWasteCoin_Update()
end)

local mythicPlus = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
mythicPlus:SetPoint("TOPLEFT", heroic, "BOTTOMLEFT", 0, -10)
mythicPlus.Text:SetText("Allow bonus roll in Mythic+")
mythicPlus:SetChecked(NoWasteCoinDB.allowMythicPlus)
mythicPlus:SetScript("OnClick", function(self)
    NoWasteCoinDB.allowMythicPlus = self:GetChecked()
    NoWasteCoin_Update()
end)

panel:SetScript("OnShow", function()
    heroic:SetChecked(NoWasteCoinDB.allowHeroicRaid)
    mythicPlus:SetChecked(NoWasteCoinDB.allowMythicPlus)
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, "NoWasteCoin")
Settings.RegisterAddOnCategory(category)
