local class = require "com/class"

---@class ColorPalette
---@overload fun(path):ColorPalette
local Font = class:derive("Font")

local Vec2 = require("src/Essentials/Vector2")
local Color = require("src/Essentials/Color")



function Font:new(path)
	self.path = path

	local data = _LoadJson(path)
	self.type = data.type

	if self.type == "image" then
		self.image = _Game.resourceManager:getImage(data.image)
		self.height = self.image.size.y
		self.characters = {}
		for characterN, character in pairs(data.characters) do
			self.characters[characterN] = {
				quad = love.graphics.newQuad(character.offset, 0, character.width, self.image.size.y, self.image.size.x, self.image.size.y),
				width = character.width
			}
		end

		self.reportedCharacters = {}
	elseif self.type == "truetype" then
		self.font = _LoadFont(_ParsePath(data.path), data.size)
		self.color = _ParseColor(data.color)
	end
end

-- Image type only
function Font:getCharacter(character)
	local b = character:byte()
	local c = self.characters[character]
	if c then
		return c
	elseif b >= 97 and b <= 122 then
		-- if lowercase character does not exist, we try again with an uppercase character
		return self:getCharacter(string.char(b - 32))
	else
		-- report only once
		if not self.reportedCharacters[character] then
			_Log:printt("Font", "ERROR: No character " .. tostring(character) .. " was found in font " .. self.path)
			self.reportedCharacters[character] = true
		end
		return self.characters["0"]
	end
end

function Font:getTextSize(text)
	if self.type == "image" then
		local size = Vec2(0, self.height)
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				size.y = size.y + self.height
			else
				size.x = size.x + self:getCharacter(character).width
			end
		end
		return size
	elseif self.type == "truetype" then
		local size = Vec2(self.font:getWidth(text), self.font:getHeight())
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				size.y = size.y + self.font:getHeight()
			end
		end
		return size
	end
end

function Font:draw(text, pos, align, color, alpha)
	align = align or Vec2(0.5)
	color = color or Color()
	alpha = alpha or 1

	if self.type == "image" then
		love.graphics.setColor(color.r, color.g, color.b, alpha)

		local y = pos.y - self:getTextSize(text).y * align.y
		local line = ""
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				self:drawLine(line, Vec2(pos.x, y), align.x)
				line = ""
				y = y + self.height
			else
				line = line .. character
			end
		end
		self:drawLine(line, Vec2(pos.x, y), align.x)
	elseif self.type == "truetype" then
		local oldFont = love.graphics.getFont()

		love.graphics.setColor(color.r * self.color.r, color.g * self.color.g, color.b * self.color.b, alpha)
		love.graphics.setFont(self.font)
		local p = _PosOnScreen(pos - self:getTextSize(text) * align)
		love.graphics.print(text, p.x, p.y, 0, _GetResolutionScale())

		love.graphics.setFont(oldFont)
	end
end

-- Image type only
function Font:drawLine(text, pos, align)
	pos.x = pos.x - self:getTextSize(text).x * align
	for i = 1, text:len() do
		local character = text:sub(i, i)
		self:drawCharacter(character, pos)
		pos.x = pos.x + self:getCharacter(character).width
	end
end

-- Image type only
function Font:drawCharacter(character, pos)
	pos = _PosOnScreen(pos)
	--if self.characters[character] then
	self.image:draw(self:getCharacter(character).quad, pos.x, pos.y, 0, _GetResolutionScale())
	--else
	--	print("ERROR: Unexpected character: " .. character)
	--end
end

return Font
