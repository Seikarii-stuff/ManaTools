-- NoWasteCoin behavior tests.
-- Deliberately tests behavior, not the number/order of UI controls.
-- Run from repository root: lua test/test_no_waste_coin_behavior.lua

-- Minimal behavior tests for simplified NoWasteCoin.
local mock = assert(loadfile("test/mockwow.lua"))()
local loader = loadstring or load

local function loadFile(path, ...)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    local chunk = assert(loader(source, path))
    chunk(...)
end

mock.reset()
local ManaTools = {}
loadFile("Bootstrap.lua", "ManaTools", ManaTools)
loadFile("NoWasteCoin/NoWasteCoin.lua", "ManaTools", ManaTools)

assert(ManaTools.DB.NoWasteCoin ~= nil, "NoWasteCoin DB branch exists")
assert(type(ManaTools.NoWasteCoin.EnableCurrentRollOverride) == "function", "EnableCurrentRollOverride exists")

print("NoWasteCoin behavior tests passed: minimal checks")
