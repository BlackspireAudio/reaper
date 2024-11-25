-- @description %description%
-- @version %version%
-- @author %author%


--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local force_pre_roll = %force_pre_roll%
local save_recorded_media = %save_recorded_media%
-- local grace_period = %grace_period% -- todo: add grace_period to script generator
local undo_message = '%description%'


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
if not BSLoadLibraries(1.0, { "track_properties.lua", "transport.lua", "rprw.lua", "helper_functions.lua" }) then return end

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()
RestartPlayRecord(AnyTrackArmed(), force_pre_roll, save_recorded_media)
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
