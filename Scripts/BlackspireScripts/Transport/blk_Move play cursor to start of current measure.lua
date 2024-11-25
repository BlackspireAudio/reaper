-- @description Move play cursor to start of current measure. Uses arrange view storage slot 5 to prevent view changes.
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Move play cursor to start of current measure'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local update_view = reaper.GetToggleCommandState(40036) == 1 -- Options: Toggle auto-scroll view when editing
if not update_view then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_WOL_SAVEVIEWS5'), 0) -- SWS: Save current arrange view, slot 5
end
reaper.Main_OnCommand(40434, 0) -- View: Move edit cursor to play cursor
reaper.Main_OnCommand(41045, 0) -- Move edit cursor back one beat
reaper.Main_OnCommand(41045, 0) -- Move edit cursor back one beat
reaper.Main_OnCommand(41041, 0) -- Move edit cursor to start of current measure
if not update_view then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_WOL_RESTOREVIEWS5'), 0) -- SWS: Restore arrange view, slot 5
end

reaper.Undo_EndBlock(undo_message, 0) -- 0 = only native commands are used
reaper.PreventUIRefresh(-1)
