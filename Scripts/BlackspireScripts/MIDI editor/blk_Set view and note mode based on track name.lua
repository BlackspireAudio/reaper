-- @description Set view and note mode based on track name
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Set editor and event view mode'
-- default configs to cycle through if track name doesn't match any named config
local default_cycle_config = {
    [1] = {
        40449, -- rectangle
        40042 -- piano roll
    },
    [2] = {
        40448, -- triangle
        40043 -- named notes
    }
}

-- specific configs for tracks that start with a certain string
local named_config = {
    [1] = {
        patterns = {"^bass"},
        cmd_ids = {
            40449, -- rectangle
            40043 -- named notes
        }
    },
    [2] = {
        patterns = {"^drum"},
        cmd_ids = {
            40448, -- triangle
            40043 -- named notes
        }
    },
    [3] = {
        patterns = {"piano", "keys", "synth"},
        cmd_ids = {
            40449, -- rectangle
            40042 -- piano roll
        }
    }
}

--------------------------------------------------
------------------LOAD LIBRARIES------------------
--------------------------------------------------
local lib_path = reaper.GetExtState("blackspire", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackspireScripts library. Please run 'blk_Set library path.lua' in the BlackspireScripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, {"helper_functions.lua", "rprw.lua"}) then return end

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()
local is_new_value, filename, sec, cmd, mode, resolution, val =
    reaper.get_action_context()
local active_midi_editor = reaper.MIDIEditor_GetActive()
local track = rprw_GetMIDIEditorActiveTakeTrack()
local named_config_applied = false
if track then
    local _, track_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME',
                                                             "", false)
    for i, v in ipairs(named_config) do
        -- match starts_with case insensitive
        for _, pattern in ipairs(v.patterns) do
            if string.match(string.lower(track_name), pattern) then
                for j, cmd_id in ipairs(v.cmd_ids) do
                    reaper.MIDIEditor_OnCommand(active_midi_editor, cmd_id)
                end
                named_config_applied = true
                break
            end
        end
    end
    if not named_config_applied then
        local current_config_index = 0
        for i, default_config in ipairs(default_cycle_config) do
            local full_match = true
            for j, cmd_id in ipairs(default_config) do
                if reaper.GetToggleCommandStateEx(sec, cmd_id) == 0 then
                    full_match = false
                    break
                end
            end
            if full_match then
                current_config_index = i
                break
            end
        end
        local next_config_index = (((current_config_index + 1) - 1) %
                                      #default_cycle_config) + 1
        for i, cmd_id in ipairs(default_cycle_config[next_config_index]) do
            reaper.MIDIEditor_OnCommand(active_midi_editor, cmd_id)
        end

    end
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found