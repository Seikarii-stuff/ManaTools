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

    C_PartyInfo.InviteUnit(sender)
end

local eventFrame = CreateFrame("Frame")
local initialized = false
local eventsRegistered = false

function ManaInvite:UpdateEvents()
    local enabled = db.enabled == true

    if enabled and not eventsRegistered then
        eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
        eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
        eventsRegistered = true
        RebuildGuildMembers()
    elseif not enabled and eventsRegistered then
        eventFrame:UnregisterEvent("GUILD_ROSTER_UPDATE")
        eventFrame:UnregisterEvent("CHAT_MSG_WHISPER")
        eventsRegistered = false
    end
end

function ManaInvite:Initialize()
    if initialized then
        self:UpdateEvents()
        return
    end

    initialized = true
    self:UpdateEvents()
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        RebuildGuildMembers()
    elseif event == "CHAT_MSG_WHISPER" then
        ManaInvite:OnWhisper(...)
    end
end)

ManaInvite.eventFrame = eventFrame
ManaInvite.NormalizePlayerName = NormalizePlayerName
ManaInvite.IsGuildMember = IsGuildMember
ManaInvite.RebuildGuildMembers = RebuildGuildMembers

ManaInvite:Initialize()
