-- @description %description%
-- @version %version%
-- @author %author%

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local target = %target%
local split = %split%
local selection = %selection%
local group = %group%
local undo_message = '%description%'

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = select(2, reaper.get_action_context()):match("^.+REAPER[\\/]Scripts[\\/].-[\\/]") .. "lib" .. package.config:sub(1, 1)
local f = io.open(lib_path .. "version.lua", "r")
if not f then
    reaper.MB("Couldn't find BlackspireScripts library at:\n" .. lib_path .. "\nInstall it using the ReaPack browser", "Whoops!", 0)
    return false
end
f:close()
package.path = package.path .. ";" .. lib_path .. "?.lua;" .. lib_path .. "fallback.lua"
if not require "version" or not BLK_CheckVersion(1.0) or not BLK_CheckReaperVrs(7.0) then return end
local im = require "items"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
im.SplitTargetMediaItem(target, split, selection, group)
reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
reaper.PreventUIRefresh(-1)
