local rsw = require 'reascript_wrapper'

local im = {} -- item module


---Split media items based on target, split and selection criterias
---@param target int 0 to split currently selected items, 1 to split item under mouse cursor or selected items if hovering over selection, 2 to split only item under mouse cursor
---@param split int 0 to split at edit cursor, 1 to split at time selection, 2 to split at mouse cursor, 3 to split at mouse cursor ignoring snap
---@param select int 0 retain original selection, 1 select only the left half, 2 select only the right half, 3 select both halves, 4 select shorter half, 5 select longer half, 6 select quieter half, 7 select louder half
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
        split_positions = { reaper.BR_GetClosestGridDivision(rsw.GetPositionUnderMouseCursor()) }
    elseif split == 3 then -- split at mouse cursor ignoring snap
        split_positions = { rsw.GetPositionUnderMouseCursor() }
    end

    if select == 0 then
        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            originally_selected_items[i + 1] = reaper.GetSelectedMediaItem(0, i)
        end
    end

    local item, _ = rsw.GetMediaItemUnderMouseCursor()
    if item then
        if (target == 1 and not reaper.IsMediaItemSelected(item)) or target == 2 then
            rsw.UnselectAllMediaItems()
            reaper.SetMediaItemSelected(item, true)
            add_split_items_to_original_selection = false
        end
    end


    if group then
        rsw.SelectAllItemsInSameGroupsAsCurrentlySelectedItems()
    end

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        items_to_split[i + 1] = reaper.GetSelectedMediaItem(0, i)
        if not has_grouped_items and reaper.GetMediaItemInfo_Value(items_to_split[i + 1], "I_GROUPID") > 0 then
            has_grouped_items = true
        end
    end
    rsw.UnselectAllMediaItems()

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
            rsw.UnselectAllMediaItems()
            for _, item in ipairs(group) do
                reaper.SetMediaItemSelected(item, true)
            end
            rsw.GroupSelectedItems()
        end

        if select > 0 then
            rsw.UnselectAllMediaItems()
            for _, item in ipairs(temp_selection_cache) do
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end

    if select == 0 then
        rsw.UnselectAllMediaItems()
        for _, item in ipairs(originally_selected_items) do
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

---split item at given position and adjust selection of the resulting halves based on the selection criteria
---@param item MediaItem item to split
---@param position double position to split item at
---@param select int 0 retain original selection, 1 select only the left half, 2 select only the right half, 3 select both halves, 4 select shorter half, 5 select longer half, 6 select quieter half, 7 select louder half
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

return im
