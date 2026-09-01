local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.NoInfo
local hooked = false

local function HideGameTooltip(self)
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

local function Enable()
    if hooked then
        return
    end

    GameTooltip:HookScript("OnShow", HideGameTooltip)
    hooked = true
end

local function Disable()
    if not hooked then
        return
    end

    GameTooltip:UnhookScript("OnShow", HideGameTooltip)
    hooked = false
    GameTooltip:Hide()
end

function ManaTools.NoInfo.Update()
    if db.enabled then
        Enable()
    else
        Disable()
    end
end

ManaTools.NoInfo.Update()
