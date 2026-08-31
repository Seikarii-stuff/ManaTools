local ADDON_NAME, ManaTools = ...

local db = ManaTools.DB.CinematicSkip
if db.enabled == nil then
    db.enabled = true
end

local CinematicSkip = ManaTools.CinematicSkip or {}
ManaTools.CinematicSkip = CinematicSkip

local eventFrame = CreateFrame("Frame")
local eventsRegistered = false

local function skipCinematic()
    if CinematicFrame_CancelCinematic then
        CinematicFrame_CancelCinematic()
    end
end

local function skipMovie()
    if MovieFrame then
        MovieFrame:Hide()
    end
end

local function skipTalkingHead()
    if TalkingHeadFrame then
        TalkingHeadFrame:Hide()
    end
end

function CinematicSkip:UpdateEvents()
    local enabled = db.enabled == true

    if enabled and not eventsRegistered then
        eventFrame:RegisterEvent("CINEMATIC_START")
        eventFrame:RegisterEvent("PLAY_MOVIE")
        eventFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
        eventsRegistered = true
    elseif not enabled and eventsRegistered then
        eventFrame:UnregisterEvent("CINEMATIC_START")
        eventFrame:UnregisterEvent("PLAY_MOVIE")
        eventFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
        eventsRegistered = false
    end
end

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "CINEMATIC_START" then
        skipCinematic()
    elseif event == "PLAY_MOVIE" then
        skipMovie()
    elseif event == "TALKINGHEAD_REQUESTED" then
        skipTalkingHead()
    end
end)

CinematicSkip.eventFrame = eventFrame
CinematicSkip:UpdateEvents()
