-- @description %description%
-- @version %version%
-- @author %author%

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local target = %target%
local split = %split%
local select = %select%
local group = %group%
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
if not BSLoadLibraries(1.0, { "rprw.lua", "items_editing.lua" }) then return end

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
SplitTargetMediaItem(target, split, select, group)
reaper.Undo_EndBlock(undo_message, 4)
reaper.PreventUIRefresh(-1)
