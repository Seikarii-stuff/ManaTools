-- Addon:	QueueRoleAutoAccept
-- Author:	Spielstein@Curse



-----------------------------
-- constants and objects   --
-----------------------------

------@class ns
local ns = select(2, ...)

-- string constants
-- TODO: add localization when you're feeling fancy
local STRINGS = {}

STRINGS["QRAA_TOGGLE_TRUE_MESSAGE"] = "|cff00ff00Automation running|r"
STRINGS["QRAA_TOGGLE_FALSE_MESSAGE"] = "|cffff0000Automation stopped|r"

STRINGS["QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_ALLOWED"] = "|cff00ff00Allowlist activated|r"
STRINGS["QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_NOT_ALLOWED"] = "|cffffff00Allowlist activated|r"
STRINGS["QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_NOT_ALLOWED_EXPLAIN"] = "Current Grp. leader not in Allowlist"
STRINGS["QRAA_TOGGLE_ALLOW_FALSE_MESSAGE"] = "|cffff0000Allowlist deactivated|r"

STRINGS["QRAA_TOGGLE_TRUE_BROKER"] = "QRAA: |cff00ff00Running|r"
STRINGS["QRAA_TOGGLE_FALSE_BROKER"] = "QRAA: |cffff0000Stopped|r"

STRINGS["QRAA_TOGGLE_TRUE_W_ALLOW_BROKER_L_ALLOWED"] = "QRAA: |cff00ff00Running w. Allowlist|r"
STRINGS["QRAA_TOGGLE_TRUE_W_ALLOW_BROKER_L_NOT_ALLOWED"] = "QRAA: |cffffff00Running w. Allowlist|r"
STRINGS["QRAA_TOGGLE_FALSE_W_ALLOW_BROKER"] = "QRAA: |cffff0000Stopped w. Allowlist|r"

STRINGS["QRAA_ROLE_CHOOSE_WINDOW_TITLE"] = "Choose your roles:"
STRINGS["QRAA_ROLE_ADDPLAYER_WINDOW_TITLE"] = "Add Player to Allowlist:"


local AVAILABLE_ROLES = {}
AVAILABLE_ROLES.tank, AVAILABLE_ROLES.healer, AVAILABLE_ROLES.dps = C_LFGList.GetAvailableRoles()

ns.CurrentLeader = ""

-- default values for 
local defaults = {
	char = {
		minimap = {
			hide = false,
		},
		automationRunning = false, -- variable to save the current automation status 
		allowlistCheck = false,
		blocklistCheck = false,
	},
	global = {
		allowlist = {},
		blocklist = {},
	}
}

-- main ace3 addon object
local QueueRoleAutoAccept = LibStub("AceAddon-3.0"):NewAddon(
	"QueueRoleAutoAccept",
	"AceConsole-3.0",
	"AceEvent-3.0"
	)
ns.QueueRoleAutoAccept = QueueRoleAutoAccept

local function GetCharacterNameAndRealm(unit)
    local name, realm = UnitName(unit)
    realm = realm or GetRealmName() -- Fallback in case realm is nil
    return name .. "-" .. realm
end
ns.GetCharacterNameAndRealm = GetCharacterNameAndRealm

local function buttonClicked(button, buttonPressed)
	local altKey = IsAltKeyDown()

	if altKey then

		if buttonPressed == "LeftButton" then
			QueueRoleAutoAccept:ToggleAllowlistCheck()
		elseif buttonPressed == "RightButton" then
			QueueRoleAutoAccept:OpenAllowlist()
		end

	else
		
		if buttonPressed == "LeftButton" then
			QueueRoleAutoAccept:ToggleAutomation()
		elseif buttonPressed == "RightButton" then
			QueueRoleAutoAccept.roleCheckWindow:Show()
		end
	end
end

local tooltipText = {
	"|cffffffffQueueRoleAutoAccept|r",
	" ",
	'Left click: Toggle queue role automation',
	'Right click: Show queue role selection',
	'Alt + Left click: Toggle allowlist for queue role automation',
	'Alt + Right click: Show allowlist',
	'To toggle minimap button, type /qr minimap',
}

-- data broker object
local qraaLDB = LibStub("LibDataBroker-1.1"):NewDataObject("QueueRoleAutoAccept", {  
	type = "data source",
	text = "QRAA",
	icon = "Interface\\Icons\\inv_misc_groupneedmore",
	OnClick = function(button, buttonPressed)
		buttonClicked(button, buttonPressed)
	end,
	OnTooltipShow = function(tooltip)
		for i = 1, #tooltipText do tooltip:AddLine(tooltipText[i]) end
	end,
}) -- define onclick function of the data broker + minimap icon as the toggle function

