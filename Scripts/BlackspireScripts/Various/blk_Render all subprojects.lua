-- @description Render all subprojects
-- @version 1.0
-- @author Blackspire
--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ALL_ITEMS_PIP"), 0) -- SWS/BR: Select all subproject (PiP) items

local subprojects = {}
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    subprojects[i + 1] = reaper.GetSelectedMediaItem(0, i)
end

for i = 0, #subprojects - 1 do
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(subprojects[i + 1], true)
    reaper.Main_OnCommand(41816, 0) -- Item: Open associated project in new tab
    reaper.Main_OnCommand(42332, 1) -- File: Save project and render RPP-PROX
    reaper.Main_OnCommand(40860, 1) -- Close current project tab
end
