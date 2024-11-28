-- @description Smart freeze tracks. Freezes selected tracks to mono, stereo or multichannel depending on SWS note trait or channel count. Mutes top level children of folder tracks that don't have sends to prevent them from using CPU. Unmutes them when they are unfrozen.
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Smart freeze tracks'

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
local rsw = require "reascript_wrapper"
local tm = require "tracks"
local utils = require "utils"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

local selected_tracks = rsw.GetSelectedTracks()
local mono_tracks = {}
local stereo_tracks = {}
local multichannel_tracks = {}
local folder_tracks = {}

for i = 1, #selected_tracks do
    local track = selected_tracks[i]
    local track_channels = reaper.GetMediaTrackInfo_Value(track, 'I_NCHAN')
    if tm.HasSWSNoteTrait(track, tm.SWSNoteTrait.FreezeToMono) then
        -- this trait has to be set manually using the "Toggle freeze to mono.lua" script
        table.insert(mono_tracks, track)
    elseif track_channels == 2 then
        table.insert(stereo_tracks, track)
    else
        table.insert(multichannel_tracks, track)
    end
    if rsw.IsFolderTrack(track) then
        table.insert(folder_tracks, track)
    end
end

if #mono_tracks > 0 then
    rsw.SelectTracks(mono_tracks, true)
    reaper.Main_OnCommand(40901, 0) --Track: Freeze to mono (render pre-fader, save/remove items and online FX)
end

if #stereo_tracks > 0 then
    rsw.SelectTracks(stereo_tracks, true)
    reaper.Main_OnCommand(41223, 0) --Track: Freeze to stereo (render pre-fader, save/remove items and online FX)
end

if #multichannel_tracks > 0 then
    rsw.SelectTracks(multichannel_tracks, true)
    reaper.Main_OnCommand(40877, 0) --Track: Freeze to multichannel (render pre-fader, save/remove items and online FX)
end

-- Mute the top level children of folder tracks that don't have sends to prevent them from using CPU
for i = 1, #folder_tracks do
    local folder_track = folder_tracks[i]
    local children = rsw.GetChildTracks(folder_track)
    local children_to_disable = {}
    for j = 1, #children do
        local child_track = children[j]
        if not rsw.HasSends(child_track, true) and rsw.HasFx(child_track) then
            table.insert(children_to_disable, child_track)
            -- set a note trait specifying that the track was disabled on freeze
            tm.SetSWSNoteTrait(child_track, tm.SWSNoteTrait.DisabledOnFreeze, true)
        end
    end
    tm.SetEnabledState(children_to_disable, false)
end
rsw.SelectTracks(selected_tracks, true)

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
