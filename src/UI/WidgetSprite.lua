local class = require "com.class"

---@class UIWidgetSprite
---@overload fun(parent, sprite):UIWidgetSprite
local UIWidgetSprite = class:derive("UIWidgetSprite")



function UIWidgetSprite:new(parent, sprite)
	self.type = "sprite"

	self.parent = parent

	self.sprite = _Game.resourceManager:getSprite(sprite)
end



function UIWidgetSprite:draw()
	self.sprite:draw(self.parent:getPos(), self.parent.align / self.sprite.size, nil, nil, self.parent.angle, nil, self.parent:getAlpha(), nil, self.parent.blendMode)
end


function UIWidgetSprite:wheelmoved(y)
	self.parent:setScrollPosRelative(y)
end

return UIWidgetSprite