-- loading minimap icon library
local qraaMinimapIcon = LibStub("LibDBIcon-1.0")



-----------------------------
-- functions               --
-----------------------------

-- taken adapted from blizz lua code:
-- LFGFrame.lua (https://github.com/Ennie/wow-ui-source/blob/master/FrameXML/LFGFrame.lua)
-- LFDFrame.xml (https://github.com/Ennie/wow-ui-source/blob/master/FrameXML/LFDFrame.xml)
-- LFGFrame.xml (https://github.com/Ennie/wow-ui-source/blob/master/FrameXML/LFGFrame.xml)


local function getDynamicBrokerText(automationEnabled, allowlistEnabled, IsLeaderinAllowlist)
	if allowlistEnabled then
		if automationEnabled then
			if IsLeaderinAllowlist then
				return STRINGS["QRAA_TOGGLE_TRUE_W_ALLOW_BROKER_L_ALLOWED"]
			else
				return STRINGS["QRAA_TOGGLE_TRUE_W_ALLOW_BROKER_L_NOT_ALLOWED"]
			end
		else
			return STRINGS["QRAA_TOGGLE_FALSE_W_ALLOW_BROKER"]
		end
	else
		if automationEnabled then
			return STRINGS["QRAA_TOGGLE_TRUE_BROKER"]
		else
			return STRINGS["QRAA_TOGGLE_FALSE_BROKER"]
		end
	end
end

local function getDynamicMinimapColor(automationEnabled, allowlistEnabled, IsLeaderinAllowlist)
	if allowlistEnabled then
		if automationEnabled then
			if IsLeaderinAllowlist then
				return 0, 1, 0 -- green
			else
				return 1, 1, 0 -- yellow
			end
		else
			return 1, 0, 0 -- red
		end
	else
		if automationEnabled then
			return 0, 1, 0 -- green
		else
			return 1, 0, 0 -- red
		end
	end
end

local function GetTexCoordsForRole(role)
	local textureHeight, textureWidth = 256, 256;
	local roleHeight, roleWidth = 67, 67;
	
	if ( role == "GUIDE" ) then
		return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "TANK" ) then
		return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "HEALER" ) then
		return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "DPS" ) then
		return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	else
		error("Unknown role: "..tostring(role));
	end
end

local function CreateRoleButton(name, parent, id, width, height)
	local button = CreateFrame("Button", "QRAA_RoleCheckWindow_" .. name, parent and parent or UIParent)
	button:SetSize(width and width or 48, height and height or 48)
	button:SetID(id and id or 0)

	local texture = button:CreateTexture()
	texture:SetAllPoints(button)
	texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
	texture:SetAlpha(0.5)
	texture:SetTexCoord(0, 0.2614, 0.5234, 0.7851)
	texture:SetDrawLayer("OVERLAY")
	button.texture = texture
	button:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")

	local checkButton = CreateFrame("CheckButton", nil, button)
	checkButton:SetSize(24, 24)
	checkButton:SetPoint("BOTTOMLEFT", -5, -5)
	checkButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	checkButton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	checkButton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	checkButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	checkButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	button.checkButton = checkButton

	button:SetScript("OnClick", function()
		checkButton:Click()
	end)

	local function PermanentlyDisableRoleButton(self)
		button.permDisabled = true;
		button:Disable();
		SetDesaturation(button:GetNormalTexture(), button);
		button.texture:Show();
		button.texture:SetAlpha(0.7);
		button.checkButton:Hide();
		button.checkButton:Disable();
	end
	button.PermanentlyDisableRoleButton = PermanentlyDisableRoleButton

	return button
end


-----------------------------
-- role check window       --
-----------------------------

local roleCheckWindow = CreateFrame("Frame", "QRAA_RoleCheckWindow", UIParent, "BackdropTemplate")
roleCheckWindow:SetFrameStrata("DIALOG")
roleCheckWindow:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
roleCheckWindow:SetSize(306,180)
roleCheckWindow:SetPoint("CENTER")
roleCheckWindow:SetMovable(true)
roleCheckWindow:EnableMouse(true)
roleCheckWindow:RegisterForDrag("LeftButton")
roleCheckWindow:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
roleCheckWindow:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)
roleCheckWindow:Hide()
QueueRoleAutoAccept.roleCheckWindow = roleCheckWindow


local fontstring = roleCheckWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
fontstring:SetText(STRINGS.QRAA_ROLE_CHOOSE_WINDOW_TITLE)
fontstring:SetPoint("TOP", 0, -15)
roleCheckWindow.fontstring = fontstring

