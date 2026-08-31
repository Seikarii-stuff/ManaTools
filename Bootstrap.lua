-- ManaTools bootstrap / shared addon namespace.
-- Keep this file intentionally small: it runs before the feature modules.
local ADDON_NAME, ManaTools = ...

ManaTools = ManaTools or {}
ManaToolsDB = ManaToolsDB or {}
ManaTools.DB = ManaToolsDB
ManaTools.DB.NoWasteCoin = ManaTools.DB.NoWasteCoin or {}
ManaTools.DB.ManaInvite = ManaTools.DB.ManaInvite or {}
ManaTools.DB.CinematicSkip = ManaTools.DB.CinematicSkip or {}
if ManaTools.DB.CinematicSkip.enabled == nil then
    ManaTools.DB.CinematicSkip.enabled = true
end
ManaTools.NoWasteCoin = ManaTools.NoWasteCoin or {}
ManaTools.ManaInvite = ManaTools.ManaInvite or {}
ManaTools.CinematicSkip = ManaTools.CinematicSkip or {}
ManaTools.ADDON_NAME = ADDON_NAME
ManaTools.VERSION = "1.1.0"
