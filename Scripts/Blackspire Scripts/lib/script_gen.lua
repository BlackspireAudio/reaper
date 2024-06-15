-- @description holds functions to create the Lokasenna_GUI for the script variations generator
-- @author BlackSpire
-- @noindex

----------------------------------------------------------------------------------------------------
-------------------------------------SCRIPT GENERATOR SPECS EXAMPLE---------------------------------
----------------------------------------------------------------------------------------------------
-- script_gen_specs = {
--     gui_width = 1200, --optional, default is 1000
--     gui_height = 300, --optional, default is 300
--     gui_x = -200, --optional, default is -200
--     gui_y = -200, --optional, default is -200
--     gui_chbl_w = 200, --optional, default uses gui width and number of params for equal spacing
--     gui_chbl_h = 70,
--     author = "BlackSpire",
--     version = "1.0",
--     script_template_folder = { reaper.GetResourcePath(), "Scripts", "BlackSpire Scripts", "Track Properties" },
--     script_template_file = "blackspire_Toggle solo track template.lua",
--     description_template = "Toggle solo on %mouse% (%in_place%, %group%, %select%%exclusive%)",
--     script_name_template = "%author%_%description%.lua", --optional, default is "%author%_%description%.lua"
--     params = {
--         [1] = {
--             name = "mouse",
--             options = {
--                 [1] = { description = "target track under mouse", script_name_modifier = "track under mouse", value = true },
--                 [2] = { description = "target selected tracks", script_name_modifier = "selected track", value = false },
--             }
--         },
--         [2] = {
--             name = "select",
--             options = {
--                 [1] = { description = "select target track", script_name_modifier = "change selection", value = true },
--                 [2] = { description = "keep original selection", script_name_modifier = "keep selection", value = false },
--             }
--         },
--         [3] = {
--             name = "in_place",
--             options = {
--                 [1] = { description = "in-place", script_name_modifier = "in-place", value = true },
--                 [2] = { description = "not-in-place", script_name_modifier = "not-in-place", value = false },
--             }
--         },
--         [4] = {
--             name = "group",
--             options = {
--                 [1] = { description = "affect track group", script_name_modifier = "respect grouping", value = true },
--                 [2] = { description = "affect only target track", script_name_modifier = "ignore grouping", value = false },
--             }
--         },
--         [5] = {
--             name = "exclusive",
--             options = {
--                 [1] = { description = "exclusive solo", script_name_modifier = ", exclusive", value = true },
--                 [2] = { description = "normal solo", script_name_modifier = "", value = false },
--             }
--         },
--     }
-- }
----------------------------------------------------------------------------------------------------
-------------------------------------SCRIPT GENERATOR SPECS EXAMPLE---------------------------------
----------------------------------------------------------------------------------------------------

function TryLoadGuiLibs(libs)
    local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
    if not lib_path or lib_path == "" then
        reaper.MB(
            "Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v2 library path.lua' in the Lokasenna_GUI folder.",
            "Whoops!", 0)
        return false
    end
    loadfile(lib_path .. "Core.lua")()
    for i = 1, #libs do
        GUI.req(libs[i])()
    end

    if missing_lib then return false end
    return true
end

---Dynamically create a Lokasenna_GUI to select enabled options for the given script variation parameters
---@param script_gen_specs any table holding all relevant gui and script generation parameters (refer to the top of the file for an example)
function OpenScriptVariationsGeneratorGUI(script_gen_specs)
    if not TryLoadGuiLibs({ "Classes/Class - Button.lua", "Classes/Class - Options.lua", "Classes/Class - Label.lua" }) then
        return
    end

    GUI.name = "Script Variation Generator"
    GUI.anchor, GUI.corner = "mouse", "C"

    GUI.x = script_gen_specs.gui_x or -200
    GUI.y = script_gen_specs.gui_y or -200
    GUI.w = script_gen_specs.gui_width or 1000
    GUI.h = script_gen_specs.gui_height or 300

    w_spacer = 20
    h_spacer = 20
    h_lbl = 20

    w_chbl = script_gen_specs.gui_chbl_w or (GUI.w - 2 * w_spacer) / #script_gen_specs.params - w_spacer
    h_chbl = script_gen_specs.gui_chbl_h or 70

    y = h_spacer
    x = w_spacer

    gui_elements = {}
    gui_elements.lbl_script_template = {
        type = "Label",
        z = 11,
        x = x,
        y = y,
        h = h_lbl,
        caption = script_gen_specs.gui_title,
    }

    y = y + h_lbl + h_spacer

    for i, param in ipairs(script_gen_specs.params) do
        local gui_options = {}
        for k, option in ipairs(param.options) do
            gui_options[k] = option.description
        end
        gui_elements[param.name] = {
            type = "Checklist",
            z = 11,
            x = x + (i - 1) * (w_chbl + w_spacer),
            y = y,
            w = w_chbl,
            h = h_chbl,
            caption = param.name,
            optarray = gui_options,
        }
    end

    y = y + h_chbl + h_spacer

    gui_elements.btn_generate_from_selection = {
        type = "Button",
        z = 11,
        x = x,
        y = y,
        w = 150,
        h = 32,
        caption = "Select All",
        func = function()
            SelectAllGUIOptions(script_gen_specs)
        end,
    }

    gui_elements.btn_generate_all_combinations = {
        type = "Button",
        z = 11,
        x = x + w_chbl + w_spacer,
        y = y,
        w = 150,
        h = 32,
        caption = "Generate from selection",
        func = function()
            local enabled_options = TryGetGUISelections(script_gen_specs)
            if enabled_options then
                GenerateSelectedScriptVariations(script_gen_specs, enabled_options)
            end
        end,
    }

    GUI.CreateElms(gui_elements)
    GUI.Init()
    GUI.Main()
