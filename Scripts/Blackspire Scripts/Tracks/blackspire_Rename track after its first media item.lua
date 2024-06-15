undo_message = 'Rename track after its first media item'




local lib_path = reaper.GetExtState("BlackSpire_Scripts", "lib_path")
if not lib_path or lib_path == "" then
    reaper.MB(
        "Couldn't load the BlackSpire_Scripts library. Please run 'blackspire_Set library path.lua' in the BlackSpire Scripts.",
        "Whoops!", 0)
    return
end
dofile(lib_path .. "core.lua")
if not BSLoadLibraries(1.0, { "helper_functions.lua", "rprw.lua", "tracks_properties.lua" }) then return end



reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()


local track = reaper.GetSelectedTrack(0, 0)
if not track then
    return
else
    local item = reaper.GetTrackMediaItem(track, 0)
    if not item then
        return
    else
        local take = reaper.GetMediaItemTake(item, 0)
        if not take then
            return
        else
            local name = reaper.GetTakeName(take)
            name = string.gsub(name, ".wav", "")
            name = string.gsub(name, "-M", "")
            name = string.gsub(name, "ST", "MT")
            reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
        end
    end
end

reaper.Undo_EndBlock(undo_message, 4)
reaper.PreventUIRefresh(-1)
