-- @description Move play cursor to start of next measure. Uses arrange view storage slot 5 to prevent view changes if auto view scroll is disabled.
-- @version 1.0
-- @author BlackSpire
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Move play cursor to start of next measure'

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
reaper.Main_OnCommand(reaper.NamedCommandLookup('_XEN_MOVE_EDCUR64THRIGHT'), 0) -- Xenakios/SWS: Move edit cursor 64th note right
reaper.Main_OnCommand(41040, 0) -- Move edit cursor to start of next measure
if not update_view then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_WOL_RESTOREVIEWS5'), 0) -- SWS: Restore arrange view, slot 5
end

reaper.Undo_EndBlock(undo_message, 0) -- 0 = only native commands are used
reaper.PreventUIRefresh(-1)
