-- @description Cycle record arm and monitoring states for track under mouse
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
-- Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#GetMediaTrackInfo_Value for infos on the values
local audio_states = {
    [1] = { rec_arm = 1, rec_mode = 0, rec_mon = 1 }, -- record input and monitor
    [2] = { rec_arm = 1, rec_mode = 2, rec_mon = 1 } -- monitor only
}

local istrument_states = {
    [1] = { rec_arm = 1, rec_mode = 8, rec_mon = 1 }, -- record midi input (touch-replace) and monitor
    [2] = { rec_arm = 1, rec_mode = 2, rec_mon = 1 } -- monitor only
}

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = select(2, reaper.get_action_context()):match("^.+REAPER[\\/]Scripts[\\/].-[\\/]") .. "lib" .. package.config:sub(1, 1)
local f = io.open(lib_path .. "version.lua", "r")
if not f then
    reaper.MB("Couldn't find BlackspireScripts library at:\n" .. lib_path .. "\nInstall it using the ReaPack browser", "Whoops!", 0)
    return false
end
f:close()
package.path = package.path .. ";" .. lib_path .. "?.lua;" .. lib_path .. "fallback.lua"
if not require "version" or not BLK_CheckVersion(1.0) or not BLK_CheckReaperVrs(7.0) then return end
local tm = require "tracks"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
tm.CycleTargetTrackRecMonStates(audio_states, istrument_states, false)
