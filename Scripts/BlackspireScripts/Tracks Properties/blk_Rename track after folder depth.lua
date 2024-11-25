-- @description Rename track after folder depth parameter
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
undo_message = 'Rename track after folder depth'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"), true)
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
reaper.PreventUIRefresh(-1)
