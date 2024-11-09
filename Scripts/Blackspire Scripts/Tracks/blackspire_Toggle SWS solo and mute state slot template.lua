-- @description %description%
-- @version %version%
-- @author %author%

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local slot = %slot%
local save_on_reset = %save_on_reset%
local solo_mute = %solo_mute%
local select = %select%
local undo_message = '%description%'


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

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()
ToggleSWSSoloMuteSlot(slot, save_on_reset, solo_mute, select)
reaper.Undo_EndBlock(undo_message, 4)
