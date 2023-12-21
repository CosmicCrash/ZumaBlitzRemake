-- NOTE:
-- May consider to ditch this class in the future and spread the contents to Game.lua, Level.lua and Profile.lua.
-- ~jakubg1


-- Class identification
local class = require "com.class"

---A root for all variable things during the game, such as level and player's progress.
---This class will be going bye-bye soon.
---To axe it, we need to have Sphere Selectors up and running.
---@class Session
---@overload fun(path, deserializationTable):Session
local Session = class:derive("Session")

-- Include commons
local Vec2 = require("src.Essentials.Vector2")

-- Include class constructors
local Level = require("src.Level")
local ColorManager = require("src.ColorManager")



---Constructs a new Session.
function Session:new()
	self.level = nil
	self.colorManager = ColorManager()
end



---An initialization callback.
function Session:init()
	_Game.uiManager:executeCallback("sessionInit")
end



---Updates the Session.
---@param dt number Delta time in seconds.
function Session:update(dt)
	if self.level then self.level:update(dt) end
end



---Starts a new Level from the current Profile, or loads one in progress if it has one.
function Session:startLevel()
	self.level = Level(_Game:getCurrentProfile():getLevelData())
	local savedLevelData = _Game:getCurrentProfile():getSavedLevel()
	if savedLevelData then
		self.level:deserialize(savedLevelData)
		_Game.uiManager:executeCallback("levelLoaded")
	else
		_Game.uiManager:executeCallback("levelStart")
	end
end



---Destroys the level along with its save data.
function Session:levelEnd()
	self.level:unsave()
	self.level:destroy()
	self.level = nil
end

---Destroys the level and marks it as won.
function Session:levelWin()
	self.level:win()
	self.level:destroy()
	self.level = nil
end

---Destroys this level and saves it for the future.
function Session:levelSave()
	self.level:save()
	self.level:destroy()
	self.level = nil
end

---Draws itself... It's actually just the level, from which all its components are drawn.
function Session:draw()
	if self.level then
		self.level:draw()
	end
end



---Returns whether both provided colors can attract or make valid scoring combinations with each other.
---@param color1 integer The first color to be checked against.
---@param color2 integer The second color to be checked against.
---@return boolean
function Session:colorsMatch(color1, color2)
	local matches = _Game.configManager.spheres[color1].matches
	for i, v in ipairs(matches) do
		if v == color2 then return true end
	end
	return false
end



