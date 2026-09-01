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

-- Follow the same angle-based model used by LibDBIcon-1.0:
-- the button is positioned from the minimap center, and dragging changes only
-- the saved angle. This avoids pixel-dragging and keeps the icon on the rim.
local function SetMinimapPosition(button, angle)
    angle = angle or 225
    local radians = math.rad(angle)
    local x, y = math.cos(radians), math.sin(radians)

    -- Keep the icon just outside the minimap. The value is based on the
    -- current minimap size so it also follows resized minimaps.
    local radius = (Minimap:GetWidth() * 0.5) + 14
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end

local function UpdateMinimapPosition(button)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()

    px, py = px / scale, py / scale

    db.minimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
    SetMinimapPosition(button, db.minimapAngle)
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
    button:RegisterForDrag("LeftButton")
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
        if mouseButton == "LeftButton" and not self.isMoving then
            ToggleInspectMode()
        end
    end)

    button:SetScript("OnDragStart", function(self, mouseButton)
        if mouseButton ~= "LeftButton" or not IsShiftKeyDown() then
            return
        end

        self.isMoving = true
        self:SetScript("OnUpdate", function(owner)
            UpdateMinimapPosition(owner)
        end)
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStop", function(self)
        if not self.isMoving then
            return
        end

        UpdateMinimapPosition(self)
        self:SetScript("OnUpdate", nil)
        self.isMoving = false
    end)

    inspectButton = button
    SetMinimapPosition(button, db.minimapAngle or 225)
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
