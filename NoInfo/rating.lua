local ADDON_NAME, ManaTools = ...

local function AddRatingToTooltip(tooltip, data)
    if not data or data.type ~= Enum.TooltipDataType.Unit then
        return
    end

    local unit
    for _, line in ipairs(data.lines or {}) do
        if line.type == Enum.TooltipDataLineType.UnitName then
            unit = line.unitToken
            break
        end
    end

    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return
    end

    if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        return
    end

    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
    if not summary then
        return
    end

    tooltip:AddLine("Mythic+ Rating: " .. tostring(summary.currentSeasonScore or "?"))
    tooltip:Show()
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, AddRatingToTooltip)
