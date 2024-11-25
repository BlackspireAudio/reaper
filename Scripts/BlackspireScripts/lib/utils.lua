-- @description holds general helper functions
-- @author Blackspire
-- @noindex

local utils = {}
function utils.BoolInt(bool) return bool and 1 or 0 end

function utils.GetExtStateSectionName(suffix)
    return 'blackspire' .. (suffix and ('_' .. suffix) or '')
end

function utils.msg(message)
    reaper.ShowConsoleMsg(tostring(message) .. '\n')
end

local ext_state_prefix = 'blackspire'
utils.ExtStateSection = {
    GLOBAL = ext_state_prefix,
    TRANSPORT = ext_state_prefix .. '_transport',
    TRACK = ext_state_prefix .. '_track',
    ITEM = ext_state_prefix .. '_item',
    PROJECT = ext_state_prefix .. '_project',
    MIDI = ext_state_prefix .. '_midi',
}
utils.ExtStateKeys={
    USAGE_COUNT='counttotal'
}

return utils