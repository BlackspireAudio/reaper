local misc = require 'misc'
local utils = require 'utils'

local tm = {} -- tracks module

tm.SWSNoteTrait = {
    FreezeToMono = "freeze_to_mono",
    DisabledOnFreeze = "disabled_on_freeze",
}

---Check if a trait is set on a track by checking for a keyword in the SWS track notes
---@param track MediaTrack track to check the trait on
---@param trait string keyword to check for in the track notes
---@return boolean true if the keyword is found in the track notes
function tm.HasSWSNoteTrait(track, trait)
    local res = reaper.NF_GetSWSTrackNotes(track):find(trait)
    return res and true or false
end

---Toggle a trait on a track by adding or removing a keyword from the SWS track notes
---@param track MediaTrack track to toggle the trait on
---@param trait string keyword to add or remove from the track notes
function tm.ToggleSWSNoteTrait(track, trait)
    tm.SetSWSNoteTrait(track, trait, not tm.HasSWSNoteTrait(track, trait))
end

function tm.UnmuteAllTracks() reaper.Main_OnCommand(40339, 0) end

function tm.UnsoloAllTracks() reaper.Main_OnCommand(40340, 0) end

function tm.SelectTrackUnterMouse() reaper.Main_OnCommand(41110, 0) end

function tm.UnselectAllTracks() reaper.Main_OnCommand(40297, 0) end

function tm.HasInstrumentFX(track)
    return reaper.TrackFX_GetInstrument(track) >= 0
end

---Checks if a track is a folder track
---@param track MediaTrack track to check
---@return boolean retval true if track is a folder track, false otherwise
function tm.IsFolder(track)
    return reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1
end

---Checks if a tracks FX chain is enabled
---@param track MediaTrack track to check
---@return boolean true if FX chain is enabled, false otherwise
function tm.IsFxEnabled(track)
    return reaper.GetMediaTrackInfo_Value(track, 'I_FXEN') == 1
end

---Checks if a track has sends
---@param track MediaTrack track to check
---@param include_hardware_sends? boolean optional true to include hardware sends in the check
---@return boolean retval true if track has sends, false otherwise
function tm.HasSends(track, include_hardware_sends)
    local count = reaper.GetTrackNumSends(track, 0)
    if include_hardware_sends then
        count = count + reaper.GetTrackNumSends(track, 1)
    end
    return count > 0
end

---Check if a track has any FX
---@param track MediaTrack track to check
---@return boolean retval true if track has FX, false otherwise
function tm.HasFx(track)
    return reaper.TrackFX_GetCount(track) > 0
end

---Loops over all tracks and returns true if predicate returns true for any track
---@param predicate function(track: MediaTrack) function specifying the condition to check for each track
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id integer default -2, track id of a single track to ignore (pass value <= -2 to ignore no track)
---@return boolean true if any non-ignored track is muted
function tm.AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
    local ignore_selected = ignore_selected or false
    local ignore_track_id = ignore_track_id or -2
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        if not (i == ignore_track_id                                   -- ignore track with given index, always false if ignore_track_id <= -2 (default -2)
                or (ignore_selected and reaper.IsTrackSelected(track)) -- ignore selected tracks if ignore_selected is true
            ) and predicate(track) then
            return true
        end
    end
    return false
end

---Loops over all tracks and returns true if any track is muted
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id integer default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is muted
function tm.AnyTrackMuted(ignore_selected, ignore_track_id)
    local predicate = function(track)
        local res, muted = reaper.GetTrackUIMute(track)
        return res and muted
    end
    return tm.AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if any track is muted
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id integer default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is soloed
function tm.AnyTrackSoloed(ignore_selected, ignore_track_id)
    local predicate = function(track)
        return reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0
    end
    return tm.AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if any track is armed (record mode "Record disable (input monitoring only)" is not considered armed)
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id integer default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is armed
function tm.AnyTrackArmed(ignore_selected, ignore_track_id)
    local ignore_selected = ignore_selected or false
    local ignore_track_id = ignore_track_id or -2
    local predicate = function(track)
        return reaper.GetMediaTrackInfo_Value(track, "I_RECMODE") ~= 2 and
            reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 1
    end
    return tm.AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Select all tracks in the provided table
