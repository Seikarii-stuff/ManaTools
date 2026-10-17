-- ProfessionSkip tests for auto-accepting profession completion confirmations.
-- Requires Lua 5.1+.

local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

local function loadAddon(db)
    mock.reset(db)
    local namespace = {}
    loadFile("Bootstrap.lua", "ManaTools", namespace)
    ManaTools = namespace
    return namespace
end

local function setPopup(which, popupText, buttonText)
    local button = {
        clicked = false,
        text = buttonText or "Sí",
    }
    function button:GetText()
        return self.text
    end
    function button:GetDisabled()
        return false
    end
    function button:IsEnabled()
        return true
    end
    function button:Click()
        self.clicked = true
    end

    StaticPopup1 = {
        which = which,
        button1 = button,
    }
    StaticPopup1Button1 = button
    StaticPopup1Text = {
        GetText = function()
            return popupText
        end
    }
end

local function triggerPopup(which)
    if not StaticPopup_Show then
        error("StaticPopup_Show is not available")
    end
    StaticPopup_Show(which)
end

local ManaTools = loadAddon({})
loadFile("CinematicSkip/profesionskip.lua", "ManaTools", ManaTools)
assert(ManaTools.ProfessionSkip ~= nil, "ProfessionSkip namespace is created")

setPopup("PROFESSION_REAGENT", "Estás a punto de completar un pedido de fabricación de Alquimia. ¿Seguro que quieres continuar?", "Sí")
triggerPopup("PROFESSION_REAGENT")
assert(StaticPopup1Button1.clicked == true, "profession confirmation popup auto-clicks the confirmation button")

setPopup("OTHER_POPUP", "No es un pedido de profesión", "Aceptar")
triggerPopup("OTHER_POPUP")
assert(StaticPopup1Button1.clicked == false, "non-profession popups are not auto-accepted")

print("ProfessionSkip tests passed")
