local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.ManaInvite
if db.enabled == nil then
    db.enabled = false
end

local ManaInvite = ManaTools.ManaInvite or {}
ManaTools.ManaInvite = ManaInvite

ManaInvite.guildMembers = ManaInvite.guildMembers or {}

local function NormalizePlayerName(name)
    if not name then
        return nil
    end

    return strlower(name)
end

local function RebuildGuildMembers()
    wipe(ManaInvite.guildMembers)

    if not GetNumGuildMembers or not GetGuildRosterInfo then
        return
    end

    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name then
            ManaInvite.guildMembers[NormalizePlayerName(name)] = true
        end
    end
end

local function IsGuildMember(name)
    return ManaInvite.guildMembers[NormalizePlayerName(name)] == true
end

function ManaInvite:OnWhisper(message, sender)
    if not IsGuildMember(sender) then
        return
    end

    message = strtrim(message or "")
    if strlower(message) ~= "mana" then
        return
    end

    InviteUnit(sender)
end

function ManaInvite:UpdateEvents()
    local shouldListen = db.enabled == true

    if shouldListen then
        eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    else
        eventFrame:UnregisterEvent("CHAT_MSG_WHISPER")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        RebuildGuildMembers()
        return
    end

    if event == "CHAT_MSG_WHISPER" then
        ManaInvite:OnWhisper(...)
    end
end)

ManaInvite.eventFrame = eventFrame
ManaInvite.NormalizePlayerName = NormalizePlayerName
ManaInvite.IsGuildMember = IsGuildMember
ManaInvite.RebuildGuildMembers = RebuildGuildMembers

-- Keep the roster cache warm independently of whisper processing.
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
RebuildGuildMembers()
ManaInvite:UpdateEvents()
