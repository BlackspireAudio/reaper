-- @description Toggle solo on active midi take track
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
undo_message = 'Toggle mute on active midi take item'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()
local midi_editor = reaper.MIDIEditor_GetActive()
local take = reaper.MIDIEditor_GetTake(midi_editor)
local item = reaper.GetMediaItemTake_Item(take)
local mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
reaper.SetMediaItemInfo_Value(item, "B_MUTE", mute == 1 and 0 or 1)
reaper.UpdateArrange()
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
