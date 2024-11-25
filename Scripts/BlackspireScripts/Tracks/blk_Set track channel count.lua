undo_message = 'Rename track after its first media item'

local lib_path = reaper.GetExtState("blackspire", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackspireScripts library. Please run 'blk_Set library path.lua' in the BlackspireScripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, {
    "helper_functions.lua", "rprw.lua", "track_properties.lua"
}) then return end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    if reaper.IsTrackSelected(track) then
        reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", 4)
    end
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
reaper.PreventUIRefresh(-1)
