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

local function Enable()
    if wrapperInstalled then
        return
    end

    db.inspectMode = NormalizeInspectMode(db.inspectMode)
    originalOnShow = GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow", NoInfoOnShow)

    if not unitHookInstalled and GameTooltip.HookScript then
        local function unitHook(self)
            if db.inspectMode ~= 2 then
                return
            end

            if not self or not self.GetUnit then
                return
            end

            local _, unit = self:GetUnit()
            if type(unit) ~= "string" or unit == "" then
                return
            end

            if not UnitIsPlayer or not UnitIsPlayer(unit) then
                return
            end

            if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                return
            end

            local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            if not summary or summary.currentSeasonScore == nil then
                return
            end

            local text = "Mythic+ Rating: " .. tostring(summary.currentSeasonScore)
            if self.NumLines and self.GetLine then
                local count = self:NumLines()
                for i = 1, count do
                    local line = self.GetLine(self, i)
                    if line == text then
                        return
                    end
                end
            end

            if self.AddLine then
                self:AddLine(text)
            end
        end

        local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", unitHook)
        if ok then
            unitHookInstalled = true
        end
    end

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
