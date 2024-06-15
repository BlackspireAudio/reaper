undo_message = 'Remove track under mouse and or selected tracks'




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
local track = rprw_GetTrackUnderMouseCursor()
if track and not reaper.IsTrackSelected(track) then
    rprw_DeleteTrack(track)
elseif reaper.GetSelectedTrack(0, 0) then
    for i = reaper.CountSelectedTracks(0) - 1, 0, -1 do
        rprw_DeleteTrack(reaper.GetSelectedTrack(0, i))
    end
end
reaper.Undo_EndBlock(undo_message, 4)
reaper.PreventUIRefresh(-1)