---Destroys these spheres, for which the provided function returns `true`. Each sphere is checked separately.
---@param f function The function to be run for each sphere. Two parameters are allowed: `sphere` (Sphere) and `spherePos` (Vector2). If the function returns `true`, the sphere is destroyed.
---@param scorePos Vector2 The location of the floating text indicator showing how much score the player has gained.
---@param scoreFont string? The font to be used in the score text.
---@param noRewards boolean? If set to `true`, the previous two parameters are ignored, and the spheres are destroyed without giving any points.
---@param source string? The scoring source to attribute the destroy function to.
function Session:destroyFunction(f, scorePos, scoreFont, noRewards, source)
	-- we pass a function in the f variable
	-- if f(param1, param2, ...) returns true, the sphere is nuked
	source = source or "default"
	local score = 0
	local base_score = 0
	local base_multiplier = 1
	-- balls destroyed is used to calculate the exponent factor
	local balls_destroyed = 0
	local effective_ball_exponent = 1
	for i, path in ipairs(self.level.map.paths) do
		for j = #path.sphereChains, 1, -1 do
			local sphereChain = path.sphereChains[j]
			for k = #sphereChain.sphereGroups, 1, -1 do
				local sphereGroup = sphereChain.sphereGroups[k]
				for l = #sphereGroup.spheres, 1, -1 do
					local sphere = sphereGroup.spheres[l]
					local spherePos = sphereGroup:getSpherePos(l)
					if sphere and f(sphere, spherePos) and not sphere:isGhost() and sphere.color ~= 0 then
						sphereGroup:destroySphere(l)
						balls_destroyed = balls_destroyed + 1
						if not noRewards then
							-- Adjust score based on source (chain blast, hot frog, bomb, spirit shot, last hurrah)
							if source == "hotfrog" then
								score = score + self.level:getParameter("hotFrogPointsInc")
							elseif source == "cannon" then
								score = score + self.level:getParameter("cannonsPointsBase")
							elseif source == "chainblast" then
								score = score + self.level:getParameter("chainBlastScoreEach")
							elseif source == "bomb" then
								score = score + self.level:getParameter("bombsEachPoints")
							elseif source == "spritshot" then
								score = score + self.level:getParameter("spiritShotPointsEach")
							elseif source == "lasthurrah" then
								score = score + self.level:getParameter("lastHurrahPointInc")
							else
								score = score + self.level:getParameter("matchPointsBase")
							end
						end
					end
				end
			end
		end
	end
	-- calculate exponential and base score effects
	if source == "hotfrog" then
		effective_ball_exponent = self.level:getParameter("hotFrogEffectiveBallExponent")
		base_score = self.level:getParameter("hotFrogPointsBase")
	elseif source == "cannon" then
		base_multiplier = self.level:getParameter("cannonsPointsMultiplier")
	elseif source == "lasthurrah" then
		base_multiplier = self.level:getParameter("lastHurrahMultiplier")
		base_score = self.level:getParameter("lastHurrahPointBase")
	elseif source == "bomb" then
		effective_ball_exponent = self.level:getParameter("bombsEffectiveBallExponent")
		base_score = self.level:getParameter("bombsBasePoints")
		base_multiplier = self.level:getParameter("bombsMultPoints")
	elseif source == "chainblast" then
		effective_ball_exponent = self.level:getParameter("chainBlastEffectiveBallExponent")
		base_score = self.level:getParameter("chainBlastScoreBase")
		base_multiplier = self.level:getParameter("chainBlastScoreMult")
	elseif source == "spritshot" then
		effective_ball_exponent = self.level:getParameter("spiritShotEffectiveBallExponent")
		base_score = self.level:getParameter("spiritShotPointsBase")
		base_multiplier = self.level:getParameter("spiritShotPointsMult")
	end

	score = score * (math.floor(balls_destroyed^effective_ball_exponent) / math.max(balls_destroyed,1))
	score = score + base_score
	score = score * base_multiplier

	if not noRewards then
		self.level:grantScore(score)
		
		local final_score = score * self.level.multiplier

		-- do not display if cannon
		if source ~= "cannon" and source ~= "lasthurrah" then
			self.level:spawnFloatingText("+".._NumStr(final_score), scorePos, scoreFont or "fonts/score0.json")
		end

		-- add score to the appropriate category
	
		if source == "hotfrog" then
			self.level.hotFrogScore = self.level.hotFrogScore + final_score
		elseif source == "cannon" then
			self.level.cannonsScore = self.level.cannonsScore + final_score
		elseif source == "chainblast" then
			self.level.chainBlastsScore = self.level.chainBlastsScore + final_score
		elseif source == "bomb" then
			self.level.bombsScore = self.level.bombsScore + final_score
		elseif source == "spritshot" then
			self.level.spiritShotScore = self.level.spiritShotScore + final_score
		elseif source == "lasthurrah" then
			self.level.lastHurrahScore = self.level.lastHurrahScore + final_score
		end
	end
end



---Changes colors of these spheres, for which the provided function returns `true`, to a given color. Each sphere is checked separately.
---@param f function The function to be run for each sphere. Two parameters are allowed: `sphere` (Sphere) and `spherePos` (Vector2). If the function returns `true`, the sphere is affected by this function.
---@param color integer The new color of affected spheres.
---@param particle table? The particle effect to be used for each affected sphere.
function Session:setColorFunction(f, color, particle)
	-- we pass a function in the f variable
	-- if f(param1, param2, ...) returns true, the sphere color is changed
	for i, path in ipairs(self.level.map.paths) do
		for j = #path.sphereChains, 1, -1 do
			local sphereChain = path.sphereChains[j]
			for k = #sphereChain.sphereGroups, 1, -1 do
				local sphereGroup = sphereChain.sphereGroups[k]
				for l = #sphereGroup.spheres, 1, -1 do
					local sphere = sphereGroup.spheres[l]
					local spherePos = sphereGroup:getSpherePos(l)
					if f(sphere, spherePos) and sphere.color ~= 0 then
						sphere:changeColor(color, particle)
					end
				end
			end
		end
	end
