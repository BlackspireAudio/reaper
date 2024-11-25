-- @description Set track parent send
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
undo_message = 'Set track parent send'
parent_send = 0

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    if reaper.IsTrackSelected(track) then
        reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND ", parent_send)
    end
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
reaper.PreventUIRefresh(-1)
