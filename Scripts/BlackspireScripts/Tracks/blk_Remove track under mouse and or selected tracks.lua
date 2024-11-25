-- @description Remove track under mouse and selected tracks if track under mouse is part of the selection
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARMS-------------------------
--------------------------------------------------
undo_message = 'Remove track under mouse and or selected tracks'

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
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

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
local track = rprw_GetTrackUnderMouseCursor()

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
if track and not reaper.IsTrackSelected(track) then
    -- store active track selctions excluding any tracks that will be deleted through folder deletion
    local selected_tracks = rprw_GetSelectedTraks(rprw_GetChildTracks(track))
    reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
    -- select track under mouse
    reaper.SetTrackSelected(track, true)
    -- delete track using native action (to avoid dealing with folder depth changes)
    reaper.Main_OnCommand(40005, 0) -- Track: Remove tracks
    -- restore selections
    rprw_SelectTracks(selected_tracks)
    reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
elseif reaper.GetSelectedTrack(0, 0) then
    reaper.Main_OnCommand(40005, 0) -- Track: Remove tracks
    reaper.Undo_EndBlock(undo_message, 0) -- 0 = only native reaper actions are used
end
