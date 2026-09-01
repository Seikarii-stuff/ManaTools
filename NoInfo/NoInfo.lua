local function HideGameTooltip(self)
    self:Hide()
end

GameTooltip:HookScript("OnShow", HideGameTooltip)
