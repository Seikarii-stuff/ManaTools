-- ManaTools bootstrap / shared addon namespace.
-- Keep this file intentionally small: it runs before the feature modules.
local ADDON_NAME, ManaTools = ...

ManaTools = ManaTools or {}
ManaToolsDB = ManaToolsDB or {}
ManaTools.DB = ManaToolsDB
ManaTools.DB.NoWasteCoin = ManaTools.DB.NoWasteCoin or {}
ManaTools.DB.CinematicSkip = ManaTools.DB.CinematicSkip or {}
ManaTools.DB.NoInfo = ManaTools.DB.NoInfo or {}
if ManaTools.DB.CinematicSkip.enabled == nil then
    ManaTools.DB.CinematicSkip.enabled = true
end
if ManaTools.DB.NoInfo.enabled == nil then
    ManaTools.DB.NoInfo.enabled = true
end
if ManaTools.DB.NoInfo.inspectMode == nil then
    ManaTools.DB.NoInfo.inspectMode = 0
elseif ManaTools.DB.NoInfo.inspectMode == true then
    ManaTools.DB.NoInfo.inspectMode = 1
elseif ManaTools.DB.NoInfo.inspectMode == false then
    ManaTools.DB.NoInfo.inspectMode = 0
end
ManaTools.NoWasteCoin = ManaTools.NoWasteCoin or {}
ManaTools.CinematicSkip = ManaTools.CinematicSkip or {}
ManaTools.NoInfo = ManaTools.NoInfo or {}
ManaTools.ADDON_NAME = ADDON_NAME
ManaTools.VERSION = "1.1.0"
