-- @description Enables the generation of "Restart playback or recording if any track is armed" script variations using the Lokasenna_GUI v2 library
-- @version 1.0
-- @author BlackSpire
-- @changelog


--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
script_gen_specs = {
    gui_width = 600, --optional, default is 1000
    gui_height = 300, --optional, default is 300
    gui_chbl_h = 100,
    gui_title = '"Restart playback or recording if any track is armed" script generator',
    author = "BlackSpire",
    version = "1.0",
    script_template_folder = { reaper.GetResourcePath(), "Scripts", "BlackSpire Scripts", "Transport" },
    script_template_file = "blackspire_Restart playback or recording if any track is armed template.lua",
    description_template = "Restart playback or recording if any track is armed (%save_recorded_media% recorded media%force_pre_roll%)",
    params = {
        [1] = {
            name = "force_pre_roll",
            options = {
                [1] = { description = "true", script_name_modifier = ", force pre-roll", value = true },
                [2] = { description = "false", script_name_modifier = "", value = false },
            }
        },
        [2] = {
            name = "save_recorded_media",
            options = {
                [1] = { description = "delete recorded media", script_name_modifier = "delete", value = 0 },
                [2] = { description = "save recorded media", script_name_modifier = "save", value = 1 },
                [3] = { description = "prompt (if activated in settings)", script_name_modifier = "prompt to save or delete", value = 2 },
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