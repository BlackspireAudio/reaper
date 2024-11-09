-- @description Toggle new recording adds takes
-- @version 1.0
-- @author BlackSpire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local lane_recording_cmd_id = "_RSd51bbd8a4b8f0a5b009560bfbe461f5299d5c94a"
local undo_message = 'Toggle new recording adds lanes'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------

reaper.Undo_BeginBlock()

local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
if reaper.GetToggleCommandState(41330) == 0 then
    reaper.Main_OnCommand(41330, 0)                  -- Options: New recording splits existing items and adds takes (default)

    if reaper.GetToggleCommandState(43152) == 1 then -- Options: New recording adds lanes (new lanes play exclusively)
        reaper.Main_OnCommand(43153, 0)              -- Options: New recording does not add lanes
    end
    reaper.SetToggleCommandState(sec, cmd, 1)
    reaper.SetToggleCommandState(sec, reaper.NamedCommandLookup(lane_recording_cmd_id), 0)
else
    reaper.Main_OnCommand(41186, 0) -- Options: New recording trims existing items (tape mode)
    reaper.SetToggleCommandState(sec, cmd, 0)
end

reaper.Undo_EndBlock(undo_message, 8) -- 8 = project state change
reaper.RefreshToolbar2(sec, cmd)
