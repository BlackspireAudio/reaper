-- @description Toggle new recording adds lanes
-- @version 1.0
-- @author BlackSpire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local take_recording_cmd_id = "_RSb885f4a5c681db938c6220d431b3f845989f2836"
local undo_message = 'Toggle new recording adds lanes'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------

local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
if reaper.GetToggleCommandState(43152) == 0 then     -- Options: New recording splits existing items and adds takes (default)
    reaper.Main_OnCommand(43152, 0)                  -- Options: New recording splits existing items and adds takes (default)
    reaper.Main_OnCommand(42677, 0)                  -- Options: New recording adds media items in layers

    if reaper.GetToggleCommandState(41330) == 1 then -- Options: New recording splits existing items and adds takes (default)
        reaper.Main_OnCommand(41186, 0)              -- Options: New recording trims existing items (tape mode)
    end
    reaper.SetToggleCommandState(sec, cmd, 1)
    reaper.SetToggleCommandState(sec, reaper.NamedCommandLookup(take_recording_cmd_id), 0)
else
    reaper.Main_OnCommand(43153, 0) -- Options: New recording does not add lanes
    reaper.Main_OnCommand(41186, 0) -- Options: New recording trims existing items (tape mode)
    reaper.SetToggleCommandState(sec, cmd, 0)
end

reaper.Undo_EndBlock(undo_message, 0) -- 0 = mostly native reaper actions are used and command state changes don't seem to add undo points anyway
reaper.RefreshToolbar2(sec, cmd)
