-- Addon:	QueueRoleAutoAccept
-- Author:	Spielstein@Curse



-----------------------------
-- constants and objects   --
-----------------------------

------@class ns
local ns = select(2, ...)

local function slice(tbl, first, last)
    local result = {}
    for i = first, last do
        table.insert(result, tbl[i])
    end
    return result
end

local function updateKeys(dict)
    local _
    local foundKeys = {}

    for key, _ in pairs(dict) do
        table.insert(foundKeys, key)
    end

    -- Keys alphabetisch sortieren (optional)
    table.sort(foundKeys)

    return foundKeys
end

-- ns.testData = {
--     ["Anduin-Stormrage"] =      {class = "PRIEST",      comment = "Licht sei mit dir."},
--     ["Anubarak-AzjolNerub"] =   {class = "DEATHKNIGHT", comment = "Die Schatten erwarten dich."},
--     ["Baine-Bloodhoof"] =       {class = "WARRIOR",     comment = "Die Erde gibt mir Kraft."},
--     ["Bolvar-Fordragon"] =      {class = "DEATHKNIGHT", comment = "Die Kälte des Nordens ruft."},
--     ["Chen-Pandaria"] =         {class = "MONK",        comment = "Ein Bier dazu?"},
--     ["Gallywix-Bilgewater"] =   {class = "ROGUE",       comment = "Gold regiert die Welt!"},
    -- ["Garrosh-Hellscream"] =    {class = "WARRIOR",     comment = "Lok'tar Ogar!"},
    -- ["Genn-Greymane"] =         {class = "DRUID",       comment = "Ich werde nie wieder die Kontrolle verlieren."},
    -- ["Guldan-Draenor"] =        {class = "WARLOCK",     comment = "Macht ist alles!"},
    -- ["Hugo-Blackmoore"] =       {class = "DRUID",       comment = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam"},
    -- ["Illidan-Stormrage"] =     {class = "DEMONHUNTER", comment = "Du bist nicht vorbereitet!"},
    -- ["Jaina-Proudmoore"] =      {class = "MAGE",        comment = "Frostblitze regnen herab."},
    -- ["Kaelthas-Sunstrider"] =   {class = "MAGE",        comment = "Das war erst ein Vorgeschmack!"},
    -- ["Kelthuzad-Naxxramas"] =   {class = "WARLOCK",     comment = "Ewige Macht gehört mir!"},
    -- ["LiLi-Wanderlust"] =       {class = "MONK",        comment = "Lass uns auf Abenteuer gehen!"},
    -- ["Magni-Bronzebeard"] =     {class = "PALADIN",     comment = "Für Khaz Modan!"},
    -- ["Malfurion-Teldrassil"] =  {class = "DRUID",       comment = "Die Natur wird sich rächen."},
    -- ["Medivh-Karazhan"] =       {class = "MAGE",        comment = "Die Zeit ist gekommen."},
    -- ["Moira-Thaurissan"] =      {class = "PRIEST",      comment = "Dunkles Eisen wird siegen."},
    -- ["Muradin-Bronzebeard"] =   {class = "PALADIN",     comment = "Für die Allianz!"},
    -- ["Neltharion-Blackrock"] =  {class = "EVOKER",      comment = "Das Erbe der Drachen lebt weiter!"},
    -- ["Rexxar-MokNathal"] =      {class = "HUNTER",      comment = "Halb Orc, halb Oger, ganz Jäger!"},
    -- ["Sylvanas-Silvermoon"] =   {class = "HUNTER",      comment = "Für die Horde!"},
    -- ["Teron-Khan"] =            {class = "DEATHKNIGHT", comment = "Ewige Dunkelheit erwartet dich."},
    -- ["Thrall-Durotan"] =        {class = "SHAMAN",      comment = "Die Elemente rufen."},
    -- ["Thrall-Ragnaros"] =       {class = "WARRIOR",     comment = "Haut drauf!"},
    -- ["Tyrande-Whisperwind"] =   {class = "PRIEST",      comment = "Elune sei mit dir."},
    -- ["Uther-Lightbringer"] =    {class = "PALADIN",     comment = "Ein reines Herz ist der stärkste Schild."},
    -- ["Valeera-Ravencrest"] =    {class = "ROGUE",       comment = "Schatten sind meine Waffe."},
    -- ["Voljin-Senjin"] =         {class = "SHAMAN",      comment = "Ich seh Dinge, die du nicht siehst."},
    -- ["Ysera-EmeraldDream"] =    {class = "DRUID",       comment = "Die Träume flüstern mir zu."},
    -- ["Zuljin-Amani"] =          {class = "HUNTER",      comment = "Ihr habt mich einmal gefangen, das passiert nicht noch mal!"}
-- }
-- ns.testDataKeys = updateKeys(ns.testData)


local function createRow(parent, isHeader)
    
    isHeader = isHeader or false

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(32)

    row.isHeader = isHeader

    local playerClassIcon = row:CreateTexture()
    playerClassIcon:SetSize(28,28)
    playerClassIcon:SetTexture("Interface\\TARGETINGFRAME\\UI-CLASSES-CIRCLES")
    playerClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS["WARRIOR"]))
    playerClassIcon:SetPoint("LEFT", row, "LEFT", 10, 0)
    if row.isHeader then playerClassIcon:Hide() end

    local classIconHeaderText = row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    classIconHeaderText:SetSize(160,32)
    classIconHeaderText:SetPoint("CENTER", playerClassIcon, "CENTER", 0, 0)
    classIconHeaderText:SetJustifyH("CENTER")
    classIconHeaderText:SetJustifyV("MIDDLE")
    classIconHeaderText:SetWordWrap(false)
    classIconHeaderText:SetText("Class")
    if not row.isHeader then classIconHeaderText:Hide() end

    local playerName = row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    playerName:SetSize(160,32)
    playerName:SetPoint("LEFT", playerClassIcon, "RIGHT", 5, 0)
    playerName:SetJustifyH("CENTER")
    playerName:SetJustifyV("MIDDLE")
    playerName:SetWordWrap(false)

    local deleteButton = CreateFrame("Button", nil, row, "UIPanelSquareButton")
    deleteButton:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    deleteButton:Hide()
    deleteButton:SetScript("OnClick", function(self)
        row:GetParent():RemovePlayer(playerName:GetText())
    end)

    -- local playerComment = row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    -- playerComment:SetHeight(32)
    -- playerComment:SetPoint("LEFT", playerName, "RIGHT")
    -- playerComment:SetPoint("RIGHT", deleteButton, "LEFT", -20, 0)
    -- playerComment:SetJustifyH("CENTER")
    -- playerComment:SetJustifyV("MIDDLE")
    -- playerComment:SetWordWrap(false)


    row:SetScript("OnEnter", function()
        if not row.isHeader then
            deleteButton:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        deleteButton:Hide()
    end)
    playerClassIcon:SetScript("OnEnter", function()
        if not row.isHeader then
            deleteButton:Show()
        end
    end)
    playerClassIcon:SetScript("OnLeave", function()
        deleteButton:Hide()
    end)
    playerName:SetScript("OnEnter", function()
        if not row.isHeader then
            deleteButton:Show()
        end
    end)
    playerName:SetScript("OnLeave", function()
        deleteButton:Hide()
    end)
    -- playerComment:SetScript("OnEnter", function()
    --     playerComment:SetWordWrap(true)
    --     if not row.isHeader then
    --         deleteButton:Show()
    --     end
    -- end)
    -- playerComment:SetScript("OnLeave", function()
    --     playerComment:SetWordWrap(false)
    --     deleteButton:Hide()
    -- end)
    deleteButton:SetScript("OnEnter", function()
        -- playerComment:SetWordWrap(true)
        if not row.isHeader then
            deleteButton:Show()
        end
    end)
    deleteButton:SetScript("OnLeave", function()
        -- playerComment:SetWordWrap(false)
        deleteButton:Hide()
    end)


    row.playerClassIcon = playerClassIcon
    row.playerName = playerName
    -- row.playerComment = playerComment
    row.deleteButton = deleteButton
    row.classIconHeaderText = classIconHeaderText


    local function SetPlayerName(self, name)
		playerName:SetText(name)
	end
	row.SetPlayerName = SetPlayerName

    local function SetPlayerClass(self, class)
        if not row.isHeader then
            if class ~= "UNKNOWN" then
                if not playerClassIcon:IsShown() then playerClassIcon:Show() end
                playerClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
            else
                if playerClassIcon:IsShown() then playerClassIcon:Hide() end
            end
        end
	end
	row.SetPlayerClass = SetPlayerClass

    -- local function SetPlayerComment(self, comment)
    --     playerComment:SetText(comment)
	-- end
	-- row.SetPlayerComment = SetPlayerComment

    local function SetPlayerData(self, name, class, comment)
        self:SetPlayerName(name)
        self:SetPlayerClass(class)
        -- self:SetPlayerComment(comment)
    end
    row.SetPlayerData = SetPlayerData

    return row