end



---Destroys all spheres on the board.
---@param noRewards boolean? If set, all the spheres are destroyed without giving any points.
function Session:destroyAllSpheres(noRewards)
	self:destroyFunction(
		function(sphere, spherePos) return true end,
		self.level.shooter.pos + Vec2(0, -29),
		nil,
		noRewards
	)
end



---Destroys a single sphere from the board.
---@param s Sphere The sphere to be destroyed.
function Session:destroySingleSphere(s, effect)
	self:destroyFunction(
		function(sphere, spherePos) return sphere == s end,
		s:getPos(), _Game.configManager.spheres[s.color].matchFont,
		nil,
		effect
	)
end



---Destroys all spheres of a given color.
---@param color integer The sphere color to be removed.
function Session:destroyColor(color)
	self:destroyFunction(
		function(sphere, spherePos) return sphere.color == color end,
		self.level.shooter.pos + Vec2(0, -29)
	)
end



---Destroys all spheres that are closer than `radius` pixels to the `pos` position.
---@param pos Vector2 A position relative to which the spheres will be destroyed.
---@param radius number The range in pixels.
function Session:destroyRadius(pos, radius, effect)
	self:destroyFunction(
		function(sphere, spherePos) return (pos - spherePos):len() <= radius end,
		pos,
		nil,
		nil,
		effect
	)
end



---Destroys all spheres that are closer than `width` pixels to the `x` position on the X coordinate.
---@param x number An X coordinate relative to which the spheres will be destroyed.
---@param width number The range in pixels.
function Session:destroyVertical(x, width)
	self:destroyFunction(
		function(sphere, spherePos) return math.abs(x - spherePos.x) <= width / 2 end,
		self.level.shooter.pos + Vec2(0, -29)
	)
end



---Destroys all spheres that are closer than `radius` pixels to the `pos` position and match with a given color.
---@param pos Vector2 A position relative to which the spheres will be destroyed.
---@param radius number The range in pixels.
---@param color integer A color that any sphere must be matching with in order to destroy it.
function Session:destroyRadiusColor(pos, radius, color)
	-- DIRTY: Only hot frog uses this, so we can set the source to "hotfrog"

	self:destroyFunction(
		function(sphere, spherePos) return (pos - spherePos):len() <= radius and self:colorsMatch(color, sphere.color) end,
		pos,
		nil, nil,
		"hotfrog"
	)
end



---Destroys all spheres that are closer than `width` pixels to the `x` position on the X coordinate and match with a given color.
---@param x number An X coordinate relative to which the spheres will be destroyed.
---@param width number The range in pixels.
---@param color integer A color that any sphere must be matching with in order to destroy it.
function Session:destroyVerticalColor(x, width, color)
	self:destroyFunction(
		function(sphere, spherePos) return math.abs(x - spherePos.x) <= width / 2 and self:colorsMatch(color, sphere.color) end,
		self.level.shooter.pos + Vec2(0, -29)
	)
end



---Replaces the color of all spheres of a given color with another color.
---@param color1 integer The color to be changed from.
---@param color2 integer The new color of the affected spheres.
---@param particle table? A one-time particle packet to be used for each affected sphere.
function Session:replaceColor(color1, color2, particle)
	self:setColorFunction(
		function(sphere, spherePos) return sphere.color == color1 end,
		color2, particle
	)
end



---Replaces the color of all spheres within a given radius with another color, provided they match with a given sphere.
---@param pos Vector2 A position relative to which the spheres will be affected.
---@param radius number The range in pixels.
---@param color integer A color that any sphere must be matching with in order to destroy it.
---@param color2 integer A target color.
function Session:replaceColorRadiusColor(pos, radius, color, color2)
	self:setColorFunction(
		function(sphere, spherePos) return (pos - spherePos):len() <= radius and self:colorsMatch(color, sphere.color) end,
		color2
	)
