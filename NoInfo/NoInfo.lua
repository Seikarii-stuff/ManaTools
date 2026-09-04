local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoInfo
local originalOnShow
local wrapperInstalled = false
local inspectButton
local unitHookInstalled = false

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
    if inspectButton.icon and inspectButton.icon.SetVertexColor then
        if db.inspectMode then
            inspectButton.icon:SetVertexColor(1, 0, 0)
        else
            inspectButton.icon:SetVertexColor(1, 1, 1)
        end
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
        icon:SetVertexColor(1, 1, 1)
    else
        function icon:SetVertexColor(r, g, b) self.r, self.g, self.b = r, g, b end
    end
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(26, 26)
    highlight:SetPoint("CENTER")
    highlight:SetAtlas("talents-search-match", true)
    highlight:SetAlpha(0.35)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then return end

        if IsShiftKeyDown and IsShiftKeyDown() then
            if not db.enabled then return end
            db.inspectMode = true
            UpdateInspectButton()
        else
            db.inspectMode = false
            GameTooltip:Hide()
            UpdateInspectButton()
        end
    end)

    inspectButton = button
    SetFixedMinimapPosition(button)
    UpdateInspectButton()
end

local function Enable()
    if wrapperInstalled then
        return
    end

    originalOnShow = GameTooltip:GetScript("OnShow")
    GameTooltip:SetScript("OnShow", NoInfoOnShow)
    -- install unit tooltip hook once
    if not unitHookInstalled and GameTooltip.HookScript then
        local function unitHook(self, ...)
            if not db.inspectMode then
                return
            end

            local unit = ...
            if not unit and self.GetUnit then
                local ok, u = pcall(self.GetUnit, self)
                unit = ok and u or nil
            end

            if not unit then
                return
            end

            if not UnitIsPlayer or not UnitIsPlayer(unit) then
                return
            end

            if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                return
            end

            local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            if not summary or not summary.currentSeasonScore then
                return
            end

            if GameTooltip.AddLine then
                GameTooltip:AddLine("Mythic+ Rating: " .. tostring(summary.currentSeasonScore))
                if GameTooltip.Show then
                    GameTooltip:Show()
                end
            end
        end

        local ok, err = pcall(function() GameTooltip:HookScript("OnTooltipSetUnit", unitHook) end)
        if not ok then
            -- try method form explicitly (defensive), ignore if both fail
            local ok2, err2 = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", unitHook)
            if ok2 then
                unitHookInstalled = true
            else
                -- unable to install hook; avoid throwing in Enable()
                unitHookInstalled = false
            end
        else
            unitHookInstalled = true
        end
    end
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
