local class = require "com.class"

---@class Target
---@overload fun(spritePath, pos, isFreeSpin):Target
local Target = class:derive("Target")

local Vec2 = require("src.Essentials.Vector2")



---Initialize a new Target.
---@param spritePath string
---@param pos Vector2
---@param isFreeSpin boolean
function Target:new(spritePath, pos, isFreeSpin)
    self.sprite = _Game.resourceManager:getSprite(spritePath)
    self.pos = pos
    self.frame = Vec2(1)
    self.isFreeSpin = isFreeSpin -- not used atm
    self.delQueue = false

    self.duration = _Game.session.level:getParameter("fruitLifetime")
end



---Updates this target.
---@param dt number Delta time in seconds.
function Target:update(dt)
    if _Game:levelExists() and _Game.session.level.target then
        self.duration = self.duration - dt
        if self.duration < 0 then
            self:destroy()
            _Game:playSound("sound_events/target_despawn.json")
        end
    end
end



---Draws this Target.
function Target:draw()
    -- line that draws the glow goes here, probably a particle
    self.sprite:draw(self.pos, Vec2(0.5))
end



function Target:onShot()
    self:destroy()
    _Game:playSound("sound_events/target_hit.json")
    local fruitRoundingValue = math.max(math.floor(_Game.session.level:getParameter("fruitRoundingValue")), 1)
    local fruitScoreRounded = _MathRoundUp(_Game.session.level.targetHitScore, fruitRoundingValue)
    _Game.session.level:grantScore(fruitScoreRounded)

    local bonusTime = _Game.session.level:getParameter("fruitTicksAdded")
    _Game.session.level:applyEffect({type = "addTime", amount = bonusTime})

    _Game.session.level:spawnFloatingText(
        string.format("BONUS\n+%s", _NumStr(fruitScoreRounded * _Game.session.level.multiplier)),
        self.pos,
        "fonts/score0.json"
    )

    -- increment stats
    _Game.session.level.fruitScore = _Game.session.level.fruitScore + (_Game.session.level.targetHitScore * _Game.session.level.multiplier)

    local incrementAmount = _Game.session.level:getParameter("hotFrogFruitInc") / _Game.session.level:getParameter("hotFrogGoal")
    incrementAmount = math.min(math.max(incrementAmount, 0), 1)
    _Game.session.level:incrementBlitzMeter(incrementAmount, true)

    _Game.session.level.targets = _Game.session.level.targets + 1
    _Game.session.level.fruitCollected = _Game.session.level.fruitCollected + 1

    -- apply that multiplier effect with cap and rounding
    local fruitPointsMultiplier = 1 + _Game.session.level:getParameter("fruitFactor")
    local fruitCap = math.floor(_Game.session.level:getParameter("fruitCap"))

    if _Game.session.level.fruitCollected <= fruitCap then
        _Game.session.level.targetHitScore = _Game.session.level.targetHitScore * fruitPointsMultiplier
    end
end



function Target:destroy()
    if self.delQueue then
		return
	end
	self.delQueue = true
end



function Target:serialize()
    local t = {
        pos = self.pos,
        isFreeSpin = self.isFreeSpin,
        delQueue = self.delQueue,
        duration = self.duration
    }
    return t
end



function Target:deserialize(t)
    self.sprite = t.sprite
    self.pos = t.pos
    self.isFreeSpin = t.isFreeSpin
    self.delQueue = t.delQueue
    self.duration = t.duration
end



return Target