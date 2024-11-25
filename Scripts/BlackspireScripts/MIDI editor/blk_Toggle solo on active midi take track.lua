-- @description Toggle solo on active midi take track
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
undo_message = 'Toggle solo on active midi take track'

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
reaper.Undo_BeginBlock()
ToggleSoloOnTrack(rprw_GetMIDIEditorActiveTakeTrack(), true, false, true)
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