end



---Returns the lowest length out of all sphere groups of a single color on the screen.
---This function ignores spheres that are offscreen.
---@return integer
function Session:getLowestMatchLength()
	local lowest = nil
	for i, path in ipairs(self.level.map.paths) do
		for j, sphereChain in ipairs(path.sphereChains) do
			for k, sphereGroup in ipairs(sphereChain.sphereGroups) do
				for l, sphere in ipairs(sphereGroup.spheres) do
					local matchLength = sphereGroup:getMatchLengthInChain(l)
					if sphere.color ~= 0 and not sphere:isOffscreen() and (not lowest or lowest > matchLength) then
						lowest = matchLength
						if lowest == 1 then -- can't go any lower
							return 1
						end
					end
				end
			end
		end
	end
	return lowest
end



---Returns a list of spheres which can be destroyed by Lightning Storm the next time it decides to impale a sphere.
---@param matchLength integer? The exact length of a single-color group which will be targeted.
---@param encourageMatches boolean? If `true`, the function will prioritize groups which have the same color on either end.
---@return table
function Session:getSpheresWithMatchLength(matchLength, encourageMatches)
	if not matchLength then return {} end
	local spheres = {}
	for i, path in ipairs(self.level.map.paths) do
		for j, sphereChain in ipairs(path.sphereChains) do
			for k, sphereGroup in ipairs(sphereChain.sphereGroups) do
				for l, sphere in ipairs(sphereGroup.spheres) do
					local valid = true
					-- Encourage matches: target groups that when destroyed will make a match.
					if encourageMatches then
						local color1, color2 = sphereGroup:getMatchBoundColorsInChain(l)
						valid = color1 and color2 and self:colorsMatch(color1, color2)
					end
					-- If one sphere can be destroyed in a large group to make a big match, don't trim edges to avoid lost opportunities.
					if matchLength > 3 then
						valid = sphereGroup.spheres[l - 1] and sphereGroup.spheres[l + 1] and self:colorsMatch(sphereGroup.spheres[l - 1].color, sphereGroup.spheres[l + 1].color)
					end
					if sphere.color ~= 0 and not sphere:isOffscreen() and sphereGroup:getMatchLengthInChain(l) == matchLength and valid then
						table.insert(spheres, sphere)
					end
				end
			end
		end
	end
	return spheres
end



---Returns the nearest sphere to the given position along with some extra data.
---The returned table has the following fields:
---
--- - `path` (Path),
--- - `sphereChain` (SphereChain),
--- - `sphereGroup` (SphereGroup),
--- - `sphere` (Sphere),
--- - `sphereID` (integer) - the sphere ID in the group,
--- - `pos` (Vector2) - the position of this sphere,
--- - `dist` (number) - the distance to this sphere,
--- - `half` (boolean) - if `true`, this is a half pointing to the end of the path, `false` if to the beginning of said path.
---@param pos Vector2 The position to be checked against.
---@return table
function Session:getNearestSphere(pos)
	local nearestData = {path = nil, sphereChain = nil, sphereGroup = nil, sphereID = nil, sphere = nil, pos = nil, dist = nil, half = nil}
	for i, path in ipairs(self.level.map.paths) do
		for j, sphereChain in ipairs(path.sphereChains) do
			for k, sphereGroup in ipairs(sphereChain.sphereGroups) do
				for l, sphere in ipairs(sphereGroup.spheres) do
					local spherePos = sphereGroup:getSpherePos(l)
					local sphereAngle = sphereGroup:getSphereAngle(l)
					local sphereHidden = sphereGroup:getSphereHidden(l)

					local sphereDist = (pos - spherePos):len()

					local sphereDistAngle = (pos - spherePos):angle()
					local sphereAngleDiff = (sphereDistAngle - sphereAngle + math.pi / 2) % (math.pi * 2)
					local sphereHalf = sphereAngleDiff <= math.pi / 2 or sphereAngleDiff > 3 * math.pi / 2
					-- if closer than the closest for now, save it
					if not sphere:isGhost() and not sphereHidden and (not nearestData.dist or sphereDist < nearestData.dist) then
						nearestData.path = path
						nearestData.sphereChain = sphereChain
						nearestData.sphereGroup = sphereGroup
						nearestData.sphereID = l
						nearestData.sphere = sphere
						nearestData.pos = spherePos
						nearestData.dist = sphereDist
						nearestData.half = sphereHalf
					end
				end
			end
		end
	end
	return nearestData
