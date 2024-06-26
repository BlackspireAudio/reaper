-- @description Enables the generation of "Split item" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author BlackSpire
-- @changelog

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 1200,
    gui_height = 500,
    gui_chbl_h = 300,

    gui_title = '"Split item" script generator',
    author = "BlackSpire",
    version = "1.0",
    script_template_folder = { reaper.GetResourcePath(), "Scripts", "BlackSpire Scripts", "Items Editing" },
    script_template_file = "blackspire_Split item template.lua",
    description_template = "Split %target% at %split% (%select%, %group%)",
    params = {
        [1] = {
            name = "target",
            options = {
                [1] = { description = "target selected items", script_name_modifier = "selected items", value = 0 },
                [2] = { description = "target (selected) item(s) under mouse", script_name_modifier = "(selected) item(s) under mouse", value = 1 },
                [3] = { description = "target only item under mouse", script_name_modifier = "item under mouse", value = 2 },
            }
        },
        [2] = {
            name = "split",
            options = {
                [1] = { description = "at edit cursor", script_name_modifier = "edit cursor", value = 0 },
                [2] = { description = "at time selection", script_name_modifier = "time selection", value = 1 },
                [3] = { description = "at mouse cursor", script_name_modifier = "mouse", value = 2 },
                [4] = { description = "at mouse cursor ignoring snap", script_name_modifier = "mouse without snap", value = 3 },
            }
        },
        [3] = {
            name = "select",
            options = {
                [1] = { description = "retain original selection", script_name_modifier = "keep selection", value = 0 },
                [2] = { description = "select left item", script_name_modifier = "select left", value = 1 },
                [3] = { description = "select right item", script_name_modifier = "select right", value = 2 },
                [4] = { description = "select both items", script_name_modifier = "select both", value = 3 },
                [5] = { description = "select shorter item", script_name_modifier = "select short", value = 4 },
                [6] = { description = "select longer item", script_name_modifier = "select long", value = 5 },
                [7] = { description = "select quieter item", script_name_modifier = "select quiet", value = 6 },
                [8] = { description = "select louder item", script_name_modifier = "select loud", value = 7 },
            }
        },
        [4] = {
            name = "group",
            options = {
                [1] = { description = "respect item grouping", script_name_modifier = "respect grouping", value = true },
                [2] = { description = "ignore item grouping", script_name_modifier = "ignore grouping", value = false },
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
