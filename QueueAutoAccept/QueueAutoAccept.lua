local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.QueueAutoAccept
local QueueAutoAccept = ManaTools.QueueAutoAccept or {}
ManaTools.QueueAutoAccept = QueueAutoAccept

local eventFrame = CreateFrame("Frame")
local eventsRegistered = false
local pendingInviteHide = false

local function IsEnabled()
    return db and db.enabled == true
end

local function SetInviteRoleCheckbox(button, checked)
    if button and button.SetChecked then
        button:SetChecked(checked == true)
    end
end

local function SelectInviteRole(role)
    local buttons = {
        TANK = _G.LFGInvitePopupRoleButtonTank and _G.LFGInvitePopupRoleButtonTank.checkButton,
        HEALER = _G.LFGInvitePopupRoleButtonHealer and _G.LFGInvitePopupRoleButtonHealer.checkButton,
        DAMAGER = _G.LFGInvitePopupRoleButtonDPS and _G.LFGInvitePopupRoleButtonDPS.checkButton,
    }

    for key, button in pairs(buttons) do
        SetInviteRoleCheckbox(button, key == role)
    end
end

local function ResolveInviteRole(allowTank, allowHealer, allowDamage)
    local function isAllowed(role)
        if role == "TANK" then
            return allowTank == true
        elseif role == "HEALER" then
            return allowHealer == true
        elseif role == "DAMAGER" then
            return allowDamage == true
        end
        return false
    end

    local specIndex
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        specIndex = C_SpecializationInfo.GetSpecialization()
    elseif GetSpecialization then
        specIndex = GetSpecialization()
    end

    local specRole = specIndex and GetSpecializationRole and GetSpecializationRole(specIndex)
    if specRole and isAllowed(specRole) then
        return specRole
    end

    if GetLFGRoles then
        local _, tank, healer, dps = GetLFGRoles()
        if tank and allowTank then
            return "TANK"
        elseif healer and allowHealer then
            return "HEALER"
        elseif dps and allowDamage then
            return "DAMAGER"
        end
    end

    return nil
end

local function HideInvitePopups()
    local numDialogs = STATICPOPUP_NUMDIALOGS or 4
    for i = 1, numDialogs do
        local popup = _G["StaticPopup" .. i]
        if popup and popup.which and (popup.which == "PARTY_INVITE" or popup.which == "PARTY_INVITE_XREALM") then
            if popup.Hide then
                popup:Hide()
            end
            popup.inviteAccepted = 1
        end
    end

    if StaticPopup_Hide then
        StaticPopup_Hide("PARTY_INVITE")
        StaticPopup_Hide("PARTY_INVITE_XREALM")
    end

    if LFGInvitePopup then
        if StaticPopupSpecial_Hide then
            StaticPopupSpecial_Hide(LFGInvitePopup)
        elseif LFGInvitePopup.Hide then
            LFGInvitePopup:Hide()
        end
    end
end

local function AcceptPartyInvite(_, isTank, isHealer, isDamage)
    if not IsEnabled() then
        return
    end

    local hasRoleFilter = isTank ~= nil or isHealer ~= nil or isDamage ~= nil
    if not hasRoleFilter then
        local role = ResolveInviteRole(true, true, true)
        if role then
            SelectInviteRole(role)
        end
        if AcceptGroup then
            AcceptGroup()
        end
        pendingInviteHide = true
        return
    end

    if type(isTank) ~= "boolean" and type(isHealer) ~= "boolean" and type(isDamage) ~= "boolean" then
        return
    end

    local role = ResolveInviteRole(isTank == true, isHealer == true, isDamage == true)
    if not role then
        return
    end

    SelectInviteRole(role)
    if AcceptGroup then
        AcceptGroup()
    end
    pendingInviteHide = true
end

local function AcceptRoleCheck()
    if not IsEnabled() then
        return
    end

    if CompleteLFGRoleCheck then
        CompleteLFGRoleCheck(true)
    end

    if LFDRoleCheckPopup then
        if StaticPopupSpecial_Hide then
            StaticPopupSpecial_Hide(LFDRoleCheckPopup)
        elseif LFDRoleCheckPopup.Hide then
            LFDRoleCheckPopup:Hide()
        end
    end
end

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
        pendingInviteHide = false
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PARTY_INVITE_REQUEST" then
        AcceptPartyInvite(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        if pendingInviteHide then
            pendingInviteHide = false
            HideInvitePopups()
        end
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        AcceptRoleCheck()
    end
end)

QueueAutoAccept.eventFrame = eventFrame
QueueAutoAccept.Update = QueueAutoAccept.Update or function() end
QueueAutoAccept:Update()
