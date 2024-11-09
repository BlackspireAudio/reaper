-- @description Count loop iterations while recording. This is an asynchronous script and should either be run with all record start actions or at reaper startup
-- @version 1.0
-- @author BlackSpire
-- @changelog


--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local loop_end_grace_period = 0.2 -- adjust this value to reduce the time required for the first loop to be accepted as complete
local terminate_on_stop = false   -- set to true to stop the script when recording stops

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
local current_playstate = reaper.GetPlayState()
local previous_playstate = reaper.GetPlayState()
local current_play_position = 0
local previous_play_position = 0
function loop()
    if reaper.GetToggleCommandState(1068) == 1 then
        -- if loop repeat is enabled
        current_playstate = reaper.GetPlayState()
        if current_playstate & 4 == 4 then
            -- recording
            current_play_position = reaper.GetPlayPosition()
            if current_play_position < previous_play_position then
                -- if the play position has jumped back during recording, a loop has been completed
                local loop_start, loop_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
                local loop_iteration = tonumber(reaper.GetExtState(0, "blackspire_current_loop_iteration")) or 0
                -- first increment may only occur if the previous play position was close to the loop end to avoid incrementing on record restarts
                if loop_iteration == 0 and previous_play_position >= loop_end - loop_end_grace_period then
                    reaper.SetExtState(0, "blackspire_current_loop_iteration", loop_iteration + 1, false)
                end
            end
            previous_play_position = current_play_position
        elseif previous_playstate & 4 == 4 and current_playstate & 4 == 0 then
            -- only executed once in transition from recording to not recording
            reaper.SetExtState(0, "blackspire_current_loop_iteration", 0, false)
            current_play_position = 0
            previous_play_position = 0
        end
        previous_playstate = current_playstate
    end

    if not terminate_on_stop or current_playstate & 4 == 4 then
        reaper.defer(loop)
    end
end

reaper.defer(loop)
