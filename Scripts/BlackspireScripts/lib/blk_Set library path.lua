-- @description Various_functions
-- @author Blackspire
-- @website https://forums.cockos.com/member.php?u=208358
-- @about Set path to libraries used by BlackspireScripts.
-- @version 1.0
-- @provides
--    track_properties.lua
--    helper_functions.lua
--    rprw.lua
--    script_gen.lua
-- @changelog
local info = debug.getinfo(1, 'S')
local script_path = info.source:match [[^@?(.*[\/])[^\/]-$]]

reaper.SetExtState("blackspire", "lib_path", script_path, true)
reaper.MB("The library path is now set to:\n" .. script_path,
          "BlackspireScripts", 0)
