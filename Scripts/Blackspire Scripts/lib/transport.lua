-- @description holds transport manipulation functions
-- @author BlackSpire
-- @noindex

---Restart playback or recording
---There is a bug, that if the restart occurs right at the end of the first loop, the recorded data is deleted but the media item is still added to the timeline where it shows as offline
---Based on my tests this an issue with reaper as the same bug can be reproduced with native record and stop actions
---@param record boolean true to restart recording, false to restart playback
---@param force_pre_roll boolean Default: false, true to force pre-roll on, false to ignore pre-roll state
---@param save_recorded_media int Default: 2, 0 to delete all recorded media, 1 to save all recorded media, 2 to prompt to select which recorded media to save if activated in Preferences -> Media -> Recording
function RestartPlayRecord(record, force_pre_roll, save_recorded_media, loop_end_grace_period)
    local force_pre_roll        = force_pre_roll or false
    local save_recorded_media   = save_recorded_media or 2

    local loop_end_grace_period = loop_end_grace_period or 0.1 -- todo add grace period param to script generator
    local loop_start, loop_end  = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local play_position         = reaper.GetPlayPosition()
    local loop_end_diff         = loop_end - play_position
    local loop_start_diff       = play_position - loop_start
    if (loop_end_diff >= 0 and loop_end_diff <= loop_end_grace_period) or (loop_start_diff >= 0 and loop_start_diff <= loop_end_grace_period) then
        save_recorded_media = 1
    end

    local loop_iteration_ext_state_key      = "current_loop_iteration"
    local recording_restarted_ext_state_key = "recording_restarted"
    local current_loop_iteration            = 0
    if rprw_HasTransportExtState(loop_iteration_ext_state_key) and tonumber(rprw_GetTransportExtState(loop_iteration_ext_state_key)) >= 1 then
        save_recorded_media = 1
    end

    local toggle_pre_roll_action_id = record and 41819 or 41818 -- Toggle playback pre-roll state
    local stop_action_id

    if save_recorded_media == 1 then
        stop_action_id = 40667 -- Transport: Stop (save all recorded media)
        reaper.ShowConsoleMsg("save all recorded media\n")
    elseif save_recorded_media == 0 then
        stop_action_id = 40668 -- Transport: Stop (DELETE all recorded media)
        reaper.ShowConsoleMsg("delete all recorded media\n")
    else
        stop_action_id = 1016 -- Transport: Stop (prompt to select which recorded media to save if activated in Preferences -> Media -> Recording)
        reaper.ShowConsoleMsg(
            "prompt to select which recorded media to save if activated in Preferences -> Media -> Recording\n")
    end



    -- if force_pre_roll is active and pre-roll is off, turn it on before restarting
    local toggle_pre_roll = force_pre_roll and reaper.GetToggleCommandState(toggle_pre_roll_action_id) == 0
    if toggle_pre_roll then
        reaper.Main_OnCommand(toggle_pre_roll_action_id, 0) -- Toggle playback pre-roll state
    end

    if rprw_HasTransportExtState(recording_restarted_ext_state_key) then
        -- if loop iteration moniroting is active, signal that the recording has been restarted and this playposition reset should not count as a loop
        rprw_SetTransportExtState(recording_restarted_ext_state_key, "true")
    end

    reaper.Main_OnCommand(stop_action_id, 0)
    reaper.Main_OnCommand(record and 1013 or 1007, 0) -- Transport: Record

    if toggle_pre_roll then
        -- if pre-roll was forced on, turn it off again
        reaper.Main_OnCommand(toggle_pre_roll_action_id, 0) -- Toggle playback pre-roll state
    end
end
