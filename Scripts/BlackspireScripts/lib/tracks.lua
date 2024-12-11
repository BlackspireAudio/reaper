local rsw = require 'reascript_wrapper'
local utils = require 'utils'

local tm = {} -- tracks module

-- @description holds helper functions for track properties manipulation
-- @author Blackspire
-- @noindex
---Get the global index of a track
---@param track MediaTrack
---@return boolean is_found true if track not found, true and track index if found
---@return int track_id zero-based track index or -1 for master track if found, -2 for invalid track
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

---Toggle Mute on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
function tm.ToggleMuteOnTargetTrack(mouse, select, group, exclusive)
    local track = rsw.GetTrackUnderMouseCursor(0, 0)
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
        if other_traks_muted then rsw.UnmuteAllTracks() end
    end

    if muted then
        rsw.SetTrackUIMute(track, other_traks_muted, group)
    else
        rsw.SetTrackUIMute(track, true, group)
    end
end

---Toggle Solo on a track under mouse cursor or all selected tracks, based on additional parameters
---@param mouse boolean true to mute track under mouse, false to mute all selected tracks
---@param select boolean true to select track under mouse
---@param group boolean false to ignore track grouping
---@param exclusive boolean true to unmute all other tracks
---@param in_place boolean true to solo in-place (respect routing), false to solo not-in-place (ignore routing)
function tm.ToggleSoloOnTargetTrack(mouse, select, group, exclusive, in_place)
    local track = rsw.GetTrackUnderMouseCursor(0, 0)
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
---@param track MediaTrack track to toggle mute on
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
        if other_traks_soloed then rsw.UnsoloAllTracks() end
    end

    if solo_state == 0 then     -- not soloed
        rsw.SetTrackUISolo(track, true, in_place, group)
    elseif solo_state == 1 then -- solo not-in-place
        rsw.SetTrackUISolo(track, in_place or other_traks_soloed, in_place,
            group)
    elseif solo_state == 2 then -- solo in-place
        rsw.SetTrackUISolo(track, not in_place or other_traks_soloed, in_place,
            group)
    else -- other solo variations
        rsw.SetTrackUISolo(track, false, in_place, group)
    end
end

---Toggle solo / mute state recall and reset on a slot in SWS extension
---@param slot_id int one-indexed slot number from the SWS extension (1-16)
---@param save_on_reset boolean true to always save current state before reset
---@param solo_mute int 0 to unset solo and mute on reset, 1 to unset solo only, 2 to unset mute only
---@param selected boolean true to save/restore only selected tracks, false to save/restore all tracks
function tm.ToggleSWSSoloMuteSlot(slot_id, save_on_reset, solo_mute, selected)
    if (solo_mute > 1 or tm.AnyTrackSoloed()) and
        (solo_mute == 1 or tm.AnyTrackMuted()) then
        if save_on_reset then
            rsw.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, true)
        end

        if solo_mute <= 1 then rsw.UnsoloAllTracks() end
        if solo_mute ~= 1 then rsw.UnmuteAllTracks() end
    else
        rsw.StoreRecallSWSSoloMuteSlot(slot_id, solo_mute, selected, false)
    end
end

---Loops over all tracks and returns true if any track is muted
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
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
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
---@return boolean true if any non-ignored track is soloed
function tm.AnyTrackSoloed(ignore_selected, ignore_track_id)
    local predicate = function(track)
        return reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0
    end
    return tm.AnyTrackPredicate(predicate, ignore_selected, ignore_track_id)
end

---Loops over all tracks and returns true if any track is armed (record mode "Record disable (input monitoring only)" is not considered armed)
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value < -1 to ignore no track)
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

---Loops over all tracks and returns true if predicate returns true for any track
---@param predicate function(track: MediaTrack) function specifying the condition to check for each track
---@param ignore_selected boolean default false, true to ignore selected tracks
---@param ignore_track_id int default -2, track id of a single track to ignore (pass value <= -2 to ignore no track)
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

---Cycle through the record arm, mode and monitor states of the track under the mouse cursor or all selected tracks
---Determines current state of track under mouse or first selected track and attempts to set the next state in the cycle (or first state if current state is not found in the cycle)
---Afterwards propagates the state to all selected tracks of the same type (audio or instrument)
---@param audio_states table table of record arm, mode and monitor states for audio tracks
---@param instrument_states table table of record arm, mode and monitor states for instrument tracks
---@param mouse boolean true to cycle states on track under mouse (or first selected track of non under mouse), false to cycle states on first selected track
function tm.CycleTargetTrackRecMonStates(audio_states, instrument_states, mouse)
    local track = nil
    if mouse then track = rsw.GetTrackUnderMouseCursor() end
    if not track then track = reaper.GetSelectedTrack(0, 0) end
    if track then
        local is_instrument_track = rsw.HasInstrumentFX(track)
        target_state = tm.CycleTrackRecMonStates(track, is_instrument_track and
            instrument_states or
            audio_states)
        if reaper.IsTrackSelected(track) then
            for i = 0, reaper.CountSelectedTracks(0) - 1 do
                local track = reaper.GetSelectedTrack(0, i)
                if is_instrument_track == rsw.HasInstrumentFX(track) then -- only propagate state to tracks of the same type
                    rsw.SetTrackArmModeMonStates(reaper.GetSelectedTrack(0, i),
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
    local rec_arm, rec_mode, rec_mon = rsw.GetTrackArmModeMonStates(track)

    for i = 1, #cycle_states do
        if rec_arm == cycle_states[i].rec_arm and rec_mode ==
            cycle_states[i].rec_mode and rec_mon == cycle_states[i].rec_mon then
            local next_state = cycle_states[i % #cycle_states + 1]
            rsw.SetTrackArmModeMonStates(track, next_state.rec_arm,
                next_state.rec_mode,
                next_state.rec_mon)
            return next_state
        end
    end
    rsw.SetTrackArmModeMonStates(track, cycle_states[1].rec_arm,
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

function tm.IsEnabled(track)
    return reaper.GetMediaTrackInfo_Value(track, 'I_FXEN') == 1
end

function tm.IsFolder(track)
    return reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') ~= 0
end

---Get the dominant enabled status of a list of tracks
---@param tracks table<MediaTrack> list of tracks to check the enabled status on
---@return boolean true if more tracks are enabled than disabled, false if more tracks are disabled than enabled
function tm.GetDominantEnabledStatus(tracks)
    local enabled_count = 0
    local disabled_count = 0
    for i = 1, #tracks do
        local track = tracks[i]
        if tm.IsEnabled(track) then
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
        selected_tracks = rsw.GetSelectedTracks()
    end

    rsw.SelectTracks(tracks, true)
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
        rsw.SelectTracks(selected_tracks, true)
    end
end

tm.SWSNoteTrait = {
    FreezeToMono = "freeze_to_mono",
    DisabledOnFreeze = "disabled_on_freeze",
}

return tm
