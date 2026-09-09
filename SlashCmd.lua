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
    -- any other argument opens settings
    OpenManaToolsSettings()
end

local function HandleCoinCommand()
    if ManaTools.NoWasteCoin and ManaTools.NoWasteCoin.EnableCurrentRollOverride then
        if ManaTools.NoWasteCoin.EnableCurrentRollOverride() then
            print("ManaTools: Bonus Roll desbloqueada para esta tirada.")
        else
            print("ManaTools: No hay ninguna Bonus Roll activa.")
        end
    else
        print("ManaTools: NoWasteCoin no disponible.")
    end
end

SLASH_MANATOOLS1 = "/mana"
SlashCmdList.MANATOOLS = HandleManaCommand

SLASH_MANACOIN1 = "/coin"
SlashCmdList.MANACOIN = HandleCoinCommand

local function HandleCopyCommand()
    if not ManaTools.DB or not ManaTools.DB.ChatCopy then
        print("ManaTools: No hay configuración de Chat Copy disponible.")
        return
    end

    ManaTools.DB.ChatCopy.enabled = not ManaTools.DB.ChatCopy.enabled
    if ManaTools.ChatCopy and ManaTools.ChatCopy.Update then
        ManaTools.ChatCopy:Update()
    end

    if ManaTools.DB.ChatCopy.enabled then
        print("ManaTools: Chat Copy activado.")
    else
        print("ManaTools: Chat Copy desactivado.")
    end
end

SLASH_MANCOPY1 = "/copy"
SlashCmdList.MANCOPY = HandleCopyCommand

ManaTools.OpenSettings = OpenManaToolsSettings
