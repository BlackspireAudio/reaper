local misc = require 'misc'
local utils = require 'utils'

local im = {} -- item module

---Get all selected items
---@param project? integer optional project index
---@return table selected_items table of selected items
function im.GetSelectedItems(project)
    project = project or 0
    local selected_items = {}
    for i = 0, reaper.CountSelectedMediaItems(project) do
        table.insert(selected_items, reaper.GetSelectedMediaItem(project, i))
    end
    return selected_items
end

function im.GetItemUnderMouseCursor()
    local item, pos = reaper.BR_ItemAtMouseCursor()
    local take
    if not item then
        local screen_x, screen_y = reaper.GetMousePosition()
        item, take = reaper.GetItemFromPoint(screen_x, screen_y, true)
    end
    return item, pos
end

---Select all items in the provided table
---@param items table items to select
function im.SelectItems(items)
    for i = 1, #items do reaper.SetMediaItemSelected(items[i], true) end
end

function im.GroupSelectedItems() reaper.Main_OnCommand(40032, 0) end

function im.SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    reaper.Main_OnCommand(40034, 0)
end

function im.UnselectAllItems() reaper.Main_OnCommand(40289, 0) end

---Split media items based on target, split and selection criterias
---@param target integer 0 to split currently selected items, 1 to split item under mouse cursor or selected items if hovering over selection, 2 to split only item under mouse cursor
---@param split integer 0 to split at edit cursor, 1 to split at time selection, 2 to split at mouse cursor, 3 to split at mouse cursor ignoring snap
---@param select integer 0 retain original selection, 1 select only the left half, 2 select only the right half, 3 select both halves, 4 select shorter half, 5 select longer half, 6 select quieter half, 7 select louder half
---@param group boolean false to ignore item grouping
function im.SplitTargetMediaItem(target, split, select, group)
    local split_positions = {}
    local items_to_split = {}
    local originally_selected_items = {}
    local split_items = {}
    local add_split_items_to_original_selection = true
    local has_grouped_items = false

    if split == 0 then     -- split at edit cursor
        split_positions = { reaper.GetCursorPosition() }
    elseif split == 1 then -- split at time selection
        local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
        if start_time == end_time then
            split_positions = { start_time }
        else
            split_positions = { start_time, end_time }
        end
    elseif split == 2 then -- split at mouse cursor
        split_positions = { reaper.BR_GetClosestGridDivision(misc.GetPositionUnderMouseCursor()) }
    elseif split == 3 then -- split at mouse cursor ignoring snap
        split_positions = { misc.GetPositionUnderMouseCursor() }
    end

    if select == 0 then
        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            originally_selected_items[i + 1] = reaper.GetSelectedMediaItem(0, i)
        end
    end

    local item, _ = im.GetItemUnderMouseCursor()
    if item then
        if (target == 1 and not reaper.IsMediaItemSelected(item)) or target == 2 then
            im.UnselectAllItems()
            reaper.SetMediaItemSelected(item, true)
            add_split_items_to_original_selection = false
        end
    end


    if group then
        im.SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    end

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        items_to_split[i + 1] = reaper.GetSelectedMediaItem(0, i)
        if not has_grouped_items and reaper.GetMediaItemInfo_Value(items_to_split[i + 1], "I_GROUPID") > 0 then
            has_grouped_items = true
        end
    end
    im.UnselectAllItems()

    for _, item in ipairs(items_to_split) do
        for i, position in ipairs(split_positions) do
            local item_select = select
            if i < #split_positions then
                item_select = 0
            end
            item_r = im.SplitMediaItem(item, position, item_select)
            if item_r then
                table.insert(split_items, item_r)
                if add_split_items_to_original_selection then
                    table.insert(originally_selected_items, item_r)
                end
                item = item_r
            end
        end
    end

    if has_grouped_items then
        local temp_selection_cache = {}
        if select > 0 then
            for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
                temp_selection_cache[i + 1] = reaper.GetSelectedMediaItem(0, i)
            end
        end

        local groups = {}
        for _, item in ipairs(split_items) do
            local group_id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
            if group_id ~= 0 then
                if not groups[group_id] then
                    groups[group_id] = {}
                end
                table.insert(groups[group_id], item)
            end
        end
        for _, group in pairs(groups) do
            im.UnselectAllItems()
            for _, item in ipairs(group) do
                reaper.SetMediaItemSelected(item, true)
            end
            im.GroupSelectedItems()
        end

        if select > 0 then
            im.UnselectAllItems()
            for _, item in ipairs(temp_selection_cache) do
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end

    if select == 0 then
        im.UnselectAllItems()
        for _, item in ipairs(originally_selected_items) do
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

---split item at given position and adjust selection of the resulting halves based on the selection criteria
---@param item MediaItem item to split
---@param position number position to split item at
---@param select integer 0 retain original selection, 1 select only the left half, 2 select only the right half, 3 select both halves, 4 select shorter half, 5 select longer half, 6 select quieter half, 7 select louder half
function im.SplitMediaItem(item, position, select)
    local item_l = item
    local item_r = reaper.SplitMediaItem(item, position)
    if not item_r then
        return nil
    end
    if 1 <= select and select <= 3 then
        reaper.SetMediaItemSelected(item_l, select == 1 or select == 3)
        reaper.SetMediaItemSelected(item_r, select == 2 or select == 3)
    elseif 4 <= select and select <= 7 then
        local item_l_val
        local item_r_val
        if 4 <= select and select <= 5 then
            item_l_val = reaper.GetMediaItemInfo_Value(item_l, "D_LENGTH")
            item_r_val = reaper.GetMediaItemInfo_Value(item_r, "D_LENGTH")
        else
            item_l_val = reaper.NF_GetMediaItemAverageRMS(item_l)
            item_r_val = reaper.NF_GetMediaItemAverageRMS(item_r)
        end
        -- reaper.MB(select .. " " .. item_l_val .. " " .. item_r_val, "Values", 0)
        local select_left
        if select % 2 == 0 then
            select_left = item_l_val <= item_r_val
        else
            select_left = item_l_val > item_r_val
        end
        reaper.SetMediaItemSelected(item_l, select_left)
        reaper.SetMediaItemSelected(item_r, not select_left)
    end
    return item_r
