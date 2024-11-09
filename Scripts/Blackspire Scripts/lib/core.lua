-- @description entry point for the BlackSpire Scripts library
-- @author BlackSpire
-- @noindex

bs_lib_version = 1.0
--------------------------------------------------
function BSLoadLibraries(version, required_libs)
    local info = debug.getinfo(1, 'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])

    if not version or version > bs_lib_version then
        reaper.MB(
            'Update ' .. script_path:gsub('%\\', '/') .. ' to version ' .. version .. ' or newer', 'BlackSpire Scripts',
            0)
        return false
    end

    if required_libs then
        for i = 1, #required_libs do
            dofile(script_path .. required_libs[i])
        end
    else
        dofile(script_path .. "track_properties.lua")
        dofile(script_path .. "helper_functions.lua")
        dofile(script_path .. "rprw.lua")
        dofile(script_path .. "script_gen.lua")
    end
    return true
end

---------------------------------------------------
function BSIncrUsedCount()
    local cnt = reaper.GetExtState('BlackSpire_Scripts', 'counttotal')
    if cnt == '' then cnt = 0 end
    cnt = tonumber(cnt)
    if not cnt then cnt = 0 end
    cnt = cnt + 1
    reaper.SetExtState('BlackSpire_Scripts', 'counttotal', cnt, true)
end

--------------------------------------------------
BSIncrUsedCount()
