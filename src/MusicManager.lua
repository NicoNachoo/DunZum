local MusicManager = {}

MusicManager.tracks = {}
MusicManager.currentTrack = nil

function MusicManager:addTrack(name, path, loop)
    local source = love.audio.newSource(path, 'stream')
    if loop ~= nil then
        source:setLooping(loop)
    else
        source:setLooping(true) -- Default to looping
    end
    self.tracks[name] = source
end

function MusicManager:play(name)
    local track = self.tracks[name]
    
    if not track then
        print("MusicManager: Track '" .. name .. "' not found!")
        return
    end
    
    -- If already playing this track, do nothing
    if self.currentTrack == track and track:isPlaying() then
        return
    end
    
    -- Stop previous track
    self:stop()
    
    -- Play new track
    track:play()
    self.currentTrack = track
end

function MusicManager:stop()
    if self.currentTrack then
        self.currentTrack:stop()
        self.currentTrack = nil
    end
end

MusicManager.MAX_VOLUME_SCALE = 0.3

function MusicManager:setVolume(volume)
    -- Input volume is 0.0 to 1.0 (from UI)
    -- We map this to 0.0 to 0.3 (Real volume)
    love.audio.setVolume(volume * self.MAX_VOLUME_SCALE)
    
    -- Save Logic
    SettingsManager.save({ volume = volume })
end

function MusicManager:getVolume()
    -- Get real volume (0.0 to 0.3)
    -- Map back to UI volume (0.0 to 1.0)
    return love.audio.getVolume() / self.MAX_VOLUME_SCALE
end

-- Initialize from Settings
local settings = SettingsManager.load() or {}
local startVol = settings.volume or 1.0

MusicManager:setVolume(startVol)

return MusicManager
