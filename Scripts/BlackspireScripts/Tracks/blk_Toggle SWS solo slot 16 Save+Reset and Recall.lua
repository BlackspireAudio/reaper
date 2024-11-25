-- @description Toggle SWS solo slot 16 Save+Reset and Recall
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local slot = 16
local save_on_reset = true
local solo_mute = 1
local select = false
local undo_message = 'Toggle SWS solo slot 16 Save+Reset and Recall'

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
ToggleSWSSoloMuteSlot(slot, save_on_reset, solo_mute, select)
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
