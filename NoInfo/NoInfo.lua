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
    inspectButton:SetAlpha(db.inspectMode and 1 or 0.55)
end

local function ToggleInspectMode()
    if not db.enabled then
        return
    end

    db.inspectMode = not db.inspectMode
    GameTooltip:Hide()
    UpdateInspectButton()
end

local function SetMinimapPosition(button, angle)
    local radius = (Minimap:GetWidth() * 0.5) + 14
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

local function UpdateMinimapPositionFromCursor(button)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale
    local cx, cy = Minimap:GetCenter()
    local angle = math.deg(math.atan2(y - cy, x - cx))

    db.minimapAngle = angle
    SetMinimapPosition(button, angle)
end

local function CreateInspectButton()
    if inspectButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "ManaToolsNoInfoInspectButton", Minimap)
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)

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

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and not self.wasDragging then
            ToggleInspectMode()
        end
        self.wasDragging = false
    end)

    button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton ~= "LeftButton" or not IsShiftKeyDown() then
            return
        end

        self.wasDragging = true
        self.dragging = true
        self:SetScript("OnUpdate", function(owner)
            UpdateMinimapPositionFromCursor(owner)
        end)
    end)

    button:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton ~= "LeftButton" or not self.dragging then
            return
        end

        UpdateMinimapPositionFromCursor(self)
        self.dragging = false
        self:SetScript("OnUpdate", nil)
    end)

    inspectButton = button
    SetMinimapPosition(button, db.minimapAngle or 0)
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
