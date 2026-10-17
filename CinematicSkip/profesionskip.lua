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
