local class = require "com.class"

---Represents an actual drawable form of Spheres.
---@class SphereEntity
---@overload fun(pos, color):SphereEntity
local SphereEntity = class:derive("SphereEntity")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

local PowerupTextures = {
	timeball = "images/game/ball_powerup/time.png",
	multiplier = "images/game/ball_powerup/multiplierx.png",
	bombs = "images/game/ball_powerup/bomb.png",
	trishot = "images/game/ball_powerup/cannon.png",
	colornuke = "images/game/ball_powerup/colorbomb.png",
}

---Constructs a new Sphere Entity.
---@param pos Vector2 The initial position of this Sphere Entity.
---@param color integer The initial sphere color.
function SphereEntity:new(pos, color)
	self.pos = pos
	self.angle = 0
	self.scale = Vec2(1)
	self.frame = Vec2(1)
	self.colorM = Color()
	self.color = color
	self.alpha = 1
	self.powerup = nil
	self.powerupTransition = 0

	self.config = _Game.configManager.spheres[color]
	self.config.shadowOffset = _ParseVec2(self.config.shadowOffset) or Vec2(4)

	self.shadowSprite = _Game.resourceManager:getSprite(self.config.shadowSprite or "sprites/game/ball_shadow.json")
	self.shouldRotate = true
	self.particle = self.config.idleParticle and _Game:spawnParticle(self.config.idleParticle, pos)
end



---Gets the current sprite which is dependent on Colorblind Mode.
---@return Sprite
function SphereEntity:getSprite()
	return _Game.resourceManager:getSprite(self.config.sprite)
end



---Sets the current powerup to be displayed on this Sphere Entity.
---DO NOT CALL THIS OUTSIDE `Sphere.lua` - call `Sphere:addPowerup()` instead.
---@param powerup? string The powerup to be displayed, or `nil` if none.
function SphereEntity:setPowerup(powerup)
	self.powerup = powerup
end



---Moves the sphere entity to a given location.
---@param pos Vector2 The new position of this Sphere Entity.
function SphereEntity:setPos(pos)
	self.pos = pos
	if self.particle then
		self.particle.pos = pos
	end
end



---Rotates the sphere entity to a given angle.
---@param angle number The angle in radians.
function SphereEntity:setAngle(angle)
	self.angle = angle
end



---Sets the size of the sphere entity. 1 is natural size.
---@param scale number The new scale.
function SphereEntity:setScale(scale)
	self.scale = Vec2(scale)
end



---Sets the frame of this sphere entity to be displayed.
---@param frame Vector2 The animation frame of this Sphere Entity's sprite.
function SphereEntity:setFrame(frame)
	self.frame = frame
end



---Sets the color modifier of this sphere entity. The color modifier will tint this entity with a given color.
---@param colorM Color The color modifier to be applied.
function SphereEntity:setColorM(colorM)
	self.colorM = colorM
end



---Changes the sphere color of this sphere entity.
---@param color integer The color to be changed to.
function SphereEntity:setColor(color)
	self.color = color
	self.config = _Game.configManager.spheres[color]
	self.config.shadowOffset = _ParseVec2(self.config.shadowOffset) or Vec2(4)
	self.sprite = _Game.resourceManager:getSprite(self.config.sprite)

	-- Particle stuff
	if self.particle then
		self.particle:destroy()
		self.particle = nil
	end
	if self.config.idleParticle then
		self.particle = _Game:spawnParticle(self.config.idleParticle, self.pos)
	end
end



---Sets the alpha of this sphere entity. This does not affect any particles attached to it.
---@param alpha number The transparency of this entity, from `0` (fully invisible) to `1` (fully visible).
function SphereEntity:setAlpha(alpha)
	self.alpha = alpha
end



---Destroys this sphere entity.
---@param spawnParticle boolean? Whether to emit sphere destruction particles. Defaults to `true`.
function SphereEntity:destroy(spawnParticle)
	if spawnParticle == nil then
		spawnParticle = true
	end
	if self.particle then
		self.particle:destroy()
		self.particle = nil
	end
	if spawnParticle and self.config.destroyParticle then
		_Game:spawnParticle(self.config.destroyParticle, self.pos)
	end
end



---Draws this Sphere Entity on the screen.
---@param shadow boolean? If set to `true`, the shadow of this entity will be drawn instead of the sphere itself.
function SphereEntity:draw(shadow)
	if shadow then
		self.shadowSprite:draw(self.pos + self.config.shadowOffset, Vec2(0.5), nil, nil, self.angle, nil, self.alpha, self.scale)
    else
        local multiplierState = nil
		if self.powerup == "multiplier" then
			multiplierState = _Game.session.level.multiplier
		end
		local s = self:getSprite()
		if s.shader then
			s.shader:send('powerup_transition',self.powerup and 1 or 0)
			s.shader:send('icon_transform',
				0,0,
				self.angle,
				1,1,
				0,0
			)
			if self.powerup then
				s.shader:send('powerup_icon',PowerupTextures[self.powerup])
			end
		end
		s:draw(self.pos, Vec2(0.5), nil, self.frame, self.angle, self.colorM, self.alpha, self.scale)
	end
end



return SphereEntity
