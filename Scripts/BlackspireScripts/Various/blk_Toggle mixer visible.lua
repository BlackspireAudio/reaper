-- @description Toggle mixer visibility
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.PreventUIRefresh(1)
if reaper.GetToggleCommandState(40083) == 1 then                             -- Mixer is docked
    if reaper.GetToggleCommandState(40078) == 1 then                         -- Mixer is visible
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HIDEDOCK"), 0) -- hide docker
    else
        -- show mixer and then hide and reshow docker to ensure that auxiliary docker windows are shown
        reaper.Main_OnCommand(40078, 0)                                      -- View: Toggle mixer visible
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HIDEDOCK"), 0) -- hide docker
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SHOWDOCK"), 0) -- hide docker
    end
else                                                                         -- Mixer is not docked
    reaper.Main_OnCommand(40078, 0)                                          -- View: Toggle mixer visible
end
reaper.PreventUIRefresh(-1)
