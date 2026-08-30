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

local function HandleManaCommand(message)
    local command = strlower(strtrim(message or ""))

    if command == "coin" then
        if ManaTools.NoWasteCoin.EnableCurrentRollOverride() then
            print("ManaTools: Bonus Roll desbloqueada para esta tirada.")
        else
            print("ManaTools: No hay ninguna Bonus Roll activa.")
        end
        return
    end

    OpenManaToolsSettings()
end

SLASH_MANATOOLS1 = "/mana"
SlashCmdList.MANATOOLS = HandleManaCommand

ManaTools.OpenSettings = OpenManaToolsSettings
