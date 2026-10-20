local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.QueueAutoAccept
local QueueAutoAccept = ManaTools.QueueAutoAccept or {}
ManaTools.QueueAutoAccept = QueueAutoAccept
QueueAutoAccept.AutoInvite = QueueAutoAccept.AutoInvite or {}
local AutoInvite = QueueAutoAccept.AutoInvite

local eventFrame = CreateFrame("Frame")
local eventsRegistered = false

function QueueAutoAccept:Enable()
    db.enabled = true
    self:Update()
end

function QueueAutoAccept:Disable()
    db.enabled = false
    self:Update()
end

function QueueAutoAccept:Update()
    if not db then
        return
    end

    local enabled = db.enabled == true
    if enabled and not eventsRegistered then
        eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
        eventsRegistered = true
    elseif not enabled and eventsRegistered then
        eventFrame:UnregisterEvent("PARTY_INVITE_REQUEST")
        eventFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:UnregisterEvent("LFG_ROLE_CHECK_SHOW")
        eventsRegistered = false
        if AutoInvite and AutoInvite.ResetPendingInviteHide then
            AutoInvite:ResetPendingInviteHide()
        end
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if AutoInvite and AutoInvite.HandleEvent then
        AutoInvite:HandleEvent(event, ...)
    end
end)

QueueAutoAccept.eventFrame = eventFrame
QueueAutoAccept.Update = QueueAutoAccept.Update or function() end
QueueAutoAccept:Update()