---@param tracks table tracks to select
---@param clear_prev_selection? any true to clear previous selection, false to keep previous selection
function tm.SelectTracks(tracks, clear_prev_selection)
    if clear_prev_selection then tm.UnselectAllTracks() end
    for i = 1, #tracks do
        if tracks[i] then reaper.SetTrackSelected(tracks[i], true) end
    end
end

---Get the volume of a track
---@param track MediaTrack track to get volume from
---@param db? boolean optional true to return volume in dB, false to return linear volume
---@return number
function tm.GetVolume(track, db)
    local volume = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
    if db then volume = utils.ToDb(volume) end
    return volume
end

---Set the volume of a track
---@param track MediaTrack track to set volume on
---@param volume number volume to set
---@param db? boolean optional true if volume is in dB, false if volume is linear
function tm.SetVolume(track, volume, db)
    if db then volume = utils.FromDb(volume) end
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", volume)
end

-- @description holds wrapper functions for reaper API functions
-- @author Blackspire
-- @noindex
function tm.GetTrackUnderMouseCursor()
    local x, y = reaper.GetMousePosition()
    local track, info = reaper.GetTrackFromPoint(x, y)
    return track
end

---Get all selected tracks excluding tracks in the exclude_tracks table
---@param exclude_tracks? table table of tracks to exclude from the selection
---@param project? integer optional project index
---@return table selected_tracks table of selected tracks excluding tracks in the exclude_tracks table
function tm.GetSelectedTracks(exclude_tracks, project)
    exclude_tracks = exclude_tracks or {}
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
---@param include_parent? boolean true to include the provided track in the returned table
---@param max_depth? integer optional maximum depth to search for child tracks or 0 for no limit
---@return table child_tracks table of child tracks or empty table if track is not a folder track
function tm.GetChildTracks(track, include_parent, max_depth)
    max_depth = max_depth or 0
    local child_tracks = {}
    if include_parent then child_tracks[#child_tracks + 1] = track end
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        -- child track search always starts at relative depth of 1
        local relative_depth = 1.0
        local track_id = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local num_tracks = reaper.CountTracks(0)
        -- iterate over all tracks after the provided track untill we are back at the same folder depth
        -- note that GetMediaTrackInfo_Value returns 1-indexed track numbers and GetTrack uses 0-indexed track numbers
        for i = track_id, num_tracks - 1 do
            local child_track = reaper.GetTrack(0, i)
            if max_depth == 0 or relative_depth <= max_depth then
                table.insert(child_tracks, child_track)
            end
            local folder_depth = reaper.GetMediaTrackInfo_Value(child_track, "I_FOLDERDEPTH")
            if folder_depth == 1.0 then
                -- if child track is a folder track, increment relative depth
                relative_depth = relative_depth + 1
            elseif folder_depth < 0 then
                -- if child track is last track in a folder, decrement relative depth by folder temination tier
                relative_depth = relative_depth - 1
            end
            if relative_depth <= 0 then
                -- if we are back at the original folder depth, break the loop as we have found all child tracks
                break
            end
        end
    end
    return child_tracks
end

-- @description holds helper functions for track properties manipulation
-- @author Blackspire
-- @noindex
---Get the global index of a track
---@param track MediaTrack
---@return boolean is_found true if track not found, true and track index if found
---@return integer track_id zero-based track index or -1 for master track if found, -2 for invalid track
function tm.GetTrackId(track)
    track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    if track_id > 0 then
        return true, track_id - 1
    elseif track_id == 0 then
        return false, -2 -- if track not found return invalid track id
    else
        return true, track_id
    end
end

---Set Mute state on track
---@param track MediaTrack track to set mute state on
---@param mute boolean true to mute track, false to unmute
---@param group? boolean optional, false to ignore track grouping
function tm.SetTrackUIMute(track, mute, group)
    reaper.SetTrackUIMute(track, utils.BoolInt(mute), group and 0 or 1)
end

---Set Solo state on track
---@param track MediaTrack track to set solo state on
---@param solo boolean true to solo track, false to unsolo
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
---@param group? boolean optional, false to ignore track grouping
function tm.SetTrackUISolo(track, solo, in_place, group)
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

---Get the current record arm, mode and monitor states of a track. Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#GetMediaTrackInfo_Value for infos on the values
---@param track MediaTrack track to get states from
---@return integer rec_arm record arm state
---@return integer rec_mode record mode state
---@return integer rec_mon monitor state
function tm.GetTrackArmModeMonStates(track)
    local rec_arm = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
    local rec_mode = reaper.GetMediaTrackInfo_Value(track, "I_RECMODE")
    local rec_mon = reaper.GetMediaTrackInfo_Value(track, "I_RECMON")
    return rec_arm, rec_mode, rec_mon
end

---Set the record arm, mode and monitor states of a track. Check https://www.reaper.fm/sdk/reascript/reascripthelp.html#SetMediaTrackInfo_Value for infos on the values
---If the track has an instrument plugin and input is set to audio, input will be set to "MIDI: All MIDI Inputs and Channels"
---@param track MediaTrack track to set states on
---@param rec_arm integer record arm state
---@param rec_mode integer record mode state
---@param rec_mon integer monitor state
function tm.SetTrackArmModeMonStates(track, rec_arm, rec_mode, rec_mon)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", rec_arm)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", rec_mode)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", rec_mon)
    if tm.HasInstrumentFX(track) and
        reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT") < 4096 then
        -- if track has an instrument plugin and input is set to audio, set input to "MIDI: All MIDI Inputs and Channels"
        reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 6112)
    end
end

---Toggle Mute on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
function tm.ToggleMuteOnTargetTrack(mouse, select, group, exclusive)
    local track = tm.GetTrackUnderMouseCursor()
    if not mouse or (track and reaper.IsTrackSelected(track)) then -- mute all selected tracks
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            tm.ToggleMuteOnTrack(reaper.GetSelectedTrack(0, i), group,
                i == 0 and exclusive)
        end
    elseif mouse then                                -- mute track under mouse
        if select and track then
            reaper.SetOnlyTrackSelected(track, true) -- select track under mouse
        else
            track = reaper.GetSelectedTrack(0, 0)    -- use selected track if no track under mouse
        end
        tm.ToggleMuteOnTrack(track, group, exclusive)
    end
end

---Toggle Mute on given track based on its current state and additional parameters
---@param track MediaTrack track to toggle mute on
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
function tm.ToggleMuteOnTrack(track, group, exclusive)
    if not track then return end

    local res, muted = reaper.GetTrackUIMute(track)
    if not res then return end

    -- other_traks_muted can only be true if exclusive is true and any other track is muted
    -- in such a case it is used further below to resolo target track after unsoloing all other tracks
    local other_traks_muted = false
    if exclusive then
        other_traks_muted = tm.AnyTrackMuted(reaper.IsTrackSelected(track),
            select(2, tm.GetTrackId(track)))
        if other_traks_muted then tm.UnmuteAllTracks() end
    end

    if muted then
        tm.SetTrackUIMute(track, other_traks_muted, group)
    else
        tm.SetTrackUIMute(track, true, group)
    end
end

---Toggle Solo on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
function tm.ToggleSoloOnTargetTrack(mouse, select, group, exclusive, in_place)
    local track = tm.GetTrackUnderMouseCursor()
    if not mouse or (track and reaper.IsTrackSelected(track)) then -- solo all selected tracks
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            tm.ToggleSoloOnTrack(reaper.GetSelectedTrack(0, i), group,
                i == 0 and exclusive, in_place)
        end
    elseif mouse then                                -- solo track under mouse without changing selection
        if select and track then
            reaper.SetOnlyTrackSelected(track, true) -- select track under mouse
        else
            track = reaper.GetSelectedTrack(0, 0)    -- use selected track if no track under mouse
        end
        tm.ToggleSoloOnTrack(track, group, exclusive, in_place)
    end
