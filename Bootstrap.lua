-- ManaTools bootstrap / shared addon namespace.
-- Keep this file intentionally small: it runs before the feature modules.
local ADDON_NAME, ManaTools = ...

ManaTools = ManaTools or {}
ManaToolsDB = ManaToolsDB or {}
ManaTools.DB = ManaToolsDB
ManaTools.DB.NoWasteCoin = ManaTools.DB.NoWasteCoin or {}
ManaTools.NoWasteCoin = ManaTools.NoWasteCoin or {}
ManaTools.ADDON_NAME = ADDON_NAME
ManaTools.VERSION = "1.1.0"