local tankButton = CreateRoleButton("RoleButtonTank", roleCheckWindow, 2, 70, 70)
tankButton:SetSize(70, 70)
tankButton:SetPoint("TOPLEFT", 35, -45)
tankButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole("TANK"))
roleCheckWindow.tankButton = tankButton

local healerButton = CreateRoleButton("RoleButtonHealer", roleCheckWindow, 3, 70, 70)
healerButton:SetSize(70, 70)
healerButton:SetPoint("LEFT", tankButton, "RIGHT", 15, 0)
healerButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole("HEALER"))
roleCheckWindow.healerButton = healerButton

local dpsButton = CreateRoleButton("RoleButtonDPS", roleCheckWindow, 1, 70, 70)
dpsButton:SetSize(70, 70)
dpsButton:SetPoint("LEFT", healerButton, "RIGHT", 15, 0)
dpsButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole("DPS"))
roleCheckWindow.dpsButton = dpsButton

local acceptButton = CreateFrame("Button", "QRAA_RoleCheckWindow_AcceptButton", roleCheckWindow, "UIPanelButtonTemplate")
acceptButton:SetSize(115, 22)
acceptButton:SetPoint("BOTTOM", roleCheckWindow, 0, 15)
acceptButton:SetText(OKAY)
acceptButton:SetScript("OnClick", function()
	if not tankButton.permDisabled then
		local tank = tankButton.checkButton:GetChecked()
		QueueRoleAutoAccept:SetTankRole(tank)
	end
	if not healerButton.permDisabled then
		local healer = healerButton.checkButton:GetChecked()
		QueueRoleAutoAccept:SetHealerRole(healer)
	end
	if not dpsButton.permDisabled then
		local dps = dpsButton.checkButton:GetChecked()
		QueueRoleAutoAccept:SetDPSRole(dps)
	end
	roleCheckWindow:Hide()
end)
roleCheckWindow.acceptButton = acceptButton


roleCheckWindow:SetScript("OnShow", function()
	local tankEnabled, healerEnabled, dpsEnabled = QueueRoleAutoAccept:GetEnabledRoles()

	if not tankEnabled and not tankButton.permDisabled then
		tankButton:PermanentlyDisableRoleButton()
	end
	if not healerEnabled and not healerButton.permDisabled then
		healerButton:PermanentlyDisableRoleButton()
	end
	if not dpsEnabled and not dpsButton.permDisabled then
		dpsButton:PermanentlyDisableRoleButton()
	end

	local tank, healer, dps = QueueRoleAutoAccept:GetRolesCheckStatus()

	tankButton.checkButton:SetChecked(tank)
	healerButton.checkButton:SetChecked(healer)
	dpsButton.checkButton:SetChecked(dps)
end)


-----------------------------
-- functions               --
-----------------------------


-- Called when the addon is loaded
function QueueRoleAutoAccept:OnInitialize() 
	
	-- register slash commands
	self:RegisterChatCommand("qr", "SlashCommand")
	self:RegisterChatCommand("queuerole", "SlashCommand")

	-- load ace library for between session variable storing
	self.db = LibStub("AceDB-3.0"):New("QueueRoleAutoAcceptDB", defaults)

	-- initialize minimap icon with reference to db variables
	qraaMinimapIcon:Register("QueueRoleAutoAccept", qraaLDB, self.db.char.minimap)
	qraaMinimapIcon:AddButtonToCompartment("QueueRoleAutoAccept")

	-- hook auto accept script into blizz's role check window (if window shows call provided funcion)
	LFDRoleCheckPopupAcceptButton:SetScript("OnShow", self.OnShowScript)

	-- update broker and minimap icon based on db variables on startup
	QueueRoleAutoAccept:UpdateUI(self.db.char.automationRunning, self.db.char.allowlistCheck)

	--ns.allowlistWindow = CreateAllowlistWindow(UIParent)
	ns.allowlistWindow:DataChanged()

	self:Print('To toggle minimap button, type /qr minimap')
end


-- toggle the automation and update relevant ui elements
function QueueRoleAutoAccept:ToggleAutomation()
	-- update the db variable
	self.db.char.automationRunning = not self.db.char.automationRunning
	-- update ui elements
	self:UpdateUI(self.db.char.automationRunning, self.db.char.allowlistCheck)
	-- print new automation status to chat
	self:Print(self.db.char.automationRunning and STRINGS.QRAA_TOGGLE_TRUE_MESSAGE or STRINGS.QRAA_TOGGLE_FALSE_MESSAGE)
