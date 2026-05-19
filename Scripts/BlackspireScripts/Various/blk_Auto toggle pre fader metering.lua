-- @description Automatically activates pre fader metering when any track is armed and vice versa.
-- If the pre fader metering state is overridden by user, the script will refrain from reengaging until a state change between "no tracks armed" and "at least one track armed" is observed
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------

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
local internal_state_pre_fader_metering = false
local reaper_state_pre_fader_metering = false
local TRACK_METER_PRE_FADER_TOGGLE = 42076

function loop()
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    reaper_state_pre_fader_metering = reaper.GetToggleCommandStateEx(sec, TRACK_METER_PRE_FADER_TOGGLE) == 1

    if tm.AnyTrackArmed() then
        if not (reaper_state_pre_fader_metering or internal_state_pre_fader_metering) then
            reaper.Main_OnCommand(TRACK_METER_PRE_FADER_TOGGLE, 0)
        end
        internal_state_pre_fader_metering = true
    else
        if reaper_state_pre_fader_metering and internal_state_pre_fader_metering then
            reaper.Main_OnCommand(TRACK_METER_PRE_FADER_TOGGLE, 0)
        end
        internal_state_pre_fader_metering = false
    end
    reaper.defer(loop)
end

loop()
