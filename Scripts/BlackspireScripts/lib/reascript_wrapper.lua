local utils = require 'utils'

local rsw = {}




---Get all selected items
---@param project? integer optional project index
---@return table selected_items table of selected items
function rsw.GetSelectedItems(project)
    project = project or 0
    local selected_items = {}
    for i = 0, reaper.CountSelectedMediaItems(project) do
        table.insert(selected_items, reaper.GetSelectedMediaItem(project, i))
    end
    return selected_items
end


---Select all items in the provided table
---@param items table items to select
function rsw.SelectItems(items)
    for i = 1, #items do reaper.SetMediaItemSelected(items[i], true) end
end

function rsw.GroupSelectedItems() reaper.Main_OnCommand(40032, 0) end

function rsw.GetPositionUnderMouseCursor()
    reaper.BR_GetMouseCursorContext()
    return reaper.BR_GetMouseCursorContext_Position()
end

---Call one of the SWS/BR mute/solo slot save/restore commands based on the provided parameters
---@param slot_id int 1-indexed slot number from the SWS extension (1-16)
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
---@param store boolean true to save current state, false to restore saved state
function rsw.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, store)
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

function rsw.GetMIDIEditorActiveTake()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return false end
    return reaper.MIDIEditor_GetTake(midi_editor)
end

function rsw.GetMIDIEditorActiveTakeItem()
    local take = rsw.GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Item(take)
end

function rsw.GetMIDIEditorActiveTakeTrack()
    local take = rsw.GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Track(take)
end

function rsw.GetMediaItemUnderMouseCursor()
    local item, pos = reaper.BR_ItemAtMouseCursor()
    local take
    if not item then
        local screen_x, screen_y = reaper.GetMousePosition()
        item, take = reaper.GetItemFromPoint(screen_x, screen_y, true)
    end
    return item, pos
end

function rsw.SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    reaper.Main_OnCommand(40034, 0)
end

function rsw.UnselectAllMediaItems() reaper.Main_OnCommand(40289, 0) end

---Set the extended state value for a specific section and key. persist=true means the value should be stored and reloaded the next time REAPER is opened.
---@param section string
---@param key string
---@param value any
---@param persist? boolean
function rsw.SetExtState(section, key, value, persist)
    reaper.SetExtState(section, key, tostring(value), persist or false)
end

---Get the extended state value for a specific section and key.
---@param section string
---@param key string
---@return string retval
function rsw.GetExtState(section, key)
    return reaper.GetExtState(section, key)
end

---Get the extended state value for a specific section and key as boolean
---@param section string
---@param key string
---@return boolean retval
function rsw.GetExtStateBool(section, key)
    return rsw.GetExtState(section, key) == "true"
end

---Get the extended state value for a specific section and key as boolean
---@param section string
---@param key string
---@return number? retval
function rsw.GetExtStateInt(section, key)
    return tonumber(rsw.GetExtState(section, key))
end

---Delete the extended state value for a specific section and key. persist=true means the value should remain deleted the next time REAPER is opened.
---@param section string
---@param key string
---@param persist? boolean
function rsw.DeleteExtState(section, key, persist)
    return reaper.DeleteExtState(section, key, persist or false)
end

---Returns true if there exists an extended state value for a specific section and key.
---@param section string
---@param key string
---@return boolean retval
function rsw.HasExtState(section, key)
    return reaper.HasExtState(section, key)
end

return rsw
