-- @description Toggle multi track editing
-- @version 1.0
-- @author Blackspire
-- @changelog
--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Toggle multi track editing'
local note_color_ext_state_key = "note_color"

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
if reaper.GetToggleCommandStateEx(sec, cmd) == 0 then
    local note_color = "pitch" -- default
    if reaper.GetToggleCommandStateEx(sec, 40738) == 1 then
        note_color = "velocity"
    elseif reaper.GetToggleCommandStateEx(sec, 41114) == 1 then
        note_color = "voice"
    elseif reaper.GetToggleCommandStateEx(sec, 40739) == 1 then
        note_color = "channel"
    elseif reaper.GetToggleCommandStateEx(sec, 40769) == 1 then
        note_color = "mediaitem"
    elseif reaper.GetToggleCommandStateEx(sec, 40741) == 1 then
        note_color = "source"
    elseif reaper.GetToggleCommandStateEx(sec, 40768) == 1 then
        note_color = "track"
    end
    rprw_SetMidiExtState(note_color_ext_state_key, note_color, true)

    reaper.MIDIEditor_OnCommand(active_midi_editor, 40768) -- Options: Color notes by track
    reaper.SetToggleCommandState(sec, cmd, 1)
    if reaper.GetToggleCommandStateEx(sec, 40901) == 1 then
        reaper.MIDIEditor_OnCommand(active_midi_editor, 40901) -- Options: Avoid setting MIDI items on other tracks editable
    end
else
    if rprw_HasMidiExtState(note_color_ext_state_key) then
        local note_color = rprw_GetMidiExtState(note_color_ext_state_key)
        if note_color == "pitch" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40740)
        elseif note_color == "velocity" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40738)
        elseif note_color == "voice" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 41114)
        elseif note_color == "channel" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40739)
        elseif note_color == "mediaitem" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40769)
        elseif note_color == "source" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40741)
        elseif note_color == "track" then
            reaper.MIDIEditor_OnCommand(active_midi_editor, 40768)
        end
    end
    reaper.SetToggleCommandState(sec, cmd, 0)
    if reaper.GetToggleCommandStateEx(sec, 40901) == 0 then
        reaper.MIDIEditor_OnCommand(active_midi_editor, 40901) -- Options: Avoid setting MIDI items on other tracks editable
    end
end

reaper.Undo_EndBlock(undo_message, -1) -- -1 = add all changes to undo state, todo: limit using appropriate flags once clear flag definition is found
