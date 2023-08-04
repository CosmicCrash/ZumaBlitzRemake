local class = require "com.class"

---@class Shader
---@overload fun(path):Shader
local Shader = class:derive("Shader")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Image = require("src.Essentials.Image")

function Shader:new(path)
	self.path = path
	local data = _LoadJson(path)
	if not data then error("Failed to load shader: " .. path) end

	self.shader = love.graphics.newShader(_ParsePath(data.pixelShader),_ParsePath(data.vertexShader))
	self.internal = data.internal

	self.parameters = {}
	for _,v in ipairs(data.parameters) do
		assert(v.name and type(v.name) == 'string',
			"No name or invalid name provided for parameter in shader: "..path)
		local t = v.type
		if t == 'number' then
			if v.init then assert(type(v.init) == 'number',
				string.format("Invalid init value for %s, expected a number, in shader: %s",v.name,path)
			) end
		elseif t == 'color' then
			if v.init then assert(type(v.init) == 'table' and #v.init == 4,
				string.format("Invalid init value for %s, expected a color [r,g,b,a], in shader: %s",v.name,path)
			) end
		elseif t == 'image' then
			if v.init then assert(type(v.init) == 'string',
				string.format("Invalid init value for %s, expected a string with a file path, in shader: %s",v.name,path)
			) end
		elseif t == 'transform' then
		else
			error(string.format("Invalid parameter type %s for %s in shader: %s",t,v.name,path))
		end

		self.parameters[v.name] = {
			type = v.type
		}
		if v.init then
			self:send(v.name,v.init)
		end
	end
end

function Shader:send(name,...)
	local param = self.parameters[name]
	if param.type == 'transform' then
		if not param.cache then param.cache = love.math.newTransform() end
		param.cache:setTransformation(...)
		self.shader:send(name,{param.cache:getMatrix()})
	elseif param.type == 'image' then
		local v = select(1,...)
		if type(v) == 'string' then
			param.cache = self.internal and
				Image(_ParsePath(v)) or
				_Game.resourceManager:getImage(v)
		else
			param.cache = v
		end
		self.shader:send(name,param.cache.img)
	elseif param.type == 'color' then
		self.shader:sendColor(name,...)
	else
		self.shader:send(name,...)
	end
end

function Shader:set()
	love.graphics.setShader(self.shader)
end

function Shader:reset()
	love.graphics.setShader()
end

return Shader