local midi = {}

---Get the active take in the active MIDI editor
---@return MediaItem_Take? take The active take or false if no take is found
function midi.GetActiveTake()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return nil end
    return reaper.MIDIEditor_GetTake(midi_editor)
end

---Get the media item of the active take in the active MIDI editor
---@return MediaItem? item The media item of the active take or false if no take is found
function midi.GetActiveTakeItem()
    local take = midi.GetActiveTake()
    if not take then return nil end
    return reaper.GetMediaItemTake_Item(take)
end

---Get the track of the active take in the active MIDI editor
---@return MediaTrack? track The track of the active take or false if no take is found
function midi.GetActiveTakeTrack()
    local take = midi.GetActiveTake()
    if not take then return nil end
    return reaper.GetMediaItemTake_Track(take)
end

return midi
