-- @description Toggle freeze_to_mono trait on a track to cause the smart freeze script to freeze it to mono
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Toggle freeze to mono on track'

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
local rsw = require "reascript_wrapper"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

local selected_tracks = rsw.GetSelectedTracks()
for i = 1, #selected_tracks do
    tm.ToggleSWSNoteTrait(selected_tracks[i], tm.SWSNoteTrait.FreezeToMono)
end
local show_track_notes_cmdid = reaper.NamedCommandLookup('_S&M_TRACKNOTES')
if reaper.GetToggleCommandState(show_track_notes_cmdid) == 0 then
    reaper.Main_OnCommand(show_track_notes_cmdid, 0) -- show track notes
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
