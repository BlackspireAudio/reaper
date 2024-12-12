-- @description Propagates the volume of a folder track to its children
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = "Propagate folder track volume to children"

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
reaper.Undo_BeginBlock()

local selected_tracks = tm.GetSelectedTracks()
if #selected_tracks == 0 then return end
local selected_track = selected_tracks[1]
if not tm.IsFolder(selected_track) then return end
local folder_volume = tm.GetVolume(selected_track, true)
local children = tm.GetChildTracks(selected_track, false, 1)
for i = 1, #children do
    tm.SetVolume(children[i], tm.GetVolume(children[i], true) + folder_volume, true)
end
tm.SetVolume(selected_track, 1)

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
