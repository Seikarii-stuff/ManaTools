local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoInfo
local originalOnShow
local wrapperInstalled = false
local inspectButton
local unitHookInstalled = false

local function NormalizeInspectMode(value)
    if value == true then
        return 1
    end
    if value == false then
        return 0
    end
    if value == nil then
        return 0
    end
    if value == 1 or value == 2 then
        return value
    end
    return 0
end

local function HideGameTooltip(self)
    if db.inspectMode ~= 0 then
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

    db.inspectMode = NormalizeInspectMode(db.inspectMode)
    inspectButton:SetShown(db.enabled == true)

    local mode = NormalizeInspectMode(db.inspectMode)
    if mode == 2 then
        inspectButton:SetAlpha(1)
        if inspectButton.icon and inspectButton.icon.SetVertexColor then
            inspectButton.icon:SetVertexColor(1, 0.2, 0.2)
        end
        if inspectButton.highlight and inspectButton.highlight.SetVertexColor then
            inspectButton.highlight:SetVertexColor(1, 0.2, 0.2)
        end
    elseif mode == 1 then
        inspectButton:SetAlpha(1)
        if inspectButton.icon and inspectButton.icon.SetVertexColor then
            inspectButton.icon:SetVertexColor(0.55, 0.75, 1)
        end
        if inspectButton.highlight and inspectButton.highlight.SetVertexColor then
            inspectButton.highlight:SetVertexColor(0.55, 0.75, 1)
        end
    else
        inspectButton:SetAlpha(0.55)
        if inspectButton.icon and inspectButton.icon.SetVertexColor then
            inspectButton.icon:SetVertexColor(0.35, 0.55, 1)
        end
        if inspectButton.highlight and inspectButton.highlight.SetVertexColor then
            inspectButton.highlight:SetVertexColor(0.35, 0.55, 1)
        end
    end
end

local function ToggleInspectMode()
    if not db.enabled then
        return
    end

    if IsShiftKeyDown and IsShiftKeyDown() then
        db.inspectMode = 2
    elseif db.inspectMode == 0 then
        db.inspectMode = 1
    else
        db.inspectMode = 0
    end

    GameTooltip:Hide()
    UpdateInspectButton()
end

local function SetFixedMinimapPosition(button)
    local radius = (Minimap:GetWidth() * 0.5) + 14
    local angle = math.rad(225)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CreateInspectButton()
    if inspectButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "ManaToolsNoInfoInspectButton", Minimap)
    button:SetSize(30, 30)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetAtlas("talents-search-match", true)
    if icon.SetVertexColor then
        icon:SetVertexColor(0.35, 0.55, 1)
    else
        function icon:SetVertexColor(r, g, b) self.r, self.g, self.b = r, g, b end
    end
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(26, 26)
    highlight:SetPoint("CENTER")
    highlight:SetAtlas("talents-search-match", true)
    highlight:SetAlpha(0.35)
    if highlight.SetVertexColor then
        highlight:SetVertexColor(0.35, 0.55, 1)
    end
    button.highlight = highlight

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then return end
        if not db.enabled then return end

        if IsShiftKeyDown and IsShiftKeyDown() then
            db.inspectMode = 2
        elseif db.inspectMode == 0 then
            db.inspectMode = 1
        else
            db.inspectMode = 0
        end

        GameTooltip:Hide()
        UpdateInspectButton()
    end)

    inspectButton = button
    SetFixedMinimapPosition(button)
    UpdateInspectButton()
end

local function GetSafeTooltipUnit(tooltip)
    if not tooltip then
        return
    end

    local unit
    if GetTooltipUnit then
        local _, displayedUnit = GetTooltipUnit(tooltip)
        if displayedUnit and (not issecretvalue or not issecretvalue(displayedUnit)) then
            unit = displayedUnit
        end
    elseif tooltip.GetUnit then
        local _, displayedUnit = tooltip:GetUnit()
        if displayedUnit and (not issecretvalue or not issecretvalue(displayedUnit)) then
            unit = displayedUnit
        end
    end

    if type(unit) == "string" and unit ~= "" then
        return unit
    end

    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if owner and owner.GetAttribute then
        local ownerUnit = owner:GetAttribute("unit")
        if ownerUnit and (not issecretvalue or not issecretvalue(ownerUnit)) and type(ownerUnit) == "string" and ownerUnit ~= "" then
            return ownerUnit
        end
    end
end

local function InstallMythicPlusTooltipHook()
    if unitHookInstalled then
        return
    end

    local function unitHook(self)
        if db.inspectMode ~= 2 then return end

        if not self then
            return
        end

        local unit = GetSafeTooltipUnit(self)
        if not unit then
            return
        end

        if not UnitIsPlayer or UnitIsPlayer(unit) ~= true then
            return
        end

        if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
            return
        end

        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
        local score = summary and summary.currentSeasonScore
        local text
        if score ~= nil and (not issecretvalue or not issecretvalue(score)) then
            text = "Mythic+ Rating: " .. tostring(score)
        else
            text = "Mythic+ Rating: nil"
        end

        if self.noInfoMythicPlusLine then
            return
        end

        self.noInfoMythicPlusLine = true
        self:AddLine(text)
    end

    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, unitHook)
        unitHookInstalled = true
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", unitHook)
        unitHookInstalled = true
    end

    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self.noInfoMythicPlusLine = nil
        end)
    end
end

local function Enable()
    if wrapperInstalled then
        return
    end

    db.inspectMode = NormalizeInspectMode(db.inspectMode)
    originalOnShow = GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow", NoInfoOnShow)

    InstallMythicPlusTooltipHook()

    wrapperInstalled = true
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
    db.inspectMode = 0
    GameTooltip.noInfoMythicPlusLine = nil
    GameTooltip:Hide()
    UpdateInspectButton()
end

function ManaTools.NoInfo.Update()
    db.inspectMode = NormalizeInspectMode(db.inspectMode)
    CreateInspectButton()

    if db.enabled then
        Enable()
    else
        Disable()
    end
end

ManaTools.NoInfo.Update()