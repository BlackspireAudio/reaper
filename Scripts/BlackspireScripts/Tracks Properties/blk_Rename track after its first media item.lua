-- @description Toggle solo on track under mouse (not-in-place, respect grouping, change selection)
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
undo_message = 'Rename track after its first media item'
string_replacements = { { ".wav", "" } }

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local track = reaper.GetSelectedTrack(0, 0)
if not track then
    return
else
    local item = reaper.GetTrackMediaItem(track, 0)
    if not item then
        return
    else
        local take = reaper.GetMediaItemTake(item, 0)
        if not take then
            return
        else
            local name = reaper.GetTakeName(take)
            for i, replacement in ipairs(string_replacements) do
                name = string.gsub(name, replacement[1], replacement[2])
            end
            reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
        end
    end
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
reaper.PreventUIRefresh(-1)
