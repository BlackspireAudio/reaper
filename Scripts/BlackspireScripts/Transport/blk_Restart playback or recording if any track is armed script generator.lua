-- @description Enables the generation of "Restart playback or recording if any track is armed" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 600,  -- optional, default is 1000
    gui_height = 300, -- optional, default is 300
    gui_chbl_h = 100,
    gui_title = '"Restart playback or recording if any track is armed" script generator',
    author = "Blackspire",
    version = "1.0",
    script_template_folder = {
        reaper.GetResourcePath(), "Scripts", "BlackspireScripts", "Transport"
    },
    script_template_file = "blk_Restart playback or recording if any track is armed template.lua",
    script_name_prefix = "blk_gen_",
    description_template = "Restart playback or recording if any track is armed (%save_recorded_media% recorded media%force_pre_roll%)",
    params = {
        [1] = {
            name = "force_pre_roll",
            options = {
                [1] = {
                    description = "true",
                    script_name_modifier = ", force pre-roll",
                    value = true
                },
                [2] = {
                    description = "false",
                    script_name_modifier = "",
                    value = false
                }
            }
        },
        [2] = {
            name = "save_recorded_media",
            options = {
                [1] = {
                    description = "delete recorded media",
                    script_name_modifier = "delete",
                    value = 0
                },
                [2] = {
                    description = "save recorded media",
                    script_name_modifier = "save",
                    value = 1
                },
                [3] = {
                    description = "prompt (if activated in settings)",
                    script_name_modifier = "prompt to save or delete",
                    value = 2
                }
            }
        }
    }
}

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
local sgm = require "script_generator"

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
sgm.OpenScriptVariationsGeneratorGUI(script_gen_specs)
