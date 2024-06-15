-- @description Enables the generation of Toggle track solo script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author BlackSpire
-- @changelog

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 1200, --optional, default is 1000
    gui_chbl_h = 70,
    gui_title = '"Toggle solo track" script generator',
    author = "BlackSpire",
    version = "1.0",
    script_template_folder = { reaper.GetResourcePath(), "Scripts", "BlackSpire Scripts", "Track Properties" },
    script_template_file = "blackspire_Toggle solo track template.lua",
    description_template = "Toggle solo on %mouse% (%in_place%, %group%, %select%%exclusive%)",
    params = {
        [1] = {
            name = "mouse",
            options = {
                [1] = { description = "target track under mouse", script_name_modifier = "track under mouse", value = true },
                [2] = { description = "target selected tracks", script_name_modifier = "selected track", value = false },
            }
        },
        [2] = {
            name = "select",
            options = {
                [1] = { description = "select target track", script_name_modifier = "change selection", value = true },
                [2] = { description = "keep original selection", script_name_modifier = "keep selection", value = false },
            }
        },
        [3] = {
            name = "in_place",
            options = {
                [1] = { description = "in-place", script_name_modifier = "in-place", value = true },
                [2] = { description = "not-in-place", script_name_modifier = "not-in-place", value = false },
            }
        },
        [4] = {
            name = "group",
            options = {
                [1] = { description = "affect track group", script_name_modifier = "respect grouping", value = true },
                [2] = { description = "affect only target track", script_name_modifier = "ignore grouping", value = false },
            }
        },
        [5] = {
            name = "exclusive",
            options = {
                [1] = { description = "exclusive solo", script_name_modifier = ", exclusive", value = true },
                [2] = { description = "normal solo", script_name_modifier = "", value = false },
            }
        },
    }
}


--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = reaper.GetExtState("BlackSpire_Scripts", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackSpire_Scripts library. Please run 'blackspire_Set library path.lua' in the BlackSpire Scripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, { "script_gen.lua" }) then return end

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
OpenScriptVariationsGeneratorGUI(script_gen_specs)
