local class = require "com.class"

---@class UIWidgetSpriteProgress
---@overload fun(parent, sprite, value, smooth, progressBarType):UIWidgetSpriteProgress
local UIWidgetSpriteProgress = class:derive("UIWidgetSpriteProgress")

local Vec2 = require("src.Essentials.Vector2")



function UIWidgetSpriteProgress:new(parent, sprite, value, smooth, progressBarType)
	self.type = "spriteProgress"

	self.parent = parent

	self.sprite = _Game.resourceManager:getSprite(sprite)
	self.size = self.sprite.img.size
	self.value = 0
	self.valueData = value or 0
	self.smooth = smooth
	self.progressBarType = progressBarType or "bar"
end



function UIWidgetSpriteProgress:update(dt)
	local value = self.valueData
	if self.smooth then
		if self.value < value then
			self.value = math.min(self.value * 0.95 + value * 0.0501, value)
		elseif self.value > value then
			self.value = math.max(self.value * 0.95 + value * 0.0501, 0)
		end
	else
		self.value = value
	end
end

function UIWidgetSpriteProgress:draw(variables)
	-- we currently only support two types - circular or bar
	-- if this is neither we assume this is a bar
	-- TODO: Specify start and end arc

	local pos = self.parent:getPos()
	local pos2 = _PosOnScreen(pos)
	
	local p2 = _PosOnScreen(pos + self.size/2)

	if self.progressBarType == "circular" then
		
		love.graphics.stencil(function()
			love.graphics.setColor(1, 1, 1)
			love.graphics.arc("fill", "pie", p2.x, p2.y, self.size.x + 2, -math.pi/2, -math.pi/2 + (math.pi * (self.value * 2)), 50)
		end, "replace", 1)
		-- mark only these pixels as the pixels which can be affected
		love.graphics.setStencilTest("equal", 1)
		-- draw the circle
		self.sprite:draw(self.parent:getPos(), nil, nil, nil, nil, nil, self.parent:getAlpha(), nil, self.parent.blendMode)
		-- reset the mask
		love.graphics.setStencilTest()

	else
		love.graphics.setScissor(pos2.x, pos2.y, self.size.x * _GetResolutionScale() * self.value, self.size.y * _GetResolutionScale())
		self.sprite:draw(pos, nil, nil, nil, nil, nil, self.parent:getAlpha(), nil, self.parent.blendMode)
		love.graphics.setScissor()
	end
end

return UIWidgetSpriteProgress
