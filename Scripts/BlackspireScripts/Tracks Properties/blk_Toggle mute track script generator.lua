-- @description Enables the generation of "Toggle track mute" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 1000, -- optional, default is 1000
    gui_chbl_h = 70,
    gui_title = '"Toggle mute track" script generator',
    author = "Blackspire",
    version = "1.0",
    script_template_folder = {
        reaper.GetResourcePath(), "Scripts", "BlackspireScripts",
        "Tracks Properties"
    },
    script_template_file = "blk_Toggle mute track template.lua",
    script_name_prefix = "blk_gen_",
    description_template = "Toggle mute on %mouse% (%group%, %selection%%exclusive%)",
    params = {
        [1] = {
            name = "mouse",
            options = {
                [1] = {
                    description = "target track under mouse",
                    script_name_modifier = "track under mouse",
                    value = true
                },
                [2] = {
                    description = "target selected tracks",
                    script_name_modifier = "selected track",
                    value = false
                }
            }
        },
        [2] = {
            name = "selection",
            options = {
                [1] = {
                    description = "select target track",
                    script_name_modifier = "change selection",
                    value = true
                },
                [2] = {
                    description = "keep original selection",
                    script_name_modifier = "keep selection",
                    value = false
                }
            }
        },
        [3] = {
            name = "group",
            options = {
                [1] = {
                    description = "affect track group",
                    script_name_modifier = "respect grouping",
                    value = true
                },
                [2] = {
                    description = "affect only target track",
                    script_name_modifier = "ignore grouping",
                    value = false
                }
            }
        },
        [4] = {
            name = "exclusive",
            options = {
                [1] = {
                    description = "exclusive mute",
                    script_name_modifier = ", exclusive",
                    value = true
                },
                [2] = {
                    description = "normal mute",
                    script_name_modifier = "",
                    value = false
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
