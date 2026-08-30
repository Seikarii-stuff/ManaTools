-- Basic tests for NoWasteCoin content gating.
-- Run with: lua test/test_no_waste_coin.lua

local function loadNoWasteCoin(instanceType, difficultyID, challengeActive)
    IsInInstance = function()
        return true, instanceType
    end

    GetInstanceInfo = function()
        return "Test Instance", instanceType, difficultyID
    end

    C_ChallengeMode.IsChallengeModeActive = function()
        return challengeActive == true
    end

    NoWasteCoinDB = {
        allowHeroicRaid = false,
        allowMythicPlus = false,
    }

    local source = assert(io.open("NoWasteCoin/NoWasteCoin.lua", "r")):read("*a")
    local chunk = assert(load(source, "NoWasteCoin.lua"))
    chunk("NoWasteCoin")
    return NoWasteCoin_IsAllowedContent()
end

local function assertEqual(actual, expected, name)
    assert(actual == expected, name .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

assertEqual(loadNoWasteCoin("raid", 16, false), true, "Mythic raid")
assertEqual(loadNoWasteCoin("raid", 15, false), false, "Heroic raid default")
assertEqual(loadNoWasteCoin("raid", 14, false), false, "Normal raid")
assertEqual(loadNoWasteCoin("party", 8, false), false, "Mythic 0")
assertEqual(loadNoWasteCoin("party", 8, true), false, "Mythic+ default")
assertEqual(loadNoWasteCoin("party", 8, true), false, "Mythic+ remains gated")
assertEqual(loadNoWasteCoin("scenario", 0, false), false, "Other content")

print("ManaTools tests passed")
