local pendingInviteHide = false

local function ResolveInviteRole(allowTank, allowHealer, allowDamage)
	local specIndex
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
		specIndex = C_SpecializationInfo.GetSpecialization()
	elseif GetSpecialization then
		specIndex = GetSpecialization()
	end

	local specRole = specIndex and GetSpecializationRole and GetSpecializationRole(specIndex)
	if specRole == "TANK" and allowTank then
		return "TANK"
	elseif specRole == "HEALER" and allowHealer then
		return "HEALER"
	elseif specRole == "DAMAGER" and allowDamage then
		return "DAMAGER"
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

	if allowTank then
		return "TANK"
	elseif allowHealer then
		return "HEALER"
	elseif allowDamage then
		return "DAMAGER"
	end
end

local function SetInviteRoleCheckbox(button, checked)
	if button and button.checkButton then
		button.checkButton:SetChecked(not not checked)
	end
end

local function SelectInviteRole(role)
	SetInviteRoleCheckbox(LFGInvitePopupRoleButtonTank, role == "TANK")
	SetInviteRoleCheckbox(LFGInvitePopupRoleButtonHealer, role == "HEALER")
	SetInviteRoleCheckbox(LFGInvitePopupRoleButtonDPS, role == "DAMAGER")
end

local function HideInvitePopups()
	local numDialogs = STATICPOPUP_NUMDIALOGS or 4
	for i = 1, numDialogs do
		local popup = _G["StaticPopup" .. i]
		if popup and (popup.which == "PARTY_INVITE" or popup.which == "PARTY_INVITE_XREALM") then
			popup.inviteAccepted = 1
		end
	end

	StaticPopup_Hide("PARTY_INVITE")
	StaticPopup_Hide("PARTY_INVITE_XREALM")

	if LFGInvitePopup and LFGInvitePopup.IsShown and LFGInvitePopup:IsShown() then
		if StaticPopupSpecial_Hide then
			StaticPopupSpecial_Hide(LFGInvitePopup)
		else
			LFGInvitePopup:Hide()
		end
	end
end

local function AcceptPartyInvite(_, isTank, isHealer, isDamage)
	if isTank or isHealer or isDamage then
		local role = ResolveInviteRole(isTank, isHealer, isDamage)
		if role then
			SelectInviteRole(role)
		end
	end

	AcceptGroup()
	pendingInviteHide = true
end

local function AcceptRoleCheck()
	if CompleteLFGRoleCheck(true) and LFDRoleCheckPopup and StaticPopupSpecial_Hide then
		StaticPopupSpecial_Hide(LFDRoleCheckPopup)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PARTY_INVITE_REQUEST")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:SetScript("OnEvent", function(_, event, ...)
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
