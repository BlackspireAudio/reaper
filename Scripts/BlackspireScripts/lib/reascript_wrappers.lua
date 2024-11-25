local utils = require 'utils'

local rprw = {}

-- @description holds wrapper functions for reaper API functions
-- @author Blackspire
-- @noindex
function rprw.GetTrackUnderMouseCursor()
    local x, y = reaper.GetMousePosition()
    local track, info = reaper.GetTrackFromPoint(x, y)
    return track
end

---Get all selected tracks excluding tracks in the exclude_tracks table
---@param exclude_tracks table table of tracks to exclude from the selection
---@param project int optional project index
---@return table selected_tracks table of selected tracks excluding tracks in the exclude_tracks table
function rprw.GetSelectedTracks(exclude_tracks, project)
    project = project or 0
    local exclude_track_numbers = {}
    for i = 1, #exclude_tracks do
        exclude_track_numbers[i] = reaper.GetMediaTrackInfo_Value(
            exclude_tracks[i], "IP_TRACKNUMBER")
    end

    local selected_tracks = {}
    for i = reaper.CountSelectedTracks(project) - 1, 0, -1 do
        track = reaper.GetSelectedTrack(project, i)
        local exclude = false
        for i = 1, #exclude_track_numbers do
            if reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") ==
                exclude_track_numbers[i] then
                exclude = true
            end
        end
        if not exclude then selected_tracks[#selected_tracks + 1] = track end
    end
    return selected_tracks
end

---Get all child tracks of a folder track
---@param track MediaTrack track to get child tracks from
---@param inclusive boolean true to include the provided track in the returned table
---@return table child_tracks table of child tracks or empty table if track is not a folder track
function rprw.GetChildTracks(track, inclusive)
    local child_tracks = {}
    if inclusive then child_tracks[#child_tracks + 1] = track end
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        -- child track search always starts at relative depth of 1
        local relative_depth = 1
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local num_tracks = reaper.CountTracks(0)
        -- iterate over all tracks after the provided track untill we are back at the same folder depth
        -- note that GetMediaTrackInfo_Value returns 1-indexed track numbers and GetTrack uses 0-indexed track numbers
        for i = track_id, num_tracks - 1 do
            local child_track = reaper.GetTrack(0, i)
            child_tracks[#child_tracks + 1] = child_track
            local folder_depth = reaper.GetMediaTrackInfo_Value(child_track,
                "I_FOLDERDEPTH")
            if folder_depth == 1 then
                -- if child track is a folder track, increment relative depth
                relative_depth = relative_depth + 1
            elseif folder_depth < 0 then
                -- if child track is last track in a folder, decrement relative depth by folder temination tier
                relative_depth = relative_depth - folder_depth
            end
            if relative_depth <= 0 then
                -- if we are back at the original folder depth, break the loop as we have found all child tracks
                break
            end
        end
    end
    return child_tracks
end

---Get all selected items
---@param project int optional project index
---@return table selected_items table of selected items
function rprw.GetSelectedItems(project)
    project = project or 0
    local selected_items = {}
    for i = reaper.CountSelectedMediaItems(project) - 1, 0, -1 do
        selected_items[i + 1] = reaper.GetSelectedMediaItem(project, i)
    end
    return selected_items
end

function rprw.SelectTracks(tracks)
    for i = 1, #tracks do
        if tracks[i] then reaper.SetTrackSelected(tracks[i], true) end
    end
end

function rprw.SelectItems(items)
    for i = 1, #items do reaper.SetMediaItemSelected(items[i], true) end
end

---Set Mute state on track
---@param track MediaTrack track to set mute state on
---@param mute boolean true to mute track, false to unmute
---@param group any false to ignore track grouping
function rprw.SetTrackUIMute(track, mute, group)
    reaper.SetTrackUIMute(track, utils.BoolInt(mute), group and 0 or 1)
end

---Set Solo state on track
---@param track MediaTrack track to set solo state on
---@param solo boolean true to solo track, false to unsolo
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
---@param group boolean false to ignore track grouping
function rprw.SetTrackUISolo(track, solo, in_place, group)
    local i_solo = 0 -- unsolo track
    if solo then
        if in_place then
            i_solo = 4 -- solo in place (respect routing)
        else
            i_solo = 2 -- solo not in place (ignore routing)
        end
    end
    reaper.SetTrackUISolo(track, i_solo, group and 0 or 1)
end

function rprw.UnmuteAllTracks() reaper.Main_OnCommand(40339, 0) end

function rprw.UnsoloAllTracks() reaper.Main_OnCommand(40340, 0) end

function rprw.SelectTrackUnterMouse() reaper.Main_OnCommand(41110, 0) end

function rprw.GroupSelectedItems() reaper.Main_OnCommand(40032, 0) end

function rprw.GetPositionUnderMouseCursor()
    reaper.BR_GetMouseCursorContext()
    return reaper.BR_GetMouseCursorContext_Position()
end

---Call one of the SWS/BR mute/solo slot save/restore commands based on the provided parameters
---@param slot_id int 1-indexed slot number from the SWS extension (1-16)
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
---@param store boolean true to save current state, false to restore saved state
function rprw.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, store)
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

---Get the current record arm, mode and monitor states of a track. Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#GetMediaTrackInfo_Value for infos on the values
---@param track MediaTrack track to get states from
---@return int rec_arm record arm state
---@return int rec_mode record mode state
---@return int rec_mon monitor state
function rprw.GetTrackArmModeMonStates(track)
    local rec_arm = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
    local rec_mode = reaper.GetMediaTrackInfo_Value(track, "I_RECMODE")
    local rec_mon = reaper.GetMediaTrackInfo_Value(track, "I_RECMON")
    return rec_arm, rec_mode, rec_mon
end

---Set the record arm, mode and monitor states of a track. Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#SetMediaTrackInfo_Value for infos on the values
---If the track has an instrument plugin and input is set to audio, input will be set to "MIDI: All MIDI Inputs and Channels"
---@param track MediaTrack track to set states on
---@param rec_arm int record arm state
---@param rec_mode int record mode state
---@param rec_mon int monitor state
function rprw.SetTrackArmModeMonStates(track, rec_arm, rec_mode, rec_mon)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", rec_arm)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", rec_mode)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", rec_mon)
    if rprw.HasInstrumentFX(track) and
        reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT") < 4096 then
        -- if track has an instrument plugin and input is set to audio, set input to "MIDI: All MIDI Inputs and Channels"
        reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 6112)
    end
