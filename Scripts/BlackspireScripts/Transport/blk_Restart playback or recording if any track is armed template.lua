-- @description %description%
-- @version %version%
-- @author %author%


--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local force_pre_roll = %force_pre_roll%
local save_recorded_media = %save_recorded_media%
-- local grace_period = %grace_period% -- todo: add grace_period to script generator
local undo_message = '%description%'

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
local transport = require "transport"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()
transport.RestartPlayRecord(tm.AnyTrackArmed(), force_pre_roll, save_recorded_media)
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
