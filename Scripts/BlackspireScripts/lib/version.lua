-- @description entry point for the BlackspireScripts library
-- @author Blackspire
-- @noindex
blk_lib_version = 1.0
--------------------------------------------------
function BLK_CheckVersion(version, show_error_msg)
    local info = debug.getinfo(1, 'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])

    if not version or version > blk_lib_version then
        if show_error_msg then reaper.MB('Update ' .. script_path:gsub('%\\', '/') .. ' to version ' .. version .. ' or newer', 'BlackspireScripts', 0) end
        return false
    end
    return true
end

function BLK_CheckReaperVrs(version, show_error_msg)
    local vrs_num = reaper.GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if version > vrs_num then
        if show_error_msg then reaper.MB('Update REAPER to newer version ' .. '(' .. version .. ' or newer)', '', 0) end
        return false
    else
        return true
    end
end

local utils = require 'utils'
---------------------------------------------------
function BLK_IncreaseUsedCount()
    local count
    if reaper.HasExtState(utils.ExtStateSection.GLOBAL, utils.ExtStateKeys.USAGE_COUNT) then
        count = tonumber(reaper.GetExtState(utils.ExtStateSection.GLOBAL, utils.ExtStateKeys.USAGE_COUNT))
    else
        count = 0
    end
    if not count then count = 0 end
    count = count + 1
    reaper.SetExtState(utils.ExtStateSection.GLOBAL, utils.ExtStateKeys.USAGE_COUNT, count, true)
end

--------------------------------------------------
BLK_IncreaseUsedCount()
