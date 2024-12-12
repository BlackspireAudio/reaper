local misc = {}

local ext_state_prefix = 'blackspire'
misc.ExtStateSection = {
    GLOBAL = ext_state_prefix,
    TRANSPORT = ext_state_prefix .. '_transport',
    TRACK = ext_state_prefix .. '_track',
    ITEM = ext_state_prefix .. '_item',
    PROJECT = ext_state_prefix .. '_project',
    MIDI = ext_state_prefix .. '_midi',
}
misc.ExtStateKeys = {
    USAGE_COUNT = 'count_total',
    NOTE_COLOR = 'note_color',
}


---Set the extended state value for a specific section and key. persist=true means the value should be stored and reloaded the next time REAPER is opened.
---@param section string
---@param key string
---@param value any
---@param persist? boolean
function misc.SetExtState(section, key, value, persist)
    reaper.SetExtState(section, key, tostring(value), persist or false)
end

---Get the extended state value for a specific section and key.
---@param section string
---@param key string
---@return string ext_state
function misc.GetExtState(section, key)
    return reaper.GetExtState(section, key)
end

---Get the extended state value for a specific section and key as boolean
---@param section string
---@param key string
---@return boolean ext_state
function misc.GetExtStateBool(section, key)
    return misc.GetExtState(section, key) == "true"
end

---Get the extended state value for a specific section and key as boolean
---@param section string
---@param key string
---@param default number default value to return if the value is not found
---@return number ext_state
function misc.GetExtStateNumber(section, key, default)
    local ext_state = tonumber(misc.GetExtState(section, key))
    if ext_state == nil then
        return default
    else
        return ext_state
    end
end

---Delete the extended state value for a specific section and key. persist=true means the value should remain deleted the next time REAPER is opened.
---@param section string
---@param key string
---@param persist? boolean
function misc.DeleteExtState(section, key, persist)
    reaper.DeleteExtState(section, key, persist or false)
end

---Returns true if there exists an extended state value for a specific section and key.
---@param section string
---@param key string
---@return boolean retval
function misc.HasExtState(section, key)
    return reaper.HasExtState(section, key)
end

function misc.GetPositionUnderMouseCursor()
    reaper.BR_GetMouseCursorContext()
    return reaper.BR_GetMouseCursorContext_Position()
end

---Call one of the SWS/BR mute/solo slot save/restore commands based on the provided parameters
---@param slot_id integer 1-indexed slot number from the SWS extension (1-16)
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
---@param store boolean true to save current state, false to restore saved state
function misc.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, store)
    local command_name_fragments = { "_BR" }
    table.insert(command_name_fragments, store and "_SAVE" or "_RESTORE")
    table.insert(command_name_fragments, "_SOLO_MUTE")
    table.insert(command_name_fragments,
        selected and "_SEL_TRACKS" or "_ALL_TRACKS")
    table.insert(command_name_fragments, "_SLOT_" .. slot_id)

    reaper.Main_OnCommand(reaper.NamedCommandLookup(table.concat(
        command_name_fragments,
        "")), 0, 0)
end

return misc
