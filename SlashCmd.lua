local ADDON_NAME, ManaTools = ...

local function OpenManaToolsSettings()
    if Settings and Settings.OpenToCategory and ManaTools.settingsCategory then
        Settings.OpenToCategory(ManaTools.settingsCategory:GetID())
        return
    end

    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("ManaTools")
        InterfaceOptionsFrame_OpenToCategory("ManaTools")
    end
end

SLASH_MANATOOLS1 = "/mana"
SlashCmdList.MANATOOLS = function()
    OpenManaToolsSettings()
end

ManaTools.OpenSettings = OpenManaToolsSettings
