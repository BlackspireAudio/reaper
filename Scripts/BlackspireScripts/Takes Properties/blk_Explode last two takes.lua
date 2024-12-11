-- @description Moves/Copies the selected items to the next two tracks and switches the first instance to the previous take
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = "Explode last two takes"

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
local im = require "items"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

local selected_items = rsw.GetSelectedItems()
if #selected_items == 0 then return reaper.MB("No items found on selected tracks", "Whoops!", 0) end
if im.GetMinTakesCount(selected_items) < 2 then return reaper.MB("All selected media item must contain at least two takes", "Whoops!", 0) end

local item = selected_items[1]
local source_track = reaper.GetMediaItem_Track(item)
local target_track2_id = reaper.GetMediaTrackInfo_Value(source_track, "IP_TRACKNUMBER") + 1 -- return value is 1-based but GetTrack is 0-based
if target_track2_id <= 0 then return reaper.MB("This script requires a minimum of two tracks below the currently selected track", "Whoops!", 0) end
local start_pos = im.GetStartPosition(item)
im.ClearTakeProperties(selected_items, true, true)
rsw.SelectTracks({ source_track }, true)
reaper.SetEditCurPos(start_pos, false, false)


reaper.Main_OnCommand(40118, 0) -- Item edit: Move items/envelope points down one track/a bit
reaper.Main_OnCommand(40057, 0) -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
reaper.Main_OnCommand(40126, 0) -- Take: Switch items to previous take
reaper.Main_OnCommand(41340, 0) -- Item properties: Lock to active take (mouse click will not change active take)

reaper.Main_OnCommand(40285, 0) -- Track: Go to next track
reaper.Main_OnCommand(40285, 0) -- Track: Go to next track
reaper.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41340, 0) -- Item properties: Lock to active take (mouse click will not change active take)
reaper.SetEditCurPos(start_pos, false, false)


reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