end

---Returns the start position of the item in seconds
---@param item MediaItem item to get the start position of
---@param snap_offset? boolean if true, the returned position will be snapped to the grid
---@return number start position of the item in seconds
function im.GetStartPosition(item, snap_offset)
    snap_offset = snap_offset or false
    local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    if snap_offset then
        start_pos = reaper.BR_GetClosestGridDivision(start_pos)
    end
    return start_pos
end

---Sets the take playback behavior of the item
---@param items table<MediaItem> items to set the playback behavior of
---@param active boolean true to enable playback of all takes, false to restrict playback to the active take
function im.SetAllTakesPlay(items, active)
    for _, item in ipairs(items) do
        reaper.SetMediaItemInfo_Value(item, "B_ALLTAKESPLAY", utils.BoolInt(active))
    end
end

---Resets the take properties of the items to default values and deactivates the AllTakesPlay flag
---@param items table<MediaItem> items to reset the take properties of
---@param volume boolean true to reset the volume of all takes to 0dB
---@param pan boolean true to reset the pan of all takes to 0
function im.ClearTakeProperties(items, volume, pan)
    for _, item in ipairs(items) do
        reaper.SetMediaItemInfo_Value(item, "B_ALLTAKESPLAY", 0)
        for i = 0, reaper.CountTakes(item) - 1 do
            local take = reaper.GetMediaItemTake(item, i)
            if volume then
                reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", 1)
            end
            if pan then
                reaper.SetMediaItemTakeInfo_Value(take, "D_PAN", 0)
            end
        end
    end
end

---Set the active take of the item to stereo playback
---@param item MediaItem item to set the playback behavior of
---@param toggle boolean true to toggle between stereo playback and default playback if selected takes are already set to stereo playback
---@param is_right boolean true to select active as right channel and previous take as left channel, false to select active as left channel and next take as right channel
function im.SetActiveTakeToStereoPlayback(item, toggle, is_right)
    local left, right
    local active_take = reaper.GetActiveTake(item)
    local active_take_id = reaper.GetMediaItemTakeInfo_Value(active_take, "IP_TAKENUMBER")
    local take_count = reaper.CountTakes(item)
    if is_right then
        local left_take_id
        if active_take_id == 0 then
            left_take_id = take_count - 1
        else
            left_take_id = active_take_id - 1
        end
        left = reaper.GetMediaItemTake(item, left_take_id)
        right = active_take
    else
        left = active_take
        right = reaper.GetMediaItemTake(item, (active_take_id + 1) % take_count)
    end
    im.SetTakesToStereoPlayback(item, left, right, toggle)
end

---Modifies item and take properties to play only the selected takes in stereo
---@param item MediaItem item to set the playback behavior of
---@param left MediaItem_Take take to pan left
---@param right MediaItem_Take take to pan right
---@param toggle? boolean true to toggle between stereo playback and default playback if selected takes are already set to stereo playback
function im.SetTakesToStereoPlayback(item, left, right, toggle)
    if toggle and reaper.GetMediaItemTakeInfo_Value(left, "D_PAN") == -1 and reaper.GetMediaItemTakeInfo_Value(right, "D_PAN") == 1 then
        im.ClearTakeProperties({ item }, true, true)
    else
        for i = 0, reaper.CountTakes(item) - 1 do
            reaper.SetMediaItemTakeInfo_Value(reaper.GetMediaItemTake(item, i), "D_VOL", 0)
            reaper.SetMediaItemTakeInfo_Value(reaper.GetMediaItemTake(item, i), "D_PAN", 0)
        end

        reaper.SetMediaItemInfo_Value(item, "B_ALLTAKESPLAY", 1)
        reaper.SetMediaItemTakeInfo_Value(left, "D_VOL", 1)
        reaper.SetMediaItemTakeInfo_Value(left, "D_PAN", -1)
        reaper.SetMediaItemTakeInfo_Value(right, "D_VOL", 1)
        reaper.SetMediaItemTakeInfo_Value(right, "D_PAN", 1)
    end
    reaper.UpdateItemInProject(item)
end

---Returns the minimum number of takes in the selected items
---@param items table<MediaItem> items to get the minimum number of takes from
---@return integer minimum number of takes in the items
function im.GetMinTakesCount(items)
    local min_takes = 1000
    for _, item in ipairs(items) do
        local takes = reaper.CountTakes(item)
        if takes < min_takes then
            min_takes = takes
        end
    end
    return min_takes
end

---Set the locked state of the items
---@param items table<MediaItem> items to set the locked state of
---@param toggle boolean true to toggle the locked state based on the majority state of the items, false to set the locked state to the given state
---@param state? boolean state to set the locked state to if toggle is false
function im.SetLockedState(items, toggle, state)
    if toggle then
        local locked_count = 0
        local unlocked_count = 0
        for _, item in ipairs(items) do
            if reaper.GetMediaItemInfo_Value(item, "C_LOCK") == 1 then
                locked_count = locked_count + 1
            else
                unlocked_count = unlocked_count + 1
            end
        end
        state = unlocked_count > locked_count
    end
    for _, item in ipairs(items) do
        reaper.SetMediaItemInfo_Value(item, "C_LOCK", utils.BoolInt(state))
    end
end

return im
