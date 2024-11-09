-- @description Cycle record arm and monitoring states for track under mouse
-- @version 1.0
-- @author BlackSpire
-- @changelog

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
-- Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#GetMediaTrackInfo_Value for infos on the values
local audio_states = {
    [1] = { rec_arm = 1, rec_mode = 0, rec_mon = 1 }, -- record input and monitor
    [2] = { rec_arm = 1, rec_mode = 2, rec_mon = 1 }, -- monitor only
}

local istrument_states = {
    [1] = { rec_arm = 1, rec_mode = 8, rec_mon = 1 }, -- record midi input (touch-replace) and monitor
    [2] = { rec_arm = 1, rec_mode = 2, rec_mon = 1 }, -- monitor only
}

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = reaper.GetExtState("BlackSpire_Scripts", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackSpire_Scripts library. Please run 'blackspire_Set library path.lua' in the BlackSpire Scripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, { "track_properties.lua", "rprw.lua" }) then return end

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
CycleTargetTrackRecMonStates(audio_states, istrument_states, false)
