undo_message = 'Rename track after folder depth'




local lib_path = reaper.GetExtState("BlackSpire_Scripts", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackSpire_Scripts library. Please run 'blackspire_Set library path.lua' in the BlackSpire Scripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, { "helper_functions.lua", "rprw.lua", "tracks_properties.lua" }) then return end



reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()


local num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"), true)
end

reaper.Undo_EndBlock(undo_message, 4)
reaper.PreventUIRefresh(-1)
