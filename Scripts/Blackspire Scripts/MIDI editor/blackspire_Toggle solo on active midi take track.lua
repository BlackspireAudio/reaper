undo_message = 'Toggle solo on active midi take track'

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = reaper.GetExtState("BlackSpire_Scripts", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackSpire_Scripts library. Please run 'blackspire_Set library path.lua' in the BlackSpire Scripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, { "helper_functions.lua", "rprw.lua", "track_properties.lua" }) then return end

reaper.Undo_BeginBlock()
ToggleSoloOnTrack(rprw_GetMIDIEditorActiveTakeTrack(), true, false, true)
reaper.Undo_EndBlock(undo_message, 4)
