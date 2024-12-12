-- @description Remove track under mouse and selected tracks if track under mouse is part of the selection
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARMS-------------------------
--------------------------------------------------
undo_message = 'Remove track under mouse and or selected tracks'

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
local track = tm.GetTrackUnderMouseCursor()

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
if track and not reaper.IsTrackSelected(track) then
    -- store active track selctions excluding any tracks that will be deleted through folder deletion
    local selected_tracks = tm.GetSelectedTracks(tm.GetChildTracks(track))
    reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
    -- select track under mouse
    reaper.SetTrackSelected(track, true)
    -- delete track using native action (to avoid dealing with folder depth changes)
    reaper.Main_OnCommand(40005, 0) -- Track: Remove tracks
    -- restore selections
    tm.SelectTracks(selected_tracks)
    reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
elseif reaper.GetSelectedTrack(0, 0) then
    reaper.Main_OnCommand(40005, 0)        -- Track: Remove tracks
    reaper.Undo_EndBlock(undo_message, 0)  -- 0 = only native reaper actions are used
end