end


local function CreateAllowlistWindow(parent)
    


    local allowlistWindowFrame = CreateFrame("Frame", "QueueRoleAutoAcceptAllowlistWindow", parent, "BasicFrameTemplate")
    allowlistWindowFrame.TitleText:SetText("QueueRoleAutoAccept: Allowlist")
    allowlistWindowFrame:SetSize(300, 405)--(650,405)
    allowlistWindowFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    allowlistWindowFrame:SetMovable(true)
    allowlistWindowFrame:EnableMouse(true)
    allowlistWindowFrame:RegisterForDrag("LeftButton")
    allowlistWindowFrame:SetScript("OnDragStart", allowlistWindowFrame.StartMoving)
    allowlistWindowFrame:SetScript("OnDragStop", allowlistWindowFrame.StopMovingOrSizing)
    --tinsert(UISpecialFrames, allowlistWindowFrame:GetName())
    allowlistWindowFrame:Show()

    allowlistWindowFrame:SetScript("OnMouseWheel", function (self, direction)

        local currentScrollbarValue = self.scrollbar:GetValue()
        local _, maxValue = self.scrollbar:GetMinMaxValues()
        self.scrollbar:SetValue(min(maxValue, max(0, currentScrollbarValue - direction)))
    end)


    local SliderBackdrop  = {
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    }

    local scrollbar = CreateFrame("Slider", nil, allowlistWindowFrame, "BackdropTemplate")
    scrollbar:SetWidth(10)
    scrollbar:SetHeight(320)
    scrollbar:SetBackdrop(SliderBackdrop)
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    scrollbar:SetOrientation('VERTICAL')
    scrollbar:SetPoint("RIGHT", allowlistWindowFrame, "RIGHT", -10, -35)
    scrollbar:SetValueStep(1)
    scrollbar:SetObeyStepOnDrag(true)
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValue(0)

    scrollbar:SetScript("OnValueChanged", function (self, value)
        self:GetParent():UpdateRows(value, value + 9)
    end)

    allowlistWindowFrame.scrollbar = scrollbar


    allowlistWindowFrame.rows = {}

    for i = 0, 9 do

        local newRow = createRow(allowlistWindowFrame)

        if i == 0 then
            newRow:SetPoint("TOPLEFT", allowlistWindowFrame, "TOPLEFT", 10, -80)
            newRow:SetPoint("TOPRIGHT", allowlistWindowFrame, "TOPRIGHT", -10, -80)
        else
            newRow:SetPoint("TOPLEFT", allowlistWindowFrame.rows[i - 1], "BOTTOMLEFT", 0, 0)
            newRow:SetPoint("TOPRIGHT", allowlistWindowFrame.rows[i - 1], "BOTTOMRIGHT", 0, 0)
        end

        allowlistWindowFrame.rows[i] = newRow
        
    end

    local addPlayerButton = CreateFrame("Button", nil, allowlistWindowFrame, "UIPanelButtonTemplate")
    addPlayerButton:SetSize(24, 24)
    addPlayerButton:SetPoint("TOPRIGHT", allowlistWindowFrame, "TOPRIGHT", -5, -25)

    -- Create a texture for the button
    local addPlayerButtonTexture = addPlayerButton:CreateTexture(nil, "ARTWORK")
    addPlayerButtonTexture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP")
    addPlayerButtonTexture:SetAllPoints(addPlayerButton)

    -- Set the button's normal, pushed, and highlight textures
    addPlayerButton:SetNormalTexture(addPlayerButtonTexture)
    --addPlayerButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    addPlayerButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
    addPlayerButton.texture = addPlayerButtonTexture

    -- Button Click Function
    addPlayerButton:SetScript("OnClick", function()
        ns.addPlayerWindow:Show()
    end)

    allowlistWindowFrame.headerRow = createRow(allowlistWindowFrame, true)
    allowlistWindowFrame.headerRow:SetPoint("TOPLEFT", allowlistWindowFrame, "TOPLEFT", 10, -40)
    allowlistWindowFrame.headerRow:SetPoint("TOPRIGHT", allowlistWindowFrame, "TOPRIGHT", -10, -40)
    allowlistWindowFrame.headerRow:SetPlayerData("Player Name", "", "Comment")

    function allowlistWindowFrame:RemovePlayer(playerName)
        ns.QueueRoleAutoAccept.db.global.allowlist[playerName] = nil
        --ns.allowlistKeys = updateKeys(ns.QueueRoleAutoAccept.db.global.allowlist)
        self:DataChanged()
    end

    function allowlistWindowFrame:AddPlayer(playerName, class, comment)
        ns.QueueRoleAutoAccept.db.global.allowlist[playerName] = {class = class,      comment = comment}
        --ns.allowlistKeys = updateKeys(ns.QueueRoleAutoAccept.db.global.allowlist)
        self:DataChanged()
    end

    function allowlistWindowFrame:UpdateRows(minIndex, maxIndex)

        --minIndex = minIndex + 1
        --maxIndex = maxIndex + 1

        --DevTools_Dump(ns.allowlistKeys)
        for x = 1, 10 do
            
            if ns.allowlistKeys[x + minIndex] then
                local playerName = ns.allowlistKeys[x + minIndex]
                local playerClass = ns.QueueRoleAutoAccept.db.global.allowlist[playerName].class
                -- local playerComment = ns.QueueRoleAutoAccept.db.global.allowlist[playerName].comment

                allowlistWindowFrame.rows[x - 1]:Show()
                allowlistWindowFrame.rows[x - 1]:SetPlayerData(playerName, playerClass)--, playerComment)
            else
                allowlistWindowFrame.rows[x - 1]:Hide()
            end
        end
    end

    function allowlistWindowFrame:DataChanged()

        ns.allowlistKeys = updateKeys(ns.QueueRoleAutoAccept.db.global.allowlist)

        -- capping current sliderValue
        local currentSliderValue = self.scrollbar:GetValue()
        local cappedSliderValue = min(currentSliderValue, #ns.allowlistKeys - 10)
        self.scrollbar:SetValue(cappedSliderValue)

        -- set new min/max slider values
        self.scrollbar:SetMinMaxValues(0, max(#ns.allowlistKeys - 10, 0))

        if #ns.allowlistKeys <= 10 then self.scrollbar:Hide() else self.scrollbar:Show() end

        local minDataIndex = max(0, cappedSliderValue)
        local maxDataIndex = min(cappedSliderValue + 9, #ns.allowlistKeys - 9)
        
        -- if #ns.allowlistKeys <= 11 then
        --     self:UpdateRows(0, 9)
        -- else
            self:UpdateRows(minDataIndex, maxDataIndex)
        -- end

        ns.QueueRoleAutoAccept:UpdateGroupLeader()
    end

    --allowlistWindowFrame:DataChanged()

    local function modify(_,parent,data)
        parent:CreateDivider()
        parent:CreateButton("Add to QRAA Allowlist", function()
        local guid = data.playerLocation.guid or C_ChatInfo.GetChatLineSenderGUID(data.playerLocation.chatLineID)
        local _, class , _, _, _, name, realm = GetPlayerInfoByGUID(guid)
        if realm ~= "" then
            name = name .. "-" .. realm
        else
            name = name .. "-" .. GetNormalizedRealmName()
        end
        ns.allowlistWindow:AddPlayer(name, class, "")
        end)
    end
    for _,tag in ipairs({
        "MENU_UNIT_ENEMY_PLAYER",
        "MENU_UNIT_FRIEND",
        "MENU_UNIT_PARTY",
        "MENU_UNIT_PLAYER",
        "MENU_UNIT_RAID_PLAYER"
    }) do Menu.ModifyMenu(tag,modify) end

    allowlistWindowFrame:Hide()
    return allowlistWindowFrame
end

local function CreateAddPlayerToAllowlistWindow(parent)
    local addPlayerWindow = CreateFrame("Frame", "QRAA_RoleCheckWindow", UIParent, "BackdropTemplate")
    addPlayerWindow:SetFrameStrata("DIALOG")
    addPlayerWindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileEdge = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    addPlayerWindow:SetSize(306,180)
    addPlayerWindow:SetPoint("CENTER")
    addPlayerWindow:SetMovable(true)
    addPlayerWindow:EnableMouse(true)
    addPlayerWindow:RegisterForDrag("LeftButton")
    addPlayerWindow:SetScript("OnDragStart", function(self, button)
        self:StartMoving()
    end)
    addPlayerWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    addPlayerWindow:Hide()

    local windowTitle = addPlayerWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    windowTitle:SetText("Add Player to Allowlist:")
    windowTitle:SetPoint("TOP", 0, -15)
    addPlayerWindow.fontstring = windowTitle

    local windowsWidth = addPlayerWindow:GetWidth()

    local hyphenText = addPlayerWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hyphenText:SetText("-")
    hyphenText:SetPoint("CENTER", 0, 0)
    hyphenText:SetJustifyH("CENTER")
    addPlayerWindow.hyphenText = hyphenText

    local textboxPlayername = CreateFrame("EditBox", nil, addPlayerWindow, "InputBoxTemplate")
    textboxPlayername:SetSize(windowsWidth/2 - 45, 50)
    textboxPlayername:SetPoint("RIGHT", hyphenText, "LEFT", -5, 0)
    addPlayerWindow.textboxPlayername = textboxPlayername

    local textboxPlayernameTitle = addPlayerWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    textboxPlayernameTitle:SetText("Player name")
    textboxPlayernameTitle:SetPoint("BOTTOM", textboxPlayername, "TOP", 0, 0)
    addPlayerWindow.textboxPlayernameTitle = textboxPlayernameTitle

    local textboxPlayerrealm = CreateFrame("EditBox", nil, addPlayerWindow, "InputBoxTemplate")
    textboxPlayerrealm:SetSize(windowsWidth/2 - 45, 50)
    textboxPlayerrealm:SetPoint("LEFT", hyphenText, "RIGHT", 5, 0)
    addPlayerWindow.textboxPlayerrealm = textboxPlayerrealm

    local textboxPlayerrealmTitle = addPlayerWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    textboxPlayerrealmTitle:SetText("Player realm")
    textboxPlayerrealmTitle:SetPoint("BOTTOM", textboxPlayerrealm, "TOP", 0, 0)
    addPlayerWindow.textboxPlayerrealmTitle = textboxPlayerrealmTitle

    local addButton = CreateFrame("Button", "QRAA_RoleCheckWindow_AcceptButton", addPlayerWindow, "UIPanelButtonTemplate")
    addButton:SetSize(115, 22)
    addButton:SetPoint("BOTTOM", addPlayerWindow, -65, 15)
    addButton:SetText(OKAY)
    addButton:SetScript("OnClick", function()
        local name = textboxPlayername:GetText():gsub("^%s+", ""):gsub("%s+$", "")
        local realm = textboxPlayerrealm:GetText():gsub("%s+", "")
        if realm ~= "" then
            name = name .. "-" .. realm
        else
            name = name .. "-" .. GetNormalizedRealmName()
        end

        local className = "UNKNOWN"
        -- if in raid or party search for party lead and save it for later use
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, GetNumGroupMembers() do
            local unit = (prefix == "party" and i == GetNumGroupMembers()) and "player" or prefix..i
            local unitName = ns.GetCharacterNameAndRealm(unit)
            if unitName == name then
                local _
                className, _ = UnitClassBase(unit)
            end
        end

        ns.allowlistWindow:AddPlayer(name, className, "")
        textboxPlayername:SetText("")
        textboxPlayerrealm:SetText("")
        addPlayerWindow:Hide()
    end)
    addPlayerWindow.acceptButton = addButton

    local cancelButton = CreateFrame("Button", "QRAA_RoleCheckWindow_AcceptButton", addPlayerWindow, "UIPanelButtonTemplate")
    cancelButton:SetSize(115, 22)
    cancelButton:SetPoint("BOTTOM", addPlayerWindow, 65, 15)
    cancelButton:SetText(CANCEL)
    cancelButton:SetScript("OnClick", function()
        textboxPlayername:SetText("")
        textboxPlayerrealm:SetText("")
        addPlayerWindow:Hide()
    end)
    addPlayerWindow.cancelButton = cancelButton


    textboxPlayername:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    textboxPlayername:SetScript("OnEditFocusLost", function(self)
        self:ClearFocus()
    end)
    textboxPlayername:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
        textboxPlayerrealm:SetFocus()
    end)
    textboxPlayername:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        addButton:Click()
    end
    )

    textboxPlayerrealm:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    textboxPlayerrealm:SetScript("OnEditFocusLost", function(self)
        self:ClearFocus()
    end)
    textboxPlayerrealm:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
        textboxPlayername:SetFocus()
    end)
    textboxPlayerrealm:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        addButton:Click()
    end
    )


    return addPlayerWindow
end

ns.allowlistWindow = CreateAllowlistWindow(UIParent)
ns.addPlayerWindow = CreateAddPlayerToAllowlistWindow(UIParent)