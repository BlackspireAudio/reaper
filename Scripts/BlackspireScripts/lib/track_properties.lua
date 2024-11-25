-- @description holds helper functions for track properties manipulation
-- @author Blackspire
-- @noindex
---Get the global index of a track
---@param track MediaTrack
---@return boolean is_found true if track not found, true and track index if found
---@return int track_id zero-based track index or -1 for master track if found, -2 for invalid track
function GetTrackId(track)
    track_id = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    if track_id > 0 then
        return true, track_id - 1
    elseif track_id == 0 then
        return false, -2 -- if track not found return invalid track id
    else
        return true, track_id
    end
end

---Toggle Mute on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
function ToggleMuteOnTargetTrack(mouse, select, group, exclusive)
    local track = rprw_GetTrackUnderMouseCursor(0, 0)
    if not mouse or (track and reaper.IsTrackSelected(track)) then -- mute all selected tracks
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            ToggleMuteOnTrack(reaper.GetSelectedTrack(0, i), group,
                              i == 0 and exclusive)
        end
    elseif mouse then -- mute track under mouse
        if select and track then
            reaper.SetOnlyTrackSelected(track, true) -- select track under mouse
        else
            track = reaper.GetSelectedTrack(0, 0) -- use selected track if no track under mouse
        end
        ToggleMuteOnTrack(track, group, exclusive)
    end
end

---Toggle Mute on given track based on its current state and additional parameters
---@param track MediaTrack track to toggle mute on
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
function ToggleMuteOnTrack(track, group, exclusive)
    if not track then return end

    local res, muted = reaper.GetTrackUIMute(track)
    if not res then return end

    -- other_traks_muted can only be true if exclusive is true and any other track is muted
    -- in such a case it is used further below to resolo target track after unsoloing all other tracks
    local other_traks_muted = false
    if exclusive then
        other_traks_muted = AnyTrackMuted(reaper.IsTrackSelected(track),
                                          select(2, GetTrackId(track)))
        if other_traks_muted then rprw_UnmuteAllTracks() end
    end

    if muted then
        rprw_SetTrackUIMute(track, other_traks_muted, group)
    else
        rprw_SetTrackUIMute(track, true, group)
    end
end

---Toggle Solo on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
function ToggleSoloOnTargetTrack(mouse, select, group, exclusive, in_place)
    local track = rprw_GetTrackUnderMouseCursor(0, 0)
    if not mouse or (track and reaper.IsTrackSelected(track)) then -- solo all selected tracks
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            ToggleSoloOnTrack(reaper.GetSelectedTrack(0, i), group,
                              i == 0 and exclusive, in_place)
        end
    elseif mouse then -- solo track under mouse without changing selection
        if select and track then
            reaper.SetOnlyTrackSelected(track, true) -- select track under mouse
        else
            track = reaper.GetSelectedTrack(0, 0) -- use selected track if no track under mouse
        end
        ToggleSoloOnTrack(track, group, exclusive, in_place)
    end
end

---Toggle Solo on given track based on its current state and additional parameters
---@param track MediaTrack track to toggle mute on
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
---@param in_place boolean false to solo not-in-place (ignore routing)
function ToggleSoloOnTrack(track, group, exclusive, in_place)
    if not track then return end
    local solo_state = reaper.GetMediaTrackInfo_Value(track, 'I_SOLO')

    -- other_traks_soloed can only be true if exclusive is true and any other track is soloed
    -- in such a case it is used further below to resolo target track after unsoloing all other tracks
    local other_traks_soloed = false
    if exclusive then
        other_traks_soloed = AnyTrackSoloed(reaper.IsTrackSelected(track),
                                            select(2, GetTrackId(track)))
        if other_traks_soloed then rprw_UnsoloAllTracks() end
    end

    if solo_state == 0 then -- not soloed
        rprw_SetTrackUISolo(track, true, in_place, group)
    elseif solo_state == 1 then -- solo not-in-place
        rprw_SetTrackUISolo(track, in_place or other_traks_soloed, in_place,
                            group)
    elseif solo_state == 2 then -- solo in-place
        rprw_SetTrackUISolo(track, not in_place or other_traks_soloed, in_place,
                            group)
    else -- other solo variations
        rprw_SetTrackUISolo(track, false, in_place, group)
    end
end

---Toggle solo / mute state recall and reset on a slot in SWS extension
---@param slot_id int one-indexed slot number from the SWS extension (1-16)
---@param save_on_reset boolean true to always save current state before reset
---@param solo_mute int 0 to unset solo and mute on reset, 1 to unset solo only, 2 to unset mute only
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
function ToggleSWSSoloMuteSlot(slot_id, save_on_reset, solo_mute, selected)
    if (solo_mute > 1 or AnyTrackSoloed()) and
        (solo_mute == 1 or AnyTrackMuted()) then
        if save_on_reset then
            rprw_StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, true)
        end

        if solo_mute <= 1 then rprw_UnsoloAllTracks() end
        if solo_mute ~= 1 then rprw_UnmuteAllTracks() end
    else
        rprw_StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, false)
    end
end

---Loops over all tracks and returns true if any track is muted
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is muted
function AnyTrackMuted(ignore_selected, ignore_track_id)
    local predicate = function(track)
        local res, muted = reaper.GetTrackUIMute(track)
        return res and muted
    end
    return AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if any track is muted
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is soloed
function AnyTrackSoloed(ignore_selected, ignore_track_id)
    local predicate = function(track)
        return reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0
    end
    return AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if any track is armed (record mode "Record disable (input monitoring only)" is not considered armed)
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is armed
function AnyTrackArmed(ignore_selected, ignore_track_id)
    local ignore_selected = ignore_selected or false
    local ignore_track_id = ignore_track_id or -2
    local predicate = function(track)
        return reaper.GetMediaTrackInfo_Value(track, "I_RECMODE") ~= 2 and
                   reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 1
    end
    return AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if predicate returns true for any track
---@param predicate function(track: MediaTrack) function specifying the condition to check for each track
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value <= -2 to ignore no track)
---@return boolean true if any non-ignored track is muted
function AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
    local ignore_selected = ignore_selected or false
    local ignore_track_id = ignore_track_id or -2
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        if not (i == ignore_track_id -- ignore track with given index, always false if ignore_track_id <= -2 (default -2)
        or (ignore_selected and reaper.IsTrackSelected(track)) -- ignore selected tracks if ignore_selected is true
        ) and predicate(track) then return true end
    end
    return false
end

---Cycle through the record arm, mode and monitor states of the track under the mouse cursor or all selected tracks
---Determines current state of track under mouse or first selected track and attempts to set the next state in the cycle (or first state if current state is not found in the cycle)
---Afterwards propagates the state to all selected tracks of the same type (audio or instrument)
---@param audio_states table table of record arm, mode and monitor states for audio tracks
---@param instrument_states table table of record arm, mode and monitor states for instrument tracks
---@param mouse boolean true to cycle states on track under mouse (or first selected track of non under mouse), false to cycle states on first selected track
function CycleTargetTrackRecMonStates(audio_states, instrument_states, mouse)
    local track = nil
    if mouse then track = rprw_GetTrackUnderMouseCursor() end
    if not track then track = reaper.GetSelectedTrack(0, 0) end
    if track then
        local is_instrument_track = rprw_HasInstrumentFX(track)
        target_state = CycleTrackRecMonStates(track, is_instrument_track and
                                                  instrument_states or
                                                  audio_states)
        if reaper.IsTrackSelected(track) then
            for i = 0, reaper.CountSelectedTracks(0) - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                if is_instrument_track == rprw_HasInstrumentFX(track) then -- only propagate state to tracks of the same type
                    rprw_SetTrackArmModeMonStates(reaper.GetSelectedTrack(0, i),
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
function CycleTrackRecMonStates(track, cycle_states)
    local rec_arm, rec_mode, rec_mon = rprw_GetTrackArmModeMonStates(track)

    for i = 1, #cycle_states do
        if rec_arm == cycle_states[i].rec_arm and rec_mode ==
            cycle_states[i].rec_mode and rec_mon == cycle_states[i].rec_mon then
            local next_state = cycle_states[i % #cycle_states + 1]
            rprw_SetTrackArmModeMonStates(track, next_state.rec_arm,
                                          next_state.rec_mode,
                                          next_state.rec_mon)
            return next_state
        end
    end
    rprw_SetTrackArmModeMonStates(track, cycle_states[1].rec_arm,
                                  cycle_states[1].rec_mode,
                                  cycle_states[1].rec_mon)
    return cycle_states[1]
end
