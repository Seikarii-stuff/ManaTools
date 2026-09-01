local function HideGameTooltip(self)
    local tooltipData = self:GetTooltipData()

    if tooltipData and tooltipData.type == Enum.TooltipDataType.Item then
        return
    end

    if self == GameTooltip then
        local owner = self:GetOwner()

        if owner == GameMenuButtonAddons then
            return
        end
    end

    self:Hide()
end

GameTooltip:HookScript("OnShow", HideGameTooltip)