end

---Toggle Solo on given track based on its current state and additional parameters
---@param track? MediaTrack track to toggle mute on
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
---@param in_place boolean false to solo not-in-place (ignore routing)
function tm.ToggleSoloOnTrack(track, group, exclusive, in_place)
    if not track then return end
    local solo_state = reaper.GetMediaTrackInfo_Value(track, 'I_SOLO')

    -- other_traks_soloed can only be true if exclusive is true and any other track is soloed
    -- in such a case it is used further below to resolo target track after unsoloing all other tracks
    local other_traks_soloed = false
    if exclusive then
        other_traks_soloed = tm.AnyTrackSoloed(reaper.IsTrackSelected(track),
            select(2, tm.GetTrackId(track)))
        if other_traks_soloed then tm.UnsoloAllTracks() end
    end

    if solo_state == 0 then     -- not soloed
        tm.SetTrackUISolo(track, true, in_place, group)
    elseif solo_state == 1 then -- solo not-in-place
        tm.SetTrackUISolo(track, in_place or other_traks_soloed, in_place,
            group)
    elseif solo_state == 2 then -- solo in-place
        tm.SetTrackUISolo(track, not in_place or other_traks_soloed, in_place,
            group)
    else -- other solo variations
        tm.SetTrackUISolo(track, false, in_place, group)
    end
end

---Toggle solo / mute state recall and reset on a slot in SWS extension
---@param slot_id integer one-indexed slot number from the SWS extension (1-16)
---@param save_on_reset boolean true to always save current state before reset
---@param solo_mute integer 0 to unset solo and mute on reset, 1 to unset solo only, 2 to unset mute only
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
function tm.ToggleSWSSoloMuteSlot(slot_id, save_on_reset, solo_mute, selected)
    if (solo_mute > 1 or tm.AnyTrackSoloed()) and
        (solo_mute == 1 or tm.AnyTrackMuted()) then
        if save_on_reset then
            misc.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, true)
        end

        if solo_mute <= 1 then tm.UnsoloAllTracks() end
        if solo_mute ~= 1 then tm.UnmuteAllTracks() end
    else
        misc.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, false)
    end
end

---Cycle through the record arm, mode and monitor states of the track under the mouse cursor or all selected tracks
---Determines current state of track under mouse or first selected track and attempts to set the next state in the cycle (or first state if current state is not found in the cycle)
---Afterwards propagates the state to all selected tracks of the same type (audio or instrument)
---@param audio_states table table of record arm, mode and monitor states for audio tracks
---@param instrument_states table table of record arm, mode and monitor states for instrument tracks
---@param mouse boolean true to cycle states on track under mouse (or first selected track of non under mouse), false to cycle states on first selected track
function tm.CycleTargetTrackRecMonStates(audio_states, instrument_states, mouse)
    local track = nil
    if mouse then track = tm.GetTrackUnderMouseCursor() end
    if not track then track = reaper.GetSelectedTrack(0, 0) end
    if track then
        local is_instrument_track = tm.HasInstrumentFX(track)
        target_state = tm.CycleTrackRecMonStates(track, is_instrument_track and
            instrument_states or
            audio_states)
        if reaper.IsTrackSelected(track) then
            for i = 0, reaper.CountSelectedTracks(0) - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                if is_instrument_track == tm.HasInstrumentFX(track) then -- only propagate state to tracks of the same type
                    tm.SetTrackArmModeMonStates(reaper.GetSelectedTrack(0, i),
                        target_state.rec_arm,
                        target_state.rec_mode,
                        target_state.rec_mon)
                end
            end
        end
    end
end

