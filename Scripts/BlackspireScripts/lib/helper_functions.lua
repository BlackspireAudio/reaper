-- @description holds general helper functions
-- @author Blackspire
-- @noindex
function BoolInt(bool) return bool and 1 or 0 end

function GetExtStateSectionName(suffix)
    return 'blackspire' .. (suffix and ('_' .. suffix) or '')
end