end



---Returns a random sphere on the board.
---position indicates what position to spawn at (modulus)
---@return Sphere
function Session:getRandomSphere(position)
	local allSpheres = {}
	for _, path in pairs(self.level.map.paths) do
		for _, sphereChain in pairs(path.sphereChains) do
			for _, sphereGroup in pairs(sphereChain.sphereGroups) do
				for i, sphere in pairs(sphereGroup.spheres) do
					local sphereHidden = sphereGroup:getSphereHidden(i)
					if not sphere:isGhost() and not sphereHidden then
						table.insert(allSpheres, sphere)
					end
				end
			end
		end
    end
	position = (position % #allSpheres) + 1
	return allSpheres[position]
end



---Returns the first sphere to collide with a provided line of sight along with some extra data.
---The returned table has the following fields:
---
--- - `path` (Path),
--- - `sphereChain` (SphereChain),
--- - `sphereGroup` (SphereGroup),
--- - `sphere` (Sphere),
--- - `sphereID` (integer) - the sphere ID in the group,
--- - `pos` (Vector2) - the position of this sphere,
--- - `dist` (number) - the distance to this sphere,
--- - `targetPos` (Vector2) - the collision position (used for i.e. drawing the reticle),
--- - `half` (boolean) - if `true`, this is a half pointing to the end of the path, `false` if to the beginning of said path.
---@param pos Vector2 The starting position of the line of sight.
---@param angle number The angle of the line. 0 is up.
---@return table
function Session:getNearestSphereOnLine(pos, angle)
	local nearestData = {path = nil, sphereChain = nil, sphereGroup = nil, sphereID = nil, sphere = nil, pos = nil, dist = nil, targetPos = nil, half = nil}
	for i, path in ipairs(self.level.map.paths) do
		for j, sphereChain in ipairs(path.sphereChains) do
			for k, sphereGroup in ipairs(sphereChain.sphereGroups) do
				for l, sphere in ipairs(sphereGroup.spheres) do
					local spherePos = sphereGroup:getSpherePos(l)
					local sphereSize = sphereGroup:getSphereSize(l)
					local sphereAngle = sphereGroup:getSphereAngle(l)
					local sphereHidden = sphereGroup:getSphereHidden(l)

					local sphereTargetCPos = (spherePos - pos):rotate(-angle) + pos
					local sphereTargetY = sphereTargetCPos.y + math.sqrt(math.pow(sphereSize / 2, 2) - math.pow(pos.x - sphereTargetCPos.x, 2))
					local sphereTargetPos = (Vec2(pos.x, sphereTargetY) - pos):rotate(angle) + pos
					local sphereDist = Vec2(pos.x - sphereTargetCPos.x, pos.y - sphereTargetY)

					local sphereDistAngle = (pos - spherePos):angle()
					local sphereAngleDiff = (sphereDistAngle - sphereAngle + math.pi / 2) % (math.pi * 2)
					local sphereHalf = sphereAngleDiff <= math.pi / 2 or sphereAngleDiff > 3 * math.pi / 2
					-- if closer than the closest for now, save it
					if not sphere:isGhost() and not sphereHidden and math.abs(sphereDist.x) <= sphereSize / 2 and sphereDist.y >= 0 and (not nearestData.dist or sphereDist.y < nearestData.dist.y) then
						nearestData.path = path
						nearestData.sphereChain = sphereChain
						nearestData.sphereGroup = sphereGroup
						nearestData.sphereID = l
						nearestData.sphere = sphere
						nearestData.pos = spherePos
						nearestData.dist = sphereDist
						nearestData.targetPos = sphereTargetPos
						nearestData.half = sphereHalf
					end
				end
			end
		end
	end
	return nearestData
end



return Session
