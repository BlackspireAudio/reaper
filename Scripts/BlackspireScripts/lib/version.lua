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

local misc = require 'misc'
---------------------------------------------------
function BLK_IncreaseUsedCount()
    local cnt = misc.GetExtStateNumber(misc.ExtStateSection.GLOBAL, misc.ExtStateKeys.USAGE_COUNT, 0)
    misc.SetExtState(misc.ExtStateSection.GLOBAL, misc.ExtStateKeys.USAGE_COUNT, cnt + 1, true)
end

--------------------------------------------------
BLK_IncreaseUsedCount()
