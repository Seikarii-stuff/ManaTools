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

local function setPopup(which, buttonText, hasButton2, hasButton3, hasButton4, hasButton5)
    local function newButton(text, visible)
        local button = {
            clicked = false,
            text = text or "Sí",
            visible = visible ~= false,
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
        function button:IsShown()
            return self.visible == true
        end
        function button:Click()
            self.clicked = true
        end
        return button
    end

    local button1 = newButton(buttonText or "Sí", true)
    local popup = {
        which = which,
        button1 = button1,
    }

    if hasButton2 then
        popup.button2 = newButton("Aceptar", true)
        StaticPopup1Button2 = popup.button2
    else
        popup.button2 = newButton("Aceptar", false)
        StaticPopup1Button2 = popup.button2
    end

    if hasButton3 then
        popup.button3 = newButton("Otro", true)
        StaticPopup1Button3 = popup.button3
    else
        StaticPopup1Button3 = nil
    end

    if hasButton4 then
        popup.button4 = newButton("Más", true)
        StaticPopup1Button4 = popup.button4
    else
        StaticPopup1Button4 = nil
    end

    if hasButton5 then
        popup.button5 = newButton("Extra", true)
        StaticPopup1Button5 = popup.button5
    else
        StaticPopup1Button5 = nil
    end

    StaticPopup1 = popup
    StaticPopup1Button1 = button1
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

setPopup("PROFESSION_REAGENT", "Sí", true)
triggerPopup("PROFESSION_REAGENT")
assert(StaticPopup1Button1.clicked == true, "binary profession confirmation popup auto-clicks the confirmation button")

setPopup("SINGLE_OPTION_POPUP", "Cancelar", false)
triggerPopup("SINGLE_OPTION_POPUP")
assert(StaticPopup1Button1.clicked == false, "single-button popup does not auto-accept")

setPopup("HIDDEN_SECOND_BUTTON_POPUP", "Cancelar", true)
StaticPopup1.button2.visible = false
triggerPopup("HIDDEN_SECOND_BUTTON_POPUP")
assert(StaticPopup1Button1.clicked == false, "hidden second button does not count as a binary popup")

setPopup("MULTI_OPTION_POPUP", "Opciones", true, true)
triggerPopup("MULTI_OPTION_POPUP")
assert(StaticPopup1Button1.clicked == false, "three-button popup does not auto-accept when it is not a binary choice")

mock.playerDead = true
setPopup("RELEASE_SPIRIT", "Liberar", true)
triggerPopup("RELEASE_SPIRIT")
assert(StaticPopup1Button1.clicked == false, "dead player does not auto-accept the release popup")
mock.playerDead = false

print("ProfessionSkip tests passed")
