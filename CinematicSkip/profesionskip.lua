local ADDON_NAME, ManaTools = ...

local ProfessionSkip = ManaTools.ProfessionSkip or {}
ManaTools.ProfessionSkip = ProfessionSkip

local function isPlayerDead()
    if type(UnitIsDeadOrGhost) == "function" and UnitIsDeadOrGhost("player") then
        return true
    end

    if type(UnitIsDead) == "function" and UnitIsDead("player") then
        return true
    end

    return false
end

local function isButtonVisible(button)
    if not button then
        return false
    end

    if type(button.IsShown) == "function" then
        return button:IsShown()
    end

    return true
end

local function hasBinaryChoicePopup()
    local popup = _G.StaticPopup1
    if not popup then
        return false
    end

    local button1 = popup.button1 or _G.StaticPopup1Button1
    local button2 = popup.button2 or _G.StaticPopup1Button2
    if not button1 or not button2 then
        return false
    end

    if not isButtonVisible(button1) or not isButtonVisible(button2) then
        return false
    end

    for i = 3, 5 do
        local extraButton = popup["button" .. i] or _G["StaticPopup1Button" .. i]
        if extraButton and isButtonVisible(extraButton) then
            return false
        end
    end

    return true
end

local function clickFirstButton()
    if not hasBinaryChoicePopup() then
        return
    end

    local popup = _G.StaticPopup1
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

function ProfessionSkip:OnStaticPopupShown()
    if isPlayerDead() then
        return
    end

    clickFirstButton()
end

function ProfessionSkip:Install()
    if self.installed then
        return
    end

    self.installed = true

    hooksecurefunc("StaticPopup_Show", function()
        ProfessionSkip:OnStaticPopupShown()
    end)
end

ProfessionSkip:Install()
