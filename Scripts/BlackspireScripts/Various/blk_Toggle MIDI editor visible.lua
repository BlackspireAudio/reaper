-- @description Toggle new recording adds lanes
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
function IsChildFocused(hwnd, fcw)
    local arr = reaper.new_array({}, 1024)
    reaper.JS_Window_ArrayAllChild(hwnd, arr)
    local childs = arr.table()
    for j = 1, #childs do
        if reaper.JS_Window_HandleFromAddress(childs[j]) == fcw then
            return true
        end
    end
end

reaper.PreventUIRefresh(1)

local midi_hwnd = reaper.MIDIEditor_GetActive()
if midi_hwnd then
    if reaper.JS_Window_IsVisible(midi_hwnd) and
        reaper.GetToggleCommandState(40279) == 1 then
        -- Docker is visible -> hide docker
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HIDEDOCK"), 0)
        if reaper.JS_Window_IsVisible(midi_hwnd) then
            -- if midi editor is still visible this means it was not docked -> reshow docker and toggle midi editor visibility
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SHOWDOCK"), 0)
            reaper.Main_OnCommand(40716, 0) -- View: Toggle show MIDI editor windows
        end
    else
        -- if midi editor is not visible, hide docker and toggle midi editor visibility twice: first to the hidden open midi editor and second to reopen it without any auxiliary docker windows
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HIDEDOCK"), 0)
        reaper.Main_OnCommand(40716, 0) -- View: Toggle show MIDI editor windows
        reaper.Main_OnCommand(40716, 0) -- View: Toggle show MIDI editor windows
    end
else
    reaper.Main_OnCommand(40716, 0) -- View: Toggle show MIDI editor windows
    if not reaper.JS_Window_IsVisible(reaper.MIDIEditor_GetActive()) then
        local selected_media_item = reaper.GetSelectedMediaItem(0, 0)
        if selected_media_item and
            reaper.TakeIsMIDI(reaper.GetActiveTake(selected_media_item)) then
            reaper.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor
        else
            local selected_track = reaper.GetSelectedTrack(0, 0)
            if selected_track then
                local media_items = reaper.CountTrackMediaItems(selected_track)
                for i = 0, media_items - 1 do
                    local media_item = reaper.GetTrackMediaItem(selected_track,
                        i)
                    local take = reaper.GetActiveTake(media_item)
                    if reaper.TakeIsMIDI(take) then
                        reaper.SetMediaItemSelected(media_item, true)
                        reaper.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor
                        break
                    end
                end
            else
                local media_items = reaper.CountMediaItems(0)
                for i = 0, media_items - 1 do
                    local media_item = reaper.GetMediaItem(0, i)
                    local take = reaper.GetActiveTake(media_item)
                    if reaper.TakeIsMIDI(take) then
                        reaper.SetMediaItemSelected(media_item, true)
                        reaper.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor
                        break
                    end
                end
            end
        end
    end
end
reaper.PreventUIRefresh(-1)
