-- @description holds wrapper functions for reaper API functions
-- @author BlackSpire
-- @noindex


function rprw_GetTrackUnderMouseCursor()
    local x, y = reaper.GetMousePosition()
    local track, info = reaper.GetTrackFromPoint(x, y)
    return track
end

---Set Mute state on track
---@param track MediaTrack track to set mute state on
---@param mute boolean true to mute track, false to unmute
---@param group any false to ignore track grouping
function rprw_SetTrackUIMute(track, mute, group)
    reaper.SetTrackUIMute(track, BoolInt(mute), group and 0 or 1)
end

---Set Solo state on track
---@param track MediaTrack track to set solo state on
---@param solo boolean true to solo track, false to unsolo
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
---@param group boolean false to ignore track grouping
function rprw_SetTrackUISolo(track, solo, in_place, group)
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

function rprw_UnmuteAllTracks()
    reaper.Main_OnCommand(40339, 0)
end

function rprw_UnsoloAllTracks()
    reaper.Main_OnCommand(40340, 0)
end

function rprw_SelectTrackUnterMouse()
    reaper.Main_OnCommand(41110, 0)
end

function rprw_GroupSelectedItems()
    reaper.Main_OnCommand(40032, 0)
end

function rprw_GetPositionUnderMouseCursor()
    reaper.BR_GetMouseCursorContext()
    return reaper.BR_GetMouseCursorContext_Position()
end

---Call one of the SWS/BR mute/solo slot save/restore commands based on the provided parameters
---@param slot_id int 1-indexed slot number from the SWS extension (1-16)
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
---@param store boolean true to save current state, false to restore saved state
function rprw_StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, store)
    local command_name_fragments = { "_BR" }
    table.insert(command_name_fragments, store and "_SAVE" or "_RESTORE")
    table.insert(command_name_fragments, "_SOLO_MUTE")
    table.insert(command_name_fragments, selected and "_SEL_TRACKS" or "_ALL_TRACKS")
    table.insert(command_name_fragments, "_SLOT_" .. slot_id)

    reaper.Main_OnCommand(reaper.NamedCommandLookup(table.concat(command_name_fragments, "")), 0, 0)
end

---Get the current record arm, mode and monitor states of a track. Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#GetMediaTrackInfo_Value for infos on the values
---@param track MediaTrack track to get states from
---@return int rec_arm record arm state
---@return int rec_mode record mode state
---@return int rec_mon monitor state
function rprw_GetTrackArmModeMonStates(track)
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
function rprw_SetTrackArmModeMonStates(track, rec_arm, rec_mode, rec_mon)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", rec_arm)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", rec_mode)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", rec_mon)
    if rprw_HasInstrumentFX(track) and reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT") < 4096 then
        -- if track has an instrument plugin and input is set to audio, set input to "MIDI: All MIDI Inputs and Channels"
        reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 6112)
    end
end

function rprw_HasInstrumentFX(track)
    return reaper.TrackFX_GetInstrument(track) >= 0
end

function rprw_GetMIDIEditorActiveTake()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return false end
    return reaper.MIDIEditor_GetTake(midi_editor)
end

function rprw_GetMIDIEditorActiveTakeItem()
    local take = rprw_GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Item(take)
end

function rprw_GetMIDIEditorActiveTakeTrack()
    local take = rprw_GetMIDIEditorActiveTake()
    if not take then return false end
    return reaper.GetMediaItemTake_Track(take)
end

function rprw_GetMediaItemUnderMouseCursor()
    local item, pos = reaper.BR_ItemAtMouseCursor()
    local take
    if not item then
        local screen_x, screen_y = reaper.GetMousePosition()
        item, take = reaper.GetItemFromPoint(screen_x, screen_y, true)
    end
    return item, pos
end

function rprw_SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    reaper.Main_OnCommand(40034, 0)
end

function rprw_UnselectAllMediaItems()
    reaper.Main_OnCommand(40289, 0)
end

function rprw_DeleteTrack(track)
    local track_folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

    if track_folder_depth < 0 then
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        if track_id > 0 then
            local prev_track = reaper.GetTrack(0, track_id - 2)
            -- if reaper.GetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH") == 1 then
            --     reaper.SetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH", 0)
            -- else
            reaper.SetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH", track_folder_depth + 1)
            -- end
        end
    else
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local num_tracks = reaper.CountTracks(0)

        for i = track_id, num_tracks - 1 do
            local track = reaper.GetTrack(0, i)
            tack_folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
            if track_folder_depth < -1 then
                reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", track_folder_depth + 1)
            elseif track_folder_depth == -1 then
                break
            end
        end
    end
    reaper.DeleteTrack(track)
end
