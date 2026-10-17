local ADDON_NAME, ManaTools = ...

local ProfessionSkip = ManaTools.ProfessionSkip or {}
ManaTools.ProfessionSkip = ProfessionSkip

local function normalizeText(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getPopupText()
    if _G.StaticPopup1Text and type(_G.StaticPopup1Text.GetText) == "function" then
        return normalizeText(_G.StaticPopup1Text:GetText() or "")
    end

    if _G.StaticPopup1 and _G.StaticPopup1.Text and type(_G.StaticPopup1.Text.GetText) == "function" then
        return normalizeText(_G.StaticPopup1.Text:GetText() or "")
    end

    return ""
end

local function getPopupWhich()
    if _G.StaticPopup1 and _G.StaticPopup1.which then
        return normalizeText(tostring(_G.StaticPopup1.which))
    end

    return ""
end

local function isProfessionConfirmationPopup(which, popupText)
    local normalizedWhich = normalizeText(which or "")
    local normalizedText = normalizeText(popupText or "")

    if normalizedWhich:match("profession") or normalizedWhich:match("craft") or normalizedWhich:match("reagent") then
        return true
    end

    local professionPhrases = {
        "estás a punto de completar",
        "about to complete",
        "seguro que quieres continuar",
        "sure you want to continue",
        "confirmar pedido",
        "profession",
        "crafting"
    }

    for _, phrase in ipairs(professionPhrases) do
        if normalizedText:find(phrase, 1, true) then
            return true
        end
    end

    return false
end

local function clickFirstButton()
    local popup = _G.StaticPopup1
    if not popup then
        return
    end

    local button = popup.button1 or _G.StaticPopup1Button1
    if not button then
        return
    end

    if type(button.GetDisabled) == "function" and button:GetDisabled() then
        return
    end

    if type(button.Click) == "function" then
        button:Click()
    end
end

function ProfessionSkip:OnStaticPopupShown(which)
    if not which then
        return
    end

    if isProfessionConfirmationPopup(which, getPopupText()) then
        clickFirstButton()
    end
end

function ProfessionSkip:Install()
    if self.installed then
        return
    end

    self.installed = true

    hooksecurefunc("StaticPopup_Show", function(which)
        if type(which) == "string" then
            ProfessionSkip:OnStaticPopupShown(which)
        end
    end)
end

ProfessionSkip:Install()
