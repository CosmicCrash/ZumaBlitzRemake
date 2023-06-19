local class = require "com.class"

---@class Hole
---@overload fun(params):Hole
local Hole = class:derive("Hole")

local Vec2 = require("src.Essentials.Vector2")



--[[
    !! READ BEFORE IMPLEMENTING THIS TO UPSTREAM !!

    This fork-specific class has hardcoded values. De-hardcode and allow for
    customization before implementing to upstream.

    This only allows for smooth movement of the top sprite. Consider the following
    prior to implementing this class to upstream:
    - allow ZD-style skull animations (sprite states)
    - allow multiple animations/sprite positions
    - allow multiple effects
    - etc...
]]

---Initializes a new Hole.
---@param path Path
function Hole:new(path)
    self.path = path
    self.pos = Vec2.round(path.nodes[#path.nodes].pos)
    self.alpha = 0
    self.frame = 0

    self.skullHoleSprite = _Game.resourceManager:getSprite("sprites/game/skull_hole.json")
    self.skullMaskSprite = _Game.resourceManager:getSprite("sprites/game/skull_mask.json")
    self.skullFrameSprite = _Game.resourceManager:getSprite("sprites/game/skull_frame.json")
    self.skullTopSprite = _Game.resourceManager:getSprite("sprites/game/skull_top.json")
    self.skullBottomSprite = _Game.resourceManager:getSprite("sprites/game/skull_bottom.json")
    self.skullRing = _Game.resourceManager:getSprite("sprites/game/skull_ring.json")
    self.skullMaskShader = love.graphics.newShader [[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
                // a discarded pixel wont be applied as the stencil.
                discard;
            }
            return vec4(1.0);
        }
    ]]

    self.topSpriteOffset = 0
    -- the bottom sprite doesn't move
end



function Hole:update(dt)
    local dangerProgress = self.path:getDangerProgress()
    self.frame = ((self.frame + (dt * 15)) % 36)

    -- top sprite
    local topSpriteOffsetBuffer = dangerProgress*20
    if self.topSpriteOffset < topSpriteOffsetBuffer then
        self.topSpriteOffset = math.min(self.topSpriteOffset + 20 * dt, topSpriteOffsetBuffer)
    elseif self.topSpriteOffset > topSpriteOffsetBuffer then
        self.topSpriteOffset = math.max(self.topSpriteOffset - 4 * dt, topSpriteOffsetBuffer)
    end

    -- ring of fire
    -- the ring of fire uses some sort of animation that changes depending on the state,
    -- an opacity value won't do
    -- 2 seconds to fade in, and 1.5 seconds fading out.
    if dangerProgress > 0 then
        self.alpha = math.min(self.alpha + (dt/2), 1)
    else
        self.alpha = math.max(self.alpha - (dt/1.5), 0)
    end
    if self.alpha == 0 then self.frame = 1 end

end



function Hole:draw()
    self.skullHoleSprite:draw(self.pos, Vec2(0.5,0.5))
    love.graphics.stencil(function()
        love.graphics.setShader(self.skullMaskShader)
        self.skullMaskSprite:draw(self.pos, Vec2(0.5,0.5))
        love.graphics.setShader()
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    local skullTopPos = Vec2(self.pos.x, (self.pos.y-3) - self.topSpriteOffset)
    local skullBotPos = Vec2(self.pos.x, self.pos.y+10)

    self.skullTopSprite:draw(skullTopPos, Vec2(0.5,0.5))
    self.skullBottomSprite:draw(skullBotPos, Vec2(0.5, 0.5))

    love.graphics.setStencilTest()
    self.skullFrameSprite:draw(self.pos, Vec2(0.5,0.5))
    
    if self.path:getDangerProgress() > 0 then
        self.skullRing:draw(self.pos, Vec2(0.5,0.5),nil,self.frame+1,nil,nil,self.alpha)
    end
end



return Hole