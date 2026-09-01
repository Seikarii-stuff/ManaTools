local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoInfo
local originalOnShow
local wrapperInstalled = false
local inspectButton

local function HideGameTooltip(self)
    if db.inspectMode then
        return
    end

    local tooltipData = self:GetTooltipData()

    if tooltipData and tooltipData.type == Enum.TooltipDataType.Item then
        return
    end

    if self == GameTooltip then
        local owner = self:GetOwner()

        if owner == MainMenuMicroButton then
            return
        end
    end

    self:Hide()
end

local function NoInfoOnShow(self, ...)
    if originalOnShow then
        originalOnShow(self, ...)
    end

    HideGameTooltip(self)
end

local function UpdateInspectButton()
    if not inspectButton then
        return
    end

    inspectButton:SetShown(db.enabled == true)

    if db.inspectMode then
        inspectButton:SetAlpha(1)
    else
        inspectButton:SetAlpha(0.55)
    end
end

local function ToggleInspectMode()
    if not db.enabled then
        return
    end

    db.inspectMode = not db.inspectMode
    GameTooltip:Hide()
    UpdateInspectButton()
end

local function CreateInspectButton()
    if inspectButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "ManaToolsNoInfoInspectButton", Minimap)
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
    button:RegisterForClicks("LeftButtonUp")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetAtlas("talents-search-match", true)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(26, 26)
    highlight:SetPoint("CENTER")
    highlight:SetAtlas("talents-search-match", true)
    highlight:SetAlpha(0.35)

    button:SetScript("OnClick", ToggleInspectMode)

    inspectButton = button
    UpdateInspectButton()
end

local function Enable()
    if wrapperInstalled then
        return
    end

    originalOnShow = GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow", NoInfoOnShow)
    wrapperInstalled = true
    db.inspectMode = false
    UpdateInspectButton()
end

local function Disable()
    if not wrapperInstalled then
        UpdateInspectButton()
        return
    end

    GameTooltip:SetScript("OnShow", originalOnShow)
    originalOnShow = nil
    wrapperInstalled = false
    db.inspectMode = false
    GameTooltip:Hide()
    UpdateInspectButton()
end

function ManaTools.NoInfo.Update()
    CreateInspectButton()

    if db.enabled then
        Enable()
    else
        Disable()
    end
end

ManaTools.NoInfo.Update()
