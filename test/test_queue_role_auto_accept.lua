-- QueueRoleAutoAccept hot-path regression test.
-- Verifies the role-check popup can be shown without crashing when roles are enabled.

local addonPath = "C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/QueueRoleAutoAccept/QueueRoleAutoAccept.lua"

local function newFrame()
    local frame = {
        scripts = {},
        checked = false,
        shown = false,
        enabled = true,
        disabled = false,
        alpha = 1,
        children = {},
    }

    function frame:SetSize(width, height)
        self.width = width
        self.height = height
    end

    function frame:SetID(id)
        self.id = id
    end

    function frame:SetPoint()
    end

    function frame:SetFrameStrata()
    end

    function frame:SetBackdrop()
    end

    function frame:EnableMouse()
    end

    function frame:RegisterForDrag()
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function frame:GetScript(scriptName)
        return self.scripts[scriptName]
    end

    function frame:Show()
        self.shown = true
        local callback = self.scripts.OnShow
        if callback then
            callback(self)
        end
    end

    function frame:Hide()
        self.shown = false
    end

    function frame:CreateTexture()
        local tex = newFrame()
        function tex:SetAllPoints()
        end
        function tex:SetTexture()
        end
        function tex:SetAlpha()
        end
        function tex:SetTexCoord()
        end
        function tex:SetDrawLayer()
        end
        function tex:Show()
        end
        return tex
    end

    function frame:CreateFontString()
        return newFrame()
    end

    function frame:SetNormalTexture()
    end

    function frame:GetNormalTexture()
        return {
            SetTexCoord = function() end,
        }
    end

    function frame:SetCheckedTexture()
    end

    function frame:SetDisabledCheckedTexture()
    end

    function frame:SetHighlightTexture()
    end

    function frame:SetPushedTexture()
    end

    function frame:SetChecked(value)
        self.checked = value == true
    end

    function frame:GetChecked()
        return self.checked
    end

    function frame:Click()
        self.clicked = true
    end

    function frame:Enable()
        self.enabled = true
        self.disabled = false
    end

    function frame:Disable()
        self.enabled = false
        self.disabled = true
    end

    function frame:IsEnabled()
        return self.enabled == true
    end

    function frame:GetText()
        return self.text
    end

    function frame:SetText(value)
        self.text = value
    end

    function frame:SetMovable()
    end

    function frame:StartMoving()
    end

    function frame:StopMovingOrSizing()
    end

    function frame:EnableMouse()
    end

    function frame:RegisterForClicks()
    end

    function frame:SetTexCoord()
    end

    return frame
end

local function makeLibStub(name)
    if name == "AceAddon-3.0" then
        return {
            NewAddon = function(addonName)
                local addon = {}
                function addon:RegisterChatCommand() end
                function addon:RegisterEvent() end
                function addon:Print() end
                function addon:UpdateUI() end
                function addon:ToggleAutomation() end
                function addon:ToggleAllowlistCheck() end
                function addon:OpenAllowlist() end
                function addon:IsLeaderinAllowlist() return true end
                function addon:AllowlistCheck() return true end
                function addon:IsAllowlistEnabled() return false end
                return addon
            end,
        }
    end

    if name == "AceConsole-3.0" then
        return {}
    end

    if name == "AceEvent-3.0" then
        return {}
    end

    if name == "LibDataBroker-1.1" then
        return {
            NewDataObject = function()
                return {
                    text = "QRAA",
                    icon = "Interface\\Icons\\inv_misc_groupneedmore",
                }
            end,
        }
    end

    if name == "LibDBIcon-1.0" then
        return {
            Register = function() end,
            AddButtonToCompartment = function() end,
            GetMinimapButton = function()
                return {
                    icon = {
                        SetVertexColor = function() end,
                    },
                }
            end,
            Hide = function() end,
            Show = function() end,
        }
    end

    return {}
end

_G.LibStub = makeLibStub
_G.CreateFrame = function()
    return newFrame()
end
_G.UIParent = newFrame()
_G.OKAY = "OK"
_G.GetTexCoordsByGrid = function()
    return 0, 0, 1, 1
end
_G.C_LFGList = {
    GetAvailableRoles = function()
        return true, true, false
    end,
}
_G.SetDesaturation = function() end
_G.GetRealmName = function()
    return "MockRealm"
end
_G.UnitName = function()
    return "MockPlayer", "MockRealm"
end
_G.IsInGroup = function() return false end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return 0 end
_G.UnitIsGroupLeader = function() return false end
_G.UnitClassBase = function() return "WARRIOR" end
_G.LFDRoleCheckPopupAcceptButton = newFrame()
_G.LFDQueueFrameRoleButtonTank = { checkButton = newFrame() }
_G.LFDQueueFrameRoleButtonHealer = { checkButton = newFrame() }
_G.LFDQueueFrameRoleButtonDPS = { checkButton = newFrame() }

local namespace = {}
assert(loadfile(addonPath))("QueueRoleAutoAccept", namespace)

local queueAddon = namespace.QueueRoleAutoAccept
assert(queueAddon ~= nil, "queue role addon namespace is created")
local roleWindow = queueAddon.roleCheckWindow
assert(roleWindow ~= nil, "role check window is created")

local ok, err = pcall(function()
    roleWindow:Show()
end)

if not ok then
    error("role check window OnShow did not crash: " .. tostring(err))
end

print("QueueRoleAutoAccept hot-path tests passed")