---Determine the current record arm, mode and monitor states of a track and attempt to set the next state in the cycle (or first state if current state is not found in the cycle)
---@param track MediaTrack track to cycle states on
---@param cycle_states table table of record arm, mode and monitor states to cycle through
---@return table applied_state record arm, mode and monitor states that were applied (for propagation if multiple tracks are selected)
function tm.CycleTrackRecMonStates(track, cycle_states)
    local rec_arm, rec_mode, rec_mon = tm.GetTrackArmModeMonStates(track)

    for i = 1, #cycle_states do
        if rec_arm == cycle_states[i].rec_arm and rec_mode ==
            cycle_states[i].rec_mode and rec_mon == cycle_states[i].rec_mon then
            local next_state = cycle_states[i % #cycle_states + 1]
            tm.SetTrackArmModeMonStates(track, next_state.rec_arm,
                next_state.rec_mode,
                next_state.rec_mon)
            return next_state
        end
    end
    tm.SetTrackArmModeMonStates(track, cycle_states[1].rec_arm,
        cycle_states[1].rec_mode,
        cycle_states[1].rec_mon)
    return cycle_states[1]
end

---Set a trait on a track by adding or removing a keyword from the SWS track notes
---@param track MediaTrack track to set the trait on
---@param trait string keyword to add or remove from the track notes
---@param active boolean true to add the keyword, false to remove it
function tm.SetSWSNoteTrait(track, trait, active)
    local track_notes = reaper.NF_GetSWSTrackNotes(track)
    local has_trait = tm.HasSWSNoteTrait(track, trait)
    if has_trait and not active then
        if track_notes:find("\n" .. trait) then
            track_notes = track_notes:gsub("\n" .. trait, "")
        else
            track_notes = track_notes:gsub(trait, "")
        end
        reaper.NF_SetSWSTrackNotes(track, track_notes)
    elseif not has_trait and active then
        reaper.NF_SetSWSTrackNotes(track, track_notes .. "\n" .. trait)
    end
end

---Get the dominant enabled status of a list of tracks
---@param tracks table<MediaTrack> list of tracks to check the enabled status on
---@return boolean true if more tracks are enabled than disabled, false if more tracks are disabled than enabled
function tm.GetDominantEnabledStatus(tracks)
    local enabled_count = 0
    local disabled_count = 0
    for i = 1, #tracks do
        local track = tracks[i]
        if tm.IsFxEnabled(track) then
            enabled_count = enabled_count + 1
        else
            disabled_count = disabled_count + 1
        end
    end

    if enabled_count > disabled_count then
        return true
    else
        return false
    end
end

---Set the enabled state of a list of tracks
---@param tracks table<MediaTrack> list of tracks to set the enabled state on
---@param enabled boolean true to enable the tracks, false to disable them
---@param preserve_selection? boolean true to preserve the selection state of the tracks
function tm.SetEnabledState(tracks, enabled, preserve_selection)
    preserve_selection = preserve_selection or false
    local selected_tracks = {}
    if preserve_selection then
        selected_tracks = tm.GetSelectedTracks()
    end

    tm.SelectTracks(tracks, true)
    if enabled then
        reaper.Main_OnCommand(40536, 0) -- Track: Set all FX online for selected tracks
        reaper.Main_OnCommand(41313, 0) -- Track: Unlock track controls
    end
    for i = 1, #tracks do
        reaper.SetMediaTrackInfo_Value(tracks[i], "B_MUTE", utils.BoolInt(not enabled))
        reaper.SetMediaTrackInfo_Value(tracks[i], "I_FXEN", utils.BoolInt(enabled))
    end
    -- must not lock track controls before setting media track info values
    if not enabled then
        reaper.Main_OnCommand(40535, 0) -- Track: Set all FX offline for selected tracks
        reaper.Main_OnCommand(41312, 0) -- Track: Lock track controls
    end

    if preserve_selection then
        tm.SelectTracks(selected_tracks, true)
    end
end

return tm
