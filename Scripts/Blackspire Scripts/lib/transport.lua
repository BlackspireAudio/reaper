-- @description holds transport manipulation functions
-- @author BlackSpire
-- @noindex


---Restart playback or recording
---@param record boolean true to restart recording, false to restart playback
---@param force_pre_roll boolean Default: false, true to force pre-roll on, false to ignore pre-roll state
---@param save_recorded_media int Default: 2, 0 to delete all recorded media, 1 to save all recorded media, 2 to prompt to select which recorded media to save if activated in Preferences -> Media -> Recording
function RestartPlayRecord(record, force_pre_roll, save_recorded_media)
    local force_pre_roll = force_pre_roll or false
    local save_recorded_media = save_recorded_media or 2

    local toggle_pre_roll_action_id = record and 41819 or 41818 -- Toggle playback pre-roll state
    local stop_action_id
    if save_recorded_media == 0 then
        stop_action_id = 40668 -- Transport: Stop (DELETE all recorded media)
    elseif save_recorded_media == 1 then
        stop_action_id = 40667 -- Transport: Stop (save all recorded media)
    else
        stop_action_id = 1016  -- Transport: Stop (prompt to select which recorded media to save if activated in Preferences -> Media -> Recording)
    end

    -- if force_pre_roll is active and pre-roll is off, turn it on before restarting
    local toggle_pre_roll = force_pre_roll and reaper.GetToggleCommandState(toggle_pre_roll_action_id) == 0
    if toggle_pre_roll then
        reaper.Main_OnCommand(toggle_pre_roll_action_id, 0) -- Toggle playback pre-roll state
    end

    reaper.Main_OnCommand(stop_action_id, 0)
    reaper.Main_OnCommand(record and 1013 or 1007, 0) -- Transport: Record

    if toggle_pre_roll then
        -- if pre-roll was forced on, turn it off again
        reaper.Main_OnCommand(toggle_pre_roll_action_id, 0) -- Toggle playback pre-roll state
    end
end
