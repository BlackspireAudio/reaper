-- @description Count loop iterations while recording. This is an asynchronous script and should either be run with all record start actions or at reaper startup
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local loop_end_grace_period = 0.2      -- adjust this value to reduce the time required for the first loop to be accepted as complete
local terminate_on_record_stop = false -- set to true to stop the script when recording stops

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
local misc = require "misc"
local utils = require "utils"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
local loop_iteration_ext_state_key = "current_loop_iteration"
local recording_restarted_ext_state_key = "recording_restarted"
local current_playstate = reaper.GetPlayState()
local previous_playstate = reaper.GetPlayState()
local current_play_position = 0
local previous_play_position = 0
function loop()
    if reaper.GetToggleCommandState(1068) == 1 then
        -- if loop repeat is enabled
        current_playstate = reaper.GetPlayState()
        if current_playstate & 4 == 4 then
            -- recording
            current_play_position = reaper.GetPlayPosition()
            if current_play_position < previous_play_position then
                if misc.GetExtStateBool(misc.ExtStateSection.TRANSPORT, recording_restarted_ext_state_key) then
                    -- recording has been restarted, reset loop iteration count
                    misc.SetExtState(misc.ExtStateSection.TRANSPORT, recording_restarted_ext_state_key, "false")
                    misc.SetExtState(misc.ExtStateSection.TRANSPORT, loop_iteration_ext_state_key, 0)
                else
                    -- increment loop iteration count
                    misc.SetExtState(misc.ExtStateSection.TRANSPORT, loop_iteration_ext_state_key, (misc.GetExtStateNumber(misc.ExtStateSection.TRANSPORT, loop_iteration_ext_state_key) or 0) + 1)
                end
            end
            previous_play_position = current_play_position
        elseif previous_playstate & 4 == 4 and current_playstate & 4 == 0 then
            -- only executed once in transition from recording to not recording
            misc.SetExtState(misc.ExtStateSection.TRANSPORT, loop_iteration_ext_state_key, 0)
            current_play_position = 0
            previous_play_position = 0
        end
        previous_playstate = current_playstate
    end

    if terminate_on_record_stop and current_playstate & 4 == 0 then return end
    reaper.defer(loop)
end

local is_new_value, filename, sec, cmd, mode, resolution, val =
    reaper.get_action_context()
if reaper.GetToggleCommandStateEx(sec, cmd) == 1 then
    -- if action is run while command toggle state is on, the monitoring script has been terminated and we only need clean up
    -- set action options to 8 to turn off toggle state
    reaper.set_action_options(8)
    -- clean up ext states
    misc.DeleteExtState(misc.ExtStateSection.TRANSPORT, loop_iteration_ext_state_key)
    misc.DeleteExtState(misc.ExtStateSection.TRANSPORT, recording_restarted_ext_state_key)
else
    -- set action toggle state on (4) cause rerun of action to terminate active instance (1) and restart (2)
    -- this allows the script clean up and set the toggle state after the instance is terminated
    reaper.set_action_options(1 | 2 | 4)
    -- create ext state to allow the restart action to communicate with this script
    misc.SetExtState(misc.ExtStateSection.TRANSPORT, recording_restarted_ext_state_key, "false")
    loop()
end