end

function rprw.HasInstrumentFX(track)
    return reaper.TrackFX_GetInstrument(track) >= 0
end

function rprw.GetMIDIEditorActiveTake()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return false end
    return reaper.MIDIEditor_GetTake(midi_editor)
end

function rprw.GetMIDIEditorActiveTakeItem()
    local take = rprw.GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Item(take)
end

function rprw.GetMIDIEditorActiveTakeTrack()
    local take = rprw.GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Track(take)
end

function rprw.GetMediaItemUnderMouseCursor()
    local item, pos = reaper.BR_ItemAtMouseCursor()
    local take
    if not item then
        local screen_x, screen_y = reaper.GetMousePosition()
        item, take = reaper.GetItemFromPoint(screen_x, screen_y, true)
    end
    return item, pos
end

function rprw.SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    reaper.Main_OnCommand(40034, 0)
end

function rprw.UnselectAllMediaItems() reaper.Main_OnCommand(40289, 0) end

function rprw.DeleteTrack(track)
    local track_folder_depth = reaper.GetMediaTrackInfo_Value(track,
        "I_FOLDERDEPTH")

    if track_folder_depth < 0 then
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        if track_id > 0 then
            local prev_track = reaper.GetTrack(0, track_id - 2)
            -- if reaper.GetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH") == 1 then
            --     reaper.SetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH", 0)
            -- else
            reaper.SetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH",
                track_folder_depth + 1)
            -- end
        end
    else
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local num_tracks = reaper.CountTracks(0)

        for i = track_id, num_tracks - 1 do
            local track = reaper.GetTrack(0, i)
            tack_folder_depth = reaper.GetMediaTrackInfo_Value(track,
                "I_FOLDERDEPTH")
            if track_folder_depth < -1 then
                reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH",
                    track_folder_depth + 1)
            elseif track_folder_depth == -1 then
                break
            end
        end
    end
    reaper.DeleteTrack(track)
end

function rprw.SetExtState(section, key, value, persist)
    reaper.SetExtState(utils.GetExtStateSectionName(section), key, value,
        persist or false)
end

function rprw.GetExtState(section, key)
    return reaper.GetExtState(utils.GetExtStateSectionName(section), key)
end

function rprw.DeleteExtState(section, key, persist)
    return reaper.DeleteExtState(utils.GetExtStateSectionName(section), key,
        persist or false)
end

function rprw.HasExtState(section, key)
    return reaper.HasExtState(utils.GetExtStateSectionName(section), key)
end

function rprw.SetTransportExtState(key, value, persist)
    rprw.SetExtState("transport", key, value, persist)
end

function rprw.GetTransportExtState(key)
    return
        rprw.GetExtState("transport", key)
end

function rprw.DeleteTransportExtState(key, persist)
    rprw.DeleteExtState("transport", key, persist)
end

function rprw.HasTransportExtState(key)
    return
        rprw.HasExtState("transport", key)
end

function rprw.SetGlobalExtState(key, value, persist)
    rprw.SetExtState("global", key, value, persist)
end

function rprw.GetGlobalExtState(key) return rprw.GetExtState("global", key) end

function rprw.DeleteGlobalExtState(key, persist)
    rprw.DeleteExtState("global", key, persist)
end

function rprw.HasGlobalExtState(key) return rprw.HasExtState("global", key) end

function rprw.SetMidiExtState(key, value, persist)
    rprw.SetExtState("midi", key, value, persist)
end

function rprw.GetMidiExtState(key) return rprw.GetExtState("midi", key) end

function rprw.DeleteMidiExtState(key, persist)
    rprw.DeleteExtState("midi", key, persist)
end

function rprw.HasMidiExtState(key) return rprw.HasExtState("midi", key) end

return rprw
