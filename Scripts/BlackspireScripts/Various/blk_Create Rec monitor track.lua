-- @description Create pre-fader monitor track to send to Master 3/4. This script creates a monitor track with a hardware output to Master 3/4 and sends from all top-level tracks to the monitor track with pre-fader mode and the same volume as the track's master send
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = "Create pre-fader monitor track to send to Master 3/4"

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
local utils = require "utils"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

-- for i = 1, reaper.CountTracks(0) do
--     track = reaper.GetTrack(0, i)
--     reaper.ShowConsoleMsg("Track:" .. i .. ": C_MAINSEND_OFFS:" .. tostring(reaper.GetMediaTrackInfo_Value(track, "C_MAINSEND_OFFS")) .. '\n')
--     reaper.ShowConsoleMsg("Track:" .. i .. ": C_MAINSEND_NCH:" .. tostring(reaper.GetMediaTrackInfo_Value(track, "C_MAINSEND_NCH")) .. '\n')

-- end
local top_level_tracks = tm.GetTopLevelTracks()

local master_track = reaper.GetMasterTrack()
tm.SetParam(master_track, tm.TrackParam.N_CHAN, 4)
route_idx = tm.CreateTrackRouting(master_track)                         -- create hardware send from Master 3/4 to HW 3/4
tm.SetRoutingChannels(master_track, route_idx, tm.RoutingType.HW, 2, 2) -- set Master 3/4 send to HW 3/4

local monitor_track = tm.CreateTrack("MONITOR", { [tm.TrackParam.SEND_OFS] = 2 })

for i = 1, #top_level_tracks do
    local track_volume = tm.GetVolume(top_level_tracks[i])
    tm.CreateTrackRouting(top_level_tracks[i], monitor_track, { [tm.RoutingParam.VOLUME] = track_volume, [tm.RoutingParam.SEND_MODE] = tm.SendMode.PRE_FADER })
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