end

---Checks all check boxes in the GUI
function SelectAllGUIOptions(script_gen_specs)
    for i, param in ipairs(script_gen_specs.params) do
        values = {}
        for j, option in ipairs(param.options) do
            values[j] = true
        end
        GUI.Val(param.name, values)
    end
end

---Tries to get all enabled options from the GUI
---@param script_gen_specs table table holding all relevant gui and script generation parameters (refer to the top of the file for an example)
---@return table enabled_options 2D table holding all enabled options per script variation parameter if at leas one option is selected for each parameter, false otherwise
function TryGetGUISelections(script_gen_specs)
    local enabled_options = {}
    for param_index, param in ipairs(script_gen_specs.params) do
        enabled_options[param_index] = {}
        local j = 1
        for option_index, val in ipairs(GUI.Val(param.name)) do
            if val then
                enabled_options[param_index][j] = option_index
                j = j + 1
            end
        end
        if j == 1 then
            reaper.MB("Please select at least one option for " .. param.name, "Whoops!", 0)
            return false
        end
    end
    return enabled_options
end

---Generate all possible script variations based on the selected options
---@param script_gen_specs table table holding all relevant gui and script generation parameters (refer to the top of the file for an example)
---@param enabled_options table 2D table holding all enabled options per script variation parameter
function GenerateSelectedScriptVariations(script_gen_specs, enabled_options)
    local all_combinations = GenerateCombinations(enabled_options)
    local script_names = {}
    local script_paths = {}
    for i, selected_option_ids in ipairs(all_combinations) do
        script_names[i], script_paths[i] = TryGenerateScriptVariation(script_gen_specs, selected_option_ids)
        if not script_names[i] then
            return
        end
    end
    local loaded = true
    for i = 1, #script_paths - 1 do
        loaded = reaper.AddRemoveReaScript(true, 0, script_paths[i], false) > 0 and loaded
    end
    loaded = reaper.AddRemoveReaScript(true, 0, script_paths[#script_paths], true) > 0 and loaded
    
    if not loaded then
        reaper.MB("Couldn't auto load all generated scripts. This means, that you will need to manually load the generated scripts using the action list 'load ReaScript' option", "Ignorable Whoops!", 0)
    end

    reaper.MB(
        "Successfully created " .. (loaded and "and loaded" or "") .. " the scripts:\n\n" ..
        table.concat(script_names, "\n") ..
        "\n\nat " .. table.concat(script_gen_specs.script_template_folder, package.config:sub(1, 1)), "Noice!", 0)
end

---Generate all possible combinations of enabled options
function GenerateCombinations(options, depth, branch)
    depth = depth or 1
    branch = branch or {}
    local result = {}

    if depth > #options then
        return { branch }
    else
        for i = 1, #options[depth] do
            local newBranch = { table.unpack(branch) }
            newBranch[depth] = options[depth][i]
            local subResult = GenerateCombinations(options, depth + 1, newBranch)
            for _, v in ipairs(subResult) do
                table.insert(result, v)
            end
        end
    end

    return result
end

---Use the script_gen_specs to replace the placeholders in the script template with the selected options and save the script
---@param script_gen_specs table table holding all relevant gui and script generation parameters (refer to the top of the file for an example)
---@param selected_option_ids table table holding all selected option ids of a script variation
---@return boolean success true if the script was successfully generated, false otherwise
function TryGenerateScriptVariation(script_gen_specs, selected_option_ids)
    local os_sep = package.config:sub(1, 1)
    local description_template = script_gen_specs.description_template
    local script_name = script_gen_specs.script_name_template or "%author%_%description%.lua"

    local script_content = ""
    local script_folder = table.concat(script_gen_specs.script_template_folder, os_sep)
    local script_template_file_path = table.concat({ script_folder, script_gen_specs.script_template_file }, os_sep)
    local script_template_file = io.open(script_template_file_path, "r")
    if script_template_file then
        script_content = script_template_file:read("*a")
        script_template_file:close()
        for i, selected_option_id in ipairs(selected_option_ids) do
            local param = script_gen_specs.params[i]
            local option = param.options[selected_option_id]
            description_template = description_template:gsub("%%" .. param.name .. "%%", option.script_name_modifier)
            script_content = script_content:gsub("%%" .. param.name .. "%%", tostring(option.value))
        end

        script_content = script_content:gsub("%%description%%", description_template)
        script_name = script_name:gsub("%%description%%", description_template)
        script_content = script_content:gsub("%%author%%", script_gen_specs.author)
        script_name = script_name:gsub("%%author%%", script_gen_specs.author:lower())
        script_content = script_content:gsub("%%version%%", script_gen_specs.version)
    else
        reaper.MB("Couldn't open script template file " .. script_template_file_path, "Whoops!", 0)
        return false
    end
    local script_file_path = table.concat({ script_folder, script_name }, os_sep)
    local script_file = io.open(script_file_path, "w")
    if script_file then
        script_file:write(script_content)
        script_file:close()
    else
        reaper.MB("Couldn't open " .. script_name, "Whoops!", 0)
        return false
    end
    return script_name, script_file_path
end
