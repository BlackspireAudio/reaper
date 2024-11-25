-- @description Enables the generation of "Split item" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 1200,
    gui_height = 500,
    gui_chbl_h = 300,

    gui_title = '"Split item" script generator',
    author = "Blackspire",
    version = "1.0",
    script_template_folder = {
        reaper.GetResourcePath(), "Scripts", "BlackspireScripts",
        "Items Editing"
    },
    script_template_file = "blk_Split item template.lua",
    script_name_prefix = "blk_gen_",
    description_template = "Split %target% at %split% (%selection%, %group%)",
    params = {
        [1] = {
            name = "target",
            options = {
                [1] = {
                    description = "target selected items",
                    script_name_modifier = "selected items",
                    value = 0
                },
                [2] = {
                    description = "target (selected) item(s) under mouse",
                    script_name_modifier = "(selected) item(s) under mouse",
                    value = 1
                },
                [3] = {
                    description = "target only item under mouse",
                    script_name_modifier = "item under mouse",
                    value = 2
                }
            }
        },
        [2] = {
            name = "split",
            options = {
                [1] = {
                    description = "at edit cursor",
                    script_name_modifier = "edit cursor",
                    value = 0
                },
                [2] = {
                    description = "at time selection",
                    script_name_modifier = "time selection",
                    value = 1
                },
                [3] = {
                    description = "at mouse cursor",
                    script_name_modifier = "mouse",
                    value = 2
                },
                [4] = {
                    description = "at mouse cursor ignoring snap",
                    script_name_modifier = "mouse without snap",
                    value = 3
                }
            }
        },
        [3] = {
            name = "selection",
            options = {
                [1] = {
                    description = "retain original selection",
                    script_name_modifier = "keep selection",
                    value = 0
                },
                [2] = {
                    description = "select left item",
                    script_name_modifier = "select left",
                    value = 1
                },
                [3] = {
                    description = "select right item",
                    script_name_modifier = "select right",
                    value = 2
                },
                [4] = {
                    description = "select both items",
                    script_name_modifier = "select both",
                    value = 3
                },
                [5] = {
                    description = "select shorter item",
                    script_name_modifier = "select short",
                    value = 4
                },
                [6] = {
                    description = "select longer item",
                    script_name_modifier = "select long",
                    value = 5
                },
                [7] = {
                    description = "select quieter item",
                    script_name_modifier = "select quiet",
                    value = 6
                },
                [8] = {
                    description = "select louder item",
                    script_name_modifier = "select loud",
                    value = 7
                }
            }
        },
        [4] = {
            name = "group",
            options = {
                [1] = {
                    description = "respect item grouping",
                    script_name_modifier = "respect grouping",
                    value = true
                },
                [2] = {
                    description = "ignore item grouping",
                    script_name_modifier = "ignore grouping",
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
