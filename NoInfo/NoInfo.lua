local function HideGameTooltip(self)
    local tooltipData = self:GetTooltipData()

    if tooltipData and tooltipData.type == Enum.TooltipDataType.Item then
        return
    end

    self:Hide()
end

GameTooltip:HookScript("OnShow", HideGameTooltip)
