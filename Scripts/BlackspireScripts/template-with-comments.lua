-- @description
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = ''

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
-- lib_path = REAPER/Scripts/BlackspireScripts/ .. lib .. /
local lib_path = select(2, reaper.get_action_context()):match("^.+REAPER[\\/]Scripts[\\/].-[\\/]") .. "lib" .. package.config:sub(1, 1)
-- check if lib is installed
local f = io.open(lib_path .. "version.lua", "r")
if not f then
    reaper.MB("Couldn't find BlackspireScripts library at:\n" .. lib_path .. "\nInstall it using the ReaPack browser", "Whoops!", 0)
    return false
end
f:close()
-- add lib path to package.path to enable require module import (see https://www.lua.org/pil/8.1.html for benefits over dofile)
-- add lib/fallback.lua to package.path to avoid ugly error message if a lib file is missing
package.path = package.path .. ";" .. lib_path .. "?.lua;" .. lib_path .. "fallback.lua"
-- check if installed lib and reaper version are high enough for script
if not require "version" or not BLK_CheckVersion(1.0) or not BLK_CheckReaperVrs(7.0) then return end
-- import modules
local utils = require "utils"
local rsw = require "reascript_wrapper"
local im = require "items"
local tm = require "tracks"
local transport = require "transport"
local sgm = require "script_generator"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
