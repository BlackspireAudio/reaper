-- @description Enables the generation of "Toggle SWS solo and mute state slot" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author Blackspire
-- @changelog

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 1000, -- optional, default is 1000
    gui_height = 800, -- optional, default is 300
    gui_chbl_h = 500,
    gui_title = '"Toggle SWS solo and mute state slot" script generator',
    author = "Blackspire",
    version = "1.0",
    script_template_folder = {
        reaper.GetResourcePath(), "Scripts", "BlackspireScripts",
        "Tracks Properties"
    },
    script_template_file = "blk_Toggle SWS solo and mute state slot template.lua",
    script_name_prefix = "blk_gen_",
    description_template = "Toggle SWS %solo_mute% slot %slot% %save_on_reset%Reset and Recall%selection%",
    params = {
        [1] = { name = "slot", options = {} },
        [2] = {
            name = "save_on_reset",
            options = {
                [1] = {
                    description = "save before resetting",
                    script_name_modifier = "Save+",
                    value = true
                },
                [2] = {
                    description = "reset only",
                    script_name_modifier = "",
                    value = false
                }
            }
        },
        [3] = {
            name = "solo_mute",
            options = {
                [1] = {
                    description = "clear solo and mute on reset",
                    script_name_modifier = "solo and mute",
                    value = 0
                },
                [2] = {
                    description = "clear solo on reset",
                    script_name_modifier = "solo",
                    value = 1
                },
                [3] = {
                    description = "clear mute on reset",
                    script_name_modifier = "mute",
                    value = 2
                }
            }
        },
        [4] = {
            name = "selection",
            options = {
                [1] = {
                    description = "store and recal selected tracks",
                    script_name_modifier = " on selected tracks",
                    value = true
                },
                [2] = {
                    description = "store and recal all tracks",
                    script_name_modifier = "",
                    value = false
                }
            }
        }
    }
}

for i = 1, 16 do
    table.insert(script_gen_specs.params[1].options,
        { description = i, script_name_modifier = i, value = i })
end

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
