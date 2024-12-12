-- @description Smart unfreeze tracks. Unfreezes all tracks and unmutes top level children of folder tracks that were muted by smart freeze action
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = "Smart unfreeze tracks"

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

reaper.Main_OnCommand(41644, 0) --Track: Unfreeze all tracks

-- Unmute child tracks that were muted by smart freeze action
local selected_tracks = tm.GetSelectedTracks()
for i = 1, #selected_tracks do
    local track = selected_tracks[i]
    if tm.IsFolder(track) then
        -- only check top level children of folder track
        local children = tm.GetChildTracks(track, false)
        local children_to_enable = {}
        for j = 1, #children do
            local child = children[j]
            if tm.HasSWSNoteTrait(child, tm.SWSNoteTrait.DisabledOnFreeze) then
                tm.SetSWSNoteTrait(child, tm.SWSNoteTrait.DisabledOnFreeze, false)
                table.insert(children_to_enable, child)
            end
        end
        tm.SetEnabledState(children_to_enable, true, true)
    end
end


reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