end


-- toggle the visibility of the minimap icon (hide/show the icon if wished)
function QueueRoleAutoAccept:ToggleMinimapIconVisibility()
	-- invert visibility boolean
	self.db.char.minimap.hide = not self.db.char.minimap.hide
	-- if minimap icon should be hidden ...
	if self.db.char.minimap.hide then
		-- ... hide minimap icon
		qraaMinimapIcon:Hide("QueueRoleAutoAccept")
	else
		-- ... else show minimap icon
		qraaMinimapIcon:Show("QueueRoleAutoAccept")
	end
end

function QueueRoleAutoAccept:ToggleAllowlistCheck()
	-- update the db variable
	self.db.char.allowlistCheck = not self.db.char.allowlistCheck
	-- update ui elements
	self:UpdateUI(self.db.char.automationRunning, self.db.char.allowlistCheck)
	-- print new automation status to chat
	local isLeaderinAllowlist = QueueRoleAutoAccept:IsLeaderinAllowlist()
	self:Print(self.db.char.allowlistCheck and
		(isLeaderinAllowlist and STRINGS.QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_ALLOWED or STRINGS.QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_NOT_ALLOWED )
		or STRINGS.QRAA_TOGGLE_ALLOW_FALSE_MESSAGE)
	if not isLeaderinAllowlist and self.db.char.allowlistCheck then
		self:Print(STRINGS.QRAA_TOGGLE_ALLOW_TRUE_MESSAGE_L_NOT_ALLOWED_EXPLAIN)
	end
end

function QueueRoleAutoAccept:UpdateGroupLeader()
	-- if not in group, leader name empty
	if not IsInGroup() then
        ns.CurrentLeader = ""
    end
    
	-- if in raid or party search for party lead and save it for later use
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = (prefix == "party" and i == GetNumGroupMembers()) and "player" or prefix..i
		local unitName = ns.GetCharacterNameAndRealm(unit)
        if UnitIsGroupLeader(unit) then
            ns.CurrentLeader = unitName
			QueueRoleAutoAccept:UpdateUI(ns.QueueRoleAutoAccept.db.char.automationRunning, ns.QueueRoleAutoAccept.db.char.allowlistCheck)
        end
	end
end

-- check for the current leaders name in the allowlist
function QueueRoleAutoAccept:IsLeaderinAllowlist()
	return ns.QueueRoleAutoAccept.db.global.allowlist[ns.CurrentLeader] and true or false
end

-- check for the enabled status of the allowlist feature
function QueueRoleAutoAccept:IsAllowlistEnabled()
	return ns.QueueRoleAutoAccept.db.char.allowlistCheck
end

-- returns (allowlist is enabled) -> (the party leader is in the allowlist) for the auto accept function
function QueueRoleAutoAccept:AllowlistCheck()
	return (not QueueRoleAutoAccept:IsAllowlistEnabled()) or QueueRoleAutoAccept:IsLeaderinAllowlist()
end

-- 
function QueueRoleAutoAccept:OpenAllowlist()
	if ns.allowlistWindow and ns.allowlistWindow.Show then
		ns.allowlistWindow:Show()
	end
end

--
function QueueRoleAutoAccept:SetTankRole(status)
	-- if LFDQueueFrameRoleButtonTank.checkButton:IsEnabled() then
	-- 	LFDQueueFrameRoleButtonTank.checkButton:SetChecked(status)
	-- end
	if AVAILABLE_ROLES.tank then
		LFDQueueFrameRoleButtonTank.checkButton:SetChecked(status)
	end
end


--
function QueueRoleAutoAccept:SetHealerRole(status)
	-- if LFDQueueFrameRoleButtonHealer.checkButton:IsEnabled() then
	-- 	LFDQueueFrameRoleButtonHealer.checkButton:SetChecked(status)
	-- end
	if AVAILABLE_ROLES.healer then
		LFDQueueFrameRoleButtonHealer.checkButton:SetChecked(status)
	end
end


--
function QueueRoleAutoAccept:SetDPSRole(status)
	-- if LFDQueueFrameRoleButtonDPS.checkButton:IsEnabled() then
	-- 	LFDQueueFrameRoleButtonDPS.checkButton:SetChecked(status)
	-- end
	if AVAILABLE_ROLES.dps then
		LFDQueueFrameRoleButtonDPS.checkButton:SetChecked(status)
	end
end


