local class = require "com.class"

---Represents a Sound Event, which can be played by miscellaneous events during the game and from the user interface.
---@class SoundEvent
---@overload fun(path):SoundEvent
local SoundEvent = class:derive("SoundEvent")

local SoundInstance = require("src.Essentials.SoundInstance")



---Constructs a Sound Event. This represents data from a file located in the `sound_events` folder.
---@param path string The path to the `sound_events/*.json` file to load the event from.
function SoundEvent:new(path)
    self.path = path
    local data = _Utils.loadJson(path)

    self.volume = data.volume or 1
    self.pitch = data.volume or 1
    self.loop = data.loop or false
    self.flat = data.flat or false
    self.instanceCount = data.instances or 8

    self.instancePools = {}
    if data.path then
        self.instancePools[1] = {}
        local sound = _Game.resourceManager:getSound(data.path)
        for i = 1, self.instanceCount do
            self.instancePools[1][i] = SoundInstance(love.audio.newSource(sound.data, "static"))
        end
    end
    -- CC Exclusive: Instance pools as a prothesis before making robust sound effects
    if data.paths then
        for i, path in ipairs(data.paths) do
            self.instancePools[i] = {}
            local sound = _Game.resourceManager:getSound(path)
            for j = 1, self.instanceCount do
                self.instancePools[i][j] = SoundInstance(love.audio.newSource(sound.data, "static"))
            end
        end
    end
end



---Updates the Sound Event. This is required so that the sound volume can update according to the game volume.
---@param dt number Time delta in seconds.
function SoundEvent:update(dt)
    for i, instancePool in ipairs(self.instancePools) do
        for j, instance in ipairs(instancePool) do
            instance:update(dt)
        end
    end
end



---Returns the first free instance of this SoundEvent's sound, or `1` if none are available right now (play the first instance).
---Can return `nil` if this SoundEvent has no sound assigned to it.
---@param instancePool table CC EXCLUSIVE: Instance pool that has been randomly picked.
---@return SoundInstance?
function SoundEvent:getFreeInstance(instancePool)
	for i, instance in ipairs(instancePool) do
		if not instance:isPlaying() then
			return instance
		end
	end
    return instancePool[1]
end



---Plays a Sound Event and returns a SoundInstance or itself.
---Returning a SoundInstance allows the caller to change the sound parameters (position) while the sound is playing.
---  - Returns a `SoundInstance` instance if the assigned sound has been correctly played.
---  - Returns itself if this Sound Event does not have any sound assigned to it.
---@param pitch number? The pitch of the sound. Defaults to 1. This is multiplied by the event-defined pitch.
---@param pos Vector2? The position of the sound for sounds which support 3D positioning.
---@return SoundEvent|SoundInstance
function SoundEvent:play(pitch, pos)
    local instance = self:getFreeInstance(self.instancePools[math.random(1, #self.instancePools)])
    if not instance then
        return self
    end
    instance:setVolume(_ParseNumber(self.volume))
    instance:setPitch(_ParseNumber(self.pitch) * (pitch or 1))
    instance:setPos(not self.flat and pos)
    instance:setLoop(self.loop)
    instance:play()
    return instance
end



---Stops all the sound instances assigned to this Sound Event.
function SoundEvent:stop()
    for i, instancePool in ipairs(self.instancePools) do
        for j, instance in ipairs(instancePool) do
            instance:stop()
        end
    end
end



return SoundEvent