--
function QueueRoleAutoAccept:GetEnabledRoles()
	-- return LFDQueueFrameRoleButtonTank.checkButton:IsEnabled(),
	--        LFDQueueFrameRoleButtonHealer.checkButton:IsEnabled(),
	--        LFDQueueFrameRoleButtonDPS.checkButton:IsEnabled()
	return AVAILABLE_ROLES.tank,
           AVAILABLE_ROLES.healer,
	       AVAILABLE_ROLES.dps
end


--
function QueueRoleAutoAccept:GetRolesCheckStatus()
	return LFDQueueFrameRoleButtonTank.checkButton:GetChecked(),
	       LFDQueueFrameRoleButtonHealer.checkButton:GetChecked(),
	       LFDQueueFrameRoleButtonDPS.checkButton:GetChecked()
end


-- update both relevant ui elements: data broker + minimap icon
function QueueRoleAutoAccept:UpdateUI(automationRunning, allowlistEnabled)
	local isLeaderinAllowlist = QueueRoleAutoAccept:IsLeaderinAllowlist()
	-- Update MinimapIcon
	self:UpdateMinimapButton(automationRunning, allowlistEnabled, isLeaderinAllowlist)
	-- Update DataBroker
	self:UpdateBrokerText(automationRunning, allowlistEnabled, isLeaderinAllowlist)
end


-- update the data broker text to reflect the new automation status
function QueueRoleAutoAccept:UpdateBrokerText(automationRunning, allowlistEnabled, isLeaderinAllowlist)
	-- Update the text of the data broker based on the automation status (true -> green, false -> red, true + true -> yellow)
	qraaLDB.text = getDynamicBrokerText(automationRunning, allowlistEnabled, isLeaderinAllowlist)
end


-- update the minimap icon coloration to reflect the new automation status
function QueueRoleAutoAccept:UpdateMinimapButton(automationRunning, allowlistEnabled, isLeaderinAllowlist)
	-- search for the minimap icon object
	local button = qraaMinimapIcon:GetMinimapButton("QueueRoleAutoAccept")
	
	local r, g, b = getDynamicMinimapColor(automationRunning, allowlistEnabled, isLeaderinAllowlist)
	button.icon:SetVertexColor(r, g, b)
end


-- script for the hooking function
function QueueRoleAutoAccept:OnShowScript()
	-- if automation is toggled ...
	--print("Automation:   ", QueueRoleAutoAccept.db.char.automationRunning)
	--print("AllowlistCheck:   ", QueueRoleAutoAccept:AllowlistCheck())
	--print("AllowlistEnabled:   ", QueueRoleAutoAccept:IsAllowlistEnabled())
	--print("LeaderInAllowlist:   ", QueueRoleAutoAccept:IsLeaderinAllowlist())
	--print("Leader:   ", ns.CurrentLeader)
	if QueueRoleAutoAccept.db.char.automationRunning and QueueRoleAutoAccept:AllowlistCheck() then
		-- ... trigger click function on blizz's role selection windows
		LFDRoleCheckPopupAcceptButton:Click()
	end
end

-- register and handle the GROUP_ROSTER_UPDATE to save current party leader
QueueRoleAutoAccept:RegisterEvent("GROUP_ROSTER_UPDATE", function()

	
	-- if not in group, leader name empty
	if not IsInGroup() then
        ns.CurrentLeader = ""
    end
    
	-- if in raid or party search for party lead and save it for later use
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = (prefix == "party" and i == GetNumGroupMembers()) and "player" or prefix..i
		local unitName = ns.GetCharacterNameAndRealm(unit)
        if UnitIsGroupLeader(unit) then
            ns.CurrentLeader = unitName
			QueueRoleAutoAccept:UpdateUI(ns.QueueRoleAutoAccept.db.char.automationRunning, ns.QueueRoleAutoAccept.db.char.allowlistCheck)
        end
		
		-- update class if player class is saved as unknown in db
		if ns.QueueRoleAutoAccept.db.global.allowlist[unitName] then
			if ns.QueueRoleAutoAccept.db.global.allowlist[unitName].class == "UNKNOWN" then
				local unitClass, _ = UnitClassBase(unit)
				if unitClass then
					ns.QueueRoleAutoAccept.db.global.allowlist[unitName].class = unitClass
					ns.allowlistWindow:DataChanged()
				end
			end
		end
    end
end)


-- function is called if registered slash command is executed in chat
function QueueRoleAutoAccept:SlashCommand(msg)
	-- if slash command message is empty or null ...
	if not msg or msg:trim() == "" then
		-- toggle automation status
		self:ToggleAutomation()
	-- else if message equals "minimap" toggle minimap icon visibility
	elseif msg == "minimap" then
		self:ToggleMinimapIconVisibility()
	end
	-- do nothing if both if conditions won't match
end