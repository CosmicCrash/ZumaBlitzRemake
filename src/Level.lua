local class = require "com.class"

---@class Level
---@overload fun(data):Level
local Level = class:derive("Level")

local Vec2 = require("src.Essentials.Vector2")

local Map = require("src.Map")
local Shooter = require("src.Shooter")
local ShotSphere = require("src.ShotSphere")
local Target = require("src.Target")
local Collectible = require("src.Collectible")
local FloatingText = require("src.FloatingText")
local json = require("com.json")

-- send stuff
local http = require("socket.http")
local ltn12 = require"ltn12"


---Constructs a new Level.
---@param data table The level data, specified in a level config file.
function Level:new(data)
    self.map = Map(self, "maps/" .. data.map, data.pathsBehavior)
    self.shooter = Shooter(data.shooter or self.map.shooter)

    -- FORK-SPECIFIC CHANGE: Change to frogatar, then spirit animal if any
    -- Yes this is the order and there should be an animation soon
	local frogatar = _Game:getCurrentProfile():getFrogatar()
	local monument = _Game:getCurrentProfile():getActiveMonument()
	_Game.configManager.frogatars[frogatar]:changeTo(self)
	if monument then
		---@diagnostic disable-next-line: param-type-mismatch
		_Game.configManager.frogatars[monument]:changeTo(self)
	end

	self.matchEffect = data.matchEffect

	local objectives = data.objectives
	if data.target then
		objectives = {{type = "destroyedSpheres", target = data.target}}
	end
	if _Game.satMode then
		objectives = {{type = "destroyedSpheres", target = _Game:getCurrentProfile():getUSMNumber() * 10}}
	end
	self.objectives = {}
	for i, objective in ipairs(objectives) do
		table.insert(self.objectives, {type = objective.type, target = objective.target, progress = 0, reached = false})
	end

	self.stateCount = 0

    self.powerupFrequency = data.powerupFrequency or 15
    self.individualPowerupFrequencies = data.individualPowerupFrequencies or nil
	self.powerupList = {"timeball", "multiplier"} -- this should prob be replaced with a function when powers are implemented
    -- Apparently Multiplier balls appear faster as Spirit Turtle, but by how much?
    -- src: http://bchantech.dreamcrafter.com/zumablitz/spiritanimals.php
	self.lastPowerupDeltas = {}
	for i, powerup in ipairs(self.powerupList) do
        self.lastPowerupDeltas[powerup] = self.stateCount - 600
    end
    for powerup, v in pairs(self.lastPowerupDeltas) do
		if self.individualPowerupFrequencies and #self.individualPowerupFrequencies ~= 0 then
			self.individualPowerupFrequencies[powerup] = data.individualPowerupFrequencies[powerup]
		end
	end

	---@type Sprite
	self.targetSprite = _Game.configManager.targetSprites.random[math.random(1, #_Game.configManager.targetSprites.random)]
    self.targetFrequency = data.targetFrequency
    self.targetInitialDelaySecondsElapsed = false

	self.targetHitScores = self:getTargetHitScoreValues()

	self.colorGeneratorNormal = data.colorGeneratorNormal
	self.colorGeneratorDanger = data.colorGeneratorDanger

	self.musicName = data.music
	self.dangerMusicName = data.dangerMusic
	self.ambientMusicName = data.ambientMusic

	self.dangerSoundName = data.dangerSound or "sound_events/warning.json"
	self.dangerLoopSoundName = data.dangerLoopSound or "sound_events/warning_loop.json"
    self.rollingSound = _Game:playSound("sound_events/sphere_roll.json")
	
	-- Initalize random seed for ball generation
	self.rngseed = os.time()
	self.ball_rng = love.math.newRandomGenerator(self.rngseed)
	self.ball_rng_streak = love.math.newRandomGenerator(self.rngseed)
	
	-- Additional variables come from this method!
	self:reset()
end



---Updates the Level.
---@param dt number Delta time in seconds.
function Level:update(dt)
	-- Game speed modifier is going to be calculated outside the main logic
	-- function, as it messes with time itself.
	if self.gameSpeedTime > 0 then
		self.gameSpeedTime = self.gameSpeedTime - dt
		if self.gameSpeedTime <= 0 then
			-- The time has elapsed. Return to default speed.
			self.gameSpeed = 1
		end
	end

	if not self.pause then
		self:updateLogic(dt * self.gameSpeed)
    end
	-- Rolling sound
	if self.rollingSound then
		if self.pause then
            self.rollingSound:pause()
        elseif (not self.pause) and self.controlDelay then
			self.rollingSound:play()
		end
	end

	self:updateMusic()
end



---Updates the Level's logic.
---@param dt number Delta time in seconds.
function Level:updateLogic(dt)
	self.map:update(dt)
    self.shooter:update(dt)
    self.stateCount = self.stateCount + dt
	self.targetHitScore = self.targetHitScores[math.min(self.targets+1, 6)] + (_MathAreKeysInTable(_Game:getCurrentProfile():getEquippedFoodItemEffects(), "fruitPointsBase") or 0)

    -- Danger sound
	--[[
	local d1 = self:getDanger() and not self.lost
	local d2 = self.danger
	if d1 and not d2 then
		self.dangerSound = _Game:playSound(self.dangerLoopSoundName)
	elseif not d1 and d2 then
		self.dangerSound:stop()
		self.dangerSound = nil
	end
	]]

	self.danger = self:getDanger() and not self.lost



	-- Shot spheres, collectibles, floating texts
	for i, shotSphere in ipairs(self.shotSpheres) do
		shotSphere:update(dt)
	end
	for i = #self.shotSpheres, 1, -1 do
		local shotSphere = self.shotSpheres[i]
		if shotSphere.delQueue then table.remove(self.shotSpheres, i) end
	end
	for i, collectible in ipairs(self.collectibles) do
		collectible:update(dt)
	end
	for i = #self.collectibles, 1, -1 do
		local collectible = self.collectibles[i]
		if collectible.delQueue then table.remove(self.collectibles, i) end
	end
	for i, floatingText in ipairs(self.floatingTexts) do
		floatingText:update(dt)
	end
	for i = #self.floatingTexts, 1, -1 do
		local floatingText = self.floatingTexts[i]
		if floatingText.delQueue then table.remove(self.floatingTexts, i) end
	end



	-- Lightning storm
	if self.lightningStormCount > 0 then
		self.lightningStormTime = self.lightningStormTime - dt
		if self.lightningStormTime <= 0 then
			self:spawnLightningStormPiece()
			self.lightningStormCount = self.lightningStormCount - 1
			if self.lightningStormCount == 0 then
				self.lightningStormTime = 0
			else
				self.lightningStormTime = self.lightningStormTime + 0.3
			end
		end
	end



	-- Net
	if self.netTime > 0 then
		self.netTime = self.netTime - dt
		if self.netTime <= 0 then
			self.netTime = 0
		end
	end



	-- Time counting
	if self.started and not self.controlDelay and not self:getFinish() and not self.finish and not self.lost then
		self.time = self.time + dt
    end



    -- Hot Frog handling
	if self.started and not self.controlDelay and not self:getFinish() and not self.finish and not self.lost then
		if self.blitzMeter == 1 then
			-- We're in hot frog mode, reset once the shooter has a ball other than the fireball.
			if self.shooter.color > 0 then
				self.shotLastHotFrogBall = true
				self.blitzMeter = 0
                self.blitzMeterCooldown = 0
			end
        else
			self.shotLastHotFrogBall = false
			if self.blitzMeterCooldown == 0 then
				self.blitzMeter = math.max(self.blitzMeter - 0.03 * dt, 0)
			else
				self.blitzMeterCooldown = math.max(self.blitzMeterCooldown - dt, 0)
			end
		end
    end



    -- Zuma style powerups
    if self.started and not self.finish and not self:areAllObjectivesReached() and not self:getEmpty() then
        local powerups = {}
		for _,v in pairs(self.powerupList) do
			table.insert(powerups, v)
		end

		local multiplierCap = 9
		local raiseCap = _MathAreKeysInTable(_Game:getCurrentProfile():getEquippedFoodItemEffects(), "multiplierMaximum")
        if raiseCap then
            multiplierCap = multiplierCap + raiseCap
        end
		-- Don't spawn multipliers if we've hit the cap
		if self.multiplier >= multiplierCap then
			local pCount = 1
			for _,v in pairs(powerups) do
                if v == "multiplier" then
					table.remove(powerups, pCount)
                end
				pCount = pCount + 1
			end
		end

        local powerupToAdd = powerups[math.random(1, #powerups)]
        local frequencies = {
            all = self.powerupFrequency
        }
        for i, powerup in ipairs(self.powerupList) do
            frequencies[powerup] = (self.individualPowerupFrequencies and self.individualPowerupFrequencies[powerup]) or frequencies.all
		end
        for powerup, v in pairs(self.lastPowerupDeltas) do
			for k, w in pairs(frequencies) do
				if frequencies[powerup] > 0 and (math.random() < 1 / frequencies[powerup]) and frequencies[powerup] < self.stateCount - self.lastPowerupDeltas[powerup] then
					local sphere = _Game.session:getRandomSphere()
                    if sphere then
                        if powerupToAdd == "multiplier" then
                            sphere:addPowerup("multiplier")
							self.multipliersSpawned = self.multipliersSpawned + 1
						elseif powerupToAdd ~= "multiplier" then
							sphere:addPowerup(powerupToAdd)
							-- determine what powerup spawned and increment the respective stat.
							
							if powerupToAdd == "timeball" then
								self.chronoBallsSpawned = self.chronoBallsSpawned + 1
							end
							if powerupToAdd == "bomb" then
								self.bombsSpawned = self.bombsSpawned + 1
							end
							if powerupToAdd == "cannon" then
								self.cannonsSpawned = self.cannonsSpawned + 1
							end
							if powerupToAdd == "colornuke" then
								self.colorNukesSpawned = self.colorNukesSpawned + 1
							end
						end
					end
					self.lastPowerupDeltas[powerup] = self.stateCount
				end
			end
        end
		-- Traverse through all the spheres one more time and remove any multiplier powerups if
        -- we've reached the cap
		-- TODO: Is there a better way to traverse every sphere? Might need to add a new function
		if self.multiplier >= multiplierCap then
			self.multiplier = multiplierCap
			for _, path in pairs(self.map.paths) do
				for _, sphereChain in pairs(path.sphereChains) do
					for _, sphereGroup in pairs(sphereChain.sphereGroups) do
						for i, sphere in pairs(sphereGroup.spheres) do
							if not sphere:isGhost() and sphere.powerup == "multiplier" then
								sphere:removePowerup()
							end
						end
					end
				end
			end
		end
	end



    -- Targets
    if self.started and not self.finish then
		if not self.target and (self.map.targetPoints and self.targetFrequency) then
            local validPoints = {}
			if self.targetFrequency.type == "seconds" then
				self.targetSecondsCooldown = self.targetSecondsCooldown - dt
				if self.targetSecondsCooldown < 0 then
					if not self.targetInitialDelaySecondsElapsed then
						self.targetInitialDelaySecondsElapsed = true
                        self.targetSecondsCooldown = self.targetFrequency.delay
						local fruitMaster = _Game:getCurrentProfile():getEquippedPower("fruit_master")
						if fruitMaster then
							self.targetSecondsCooldown = self.targetSecondsCooldown - fruitMaster:getCurrentLevelData().subtractiveSeconds
						end
					end
					for i, point in ipairs(self.map.targetPoints) do
						for j, path in ipairs(self.map.paths) do
							local d = path:getMaxOffset() / path.length
							if d > point.distance then
								table.insert(validPoints, Vec2(point.pos.x, point.pos.y))
							end
						end
					end
				end
			elseif self.targetFrequency.type == "frequency" then
				-- we won't be implementing this for ZBR, but this is here for
				-- flexibility of OpenSMCE
			end
			if #validPoints > 0 then
				self.target = Target(
					self.targetSprite,
					validPoints[math.random(1, #validPoints)],
					false -- no slot machine yet!
                )
				_Game:playSound("sound_events/target_spawn.json")
				self.fruitSpawned = self.fruitSpawned + 1 
			end
		elseif self.target then
			-- don't tick the timer down if there's fruit present
            self.targetSecondsCooldown = self.targetFrequency.delay
			local fruitMaster = _Game:getCurrentProfile():getEquippedPower("fruit_master")
			if fruitMaster then
				self.targetSecondsCooldown = self.targetSecondsCooldown - fruitMaster:getCurrentLevelData().subtractiveSeconds
			end
			if self.target.delQueue then
				self.target = nil
            end
            if self.target then
				-- this may get called after target gets nil'd
				self.target:update(dt)
			end
		end
	end



	-- Objectives
	self:updateObjectives()



	-- Stop the board once target time reached
	if not self.finish and self:areAllObjectivesReached() and not self:hasShotSpheres() and not self:areMatchesPredicted() then
		self.shooter:empty()
		self.finish = true
		self.wonDelay = _Game.configManager.gameplay.level.wonDelay

        for i, path in ipairs(self.map.paths) do
			for j, chain in ipairs(path.sphereChains) do
                chain:concludeGeneration()
				self:applyEffect({
                    type = "speedOverride",
					speedBase = 0,
					speedMultiplier = 0,
					decceleration = 0,
					time = 0
				})
			end
        end
		self:spawnFloatingText("TIME'S UP!", Vec2(380,285), "fonts/score0.json")
		--TODO: Implement the Last Hurrah
        _Game:playSound("sound_events/time_up.json")
	end



	-- Level start
	-- TODO: HARDCODED - make it more flexible
	if self.controlDelay then
		self.controlDelay = self.controlDelay - dt
		if self.controlDelay <= 0 then
            self.controlDelay = nil
			if self.rollingSound then
				self.rollingSound:stop()
			end
		end
	end



	-- Level finish
	if self:getFinish() and not self.finish and not self.finishDelay then
		self.finishDelay = _Game.configManager.gameplay.level.finishDelay
	end

	if self.finishDelay then
		self.finishDelay = self.finishDelay - dt
		if self.finishDelay <= 0 then
			self.finishDelay = nil
			self.finish = true
			self.bonusDelay = 0
			self.shooter:empty()
		end
	end

	if self.bonusDelay and (self.bonusPathID == 1 or not self.map.paths[self.bonusPathID - 1].bonusScarab) then
		if self.map.paths[self.bonusPathID] then
			self.bonusDelay = self.bonusDelay - dt
			if self.bonusDelay <= 0 then
				self.map.paths[self.bonusPathID]:spawnBonusScarab()
				self.bonusDelay = _Game.configManager.gameplay.level.bonusDelay
				self.bonusPathID = self.bonusPathID + 1
			end
		elseif self:getFinish() then
			self.wonDelay = _Game.configManager.gameplay.level.wonDelay
			self.bonusDelay = nil
		end
	end

	if self.wonDelay then
		print("wondelay " .. self.wonDelay )
		self.wonDelay = self.wonDelay - dt
		if self.wonDelay <= 0 then
			self.wonDelay = nil
			-- FORK-SPECIFIC CODE: Add a highscore after the board
			_Game:getCurrentProfile():writeHighscore()
            _Game.uiManager:executeCallback("levelComplete")
			self.ended = true
			self:saveStats()
		end
	end



	-- Level lose
    if self.lost and self:getEmpty() and not self.ended then
		if self.rollingSound then
			self.rollingSound:stop()
		end
		-- FORK-SPECIFIC CODE: Add a highscore after the board
		_Game:getCurrentProfile():writeHighscore()
		_Game.uiManager:executeCallback("levelLost")
		self.ended = true
		self:saveStats()
	end

	-- Other variables, such as the speed timer
	-- timer will not tick down when under hot frog.
	if self.speedTimer > 0 and self.blitzMeter < 1 then
		self.speedTimer = self.speedTimer - dt
	end
end



---Adjusts which music is playing based on the level's internal state.
function Level:updateMusic()
	local music = _Game:getMusic(self.musicName)

    local time = math.floor(math.max(self.objectives[1].target - self.objectives[1].progress, 0))
	
	if self.dangerMusicName then
		local dangerMusic = _Game:getMusic(self.dangerMusicName)

		-- If the level hasn't started yet, is lost, won or the game is paused,
		-- mute the music.
		if not self.started or self.ended or self.pause then
			music:setVolume(0)
			dangerMusic:setVolume(0)
		else
			-- Play the music accordingly to the danger flag.
			if time < 15 then
				music:setVolume(0)
				dangerMusic:setVolume(1)
			else
				music:setVolume(1)
				dangerMusic:setVolume(0)
			end
		end
	else
		-- If there's no danger music, then mute it or unmute in a similar fashion.
		if not self.started or self.ended or self.pause then
			music:setVolume(0)
		else
			music:setVolume(1)
		end
	end

	if self.ambientMusicName then
		local ambientMusic = _Game:getMusic(self.ambientMusicName)

		-- Ambient music plays all the time.
		ambientMusic:setVolume(1)
	end
end



---Updates the progress of this Level's objectives.
function Level:updateObjectives()
	for i, objective in ipairs(self.objectives) do
		if objective.type == "destroyedSpheres" then
			objective.progress = self.destroyedSpheres
		elseif objective.type == "timeSurvived" then
			objective.progress = self.time
		elseif objective.type == "score" then
			objective.progress = self.score
		end
		objective.reached = objective.progress >= objective.target
	end
end



---Activates a collectible generator in a given position.
---@param pos Vector2 The position where the collectibles will spawn.
---@param entryName string The CollectibleEntry ID.
function Level:spawnCollectiblesFromEntry(pos, entryName)
	if not entryName then
		return
	end

	local manager = _Game.configManager.collectibleGeneratorManager
	local entry = manager:getEntry(entryName)
	local collectibles = entry:generate()
	for i, collectible in ipairs(collectibles) do
		self:spawnCollectible(pos, collectible)
	end
end



---Adds score to the current Profile, as well as to level's statistics.
---@param score integer The score to be added.
function Level:grantScore(score)
	score = score * self.multiplier
	self.score = self.score + score
	_Game:getCurrentProfile():grantScore(score)
end



---Adds one coin to the current Profile and to level's statistics.
function Level:grantCoin()
	self.coins = self.coins + 1
	_Game:getCurrentProfile():grantCoin()
end



---Adds one gem to the level's statistics.
function Level:grantGem()
	self.gems = self.gems + 1
end



---Adds one sphere to the destroyed sphere counter.
function Level:destroySphere()
	if self.lost then
		return
	end

	self.destroyedSpheres = self.destroyedSpheres + 1
end



---Returns the fraction of progress of the given objective as a number in a range [0, 1].
---@param n integer The objective index.
---@return number
function Level:getObjectiveProgress(n)
	local objective = self.objectives[n]
	return math.min(objective.progress / objective.target, 1)
end



---Returns whether all objectives defined in this level have been reached.
---@return boolean
function Level:areAllObjectivesReached()
	for i, objective in ipairs(self.objectives) do
		if not objective.reached then
			return false
		end
	end
	return true
end



---Applies an effect to the level.
---@param effect table The effect data to be applied.
---@param TMP_pos Vector2? The position of the effect.
function Level:applyEffect(effect, TMP_pos)
	if effect.type == "replaceSphere" then
		self.shooter:getSphere(effect.color)
	elseif effect.type == "multiSphere" then
		self.shooter:getMultiSphere(effect.color, effect.count)
	elseif effect.type == "speedShot" then
		self.shooter.speedShotTime = effect.time
		self.shooter.speedShotSpeed = effect.speed
	elseif effect.type == "speedOverride" then
		for i, path in ipairs(self.map.paths) do
			for j, sphereChain in ipairs(path.sphereChains) do
				sphereChain.speedOverrideBase = effect.speedBase
				sphereChain.speedOverrideMult = effect.speedMultiplier
				sphereChain.speedOverrideDecc = effect.decceleration
				sphereChain.speedOverrideTime = effect.time
			end
		end
	elseif effect.type == "destroyAllSpheres" then
		-- DIRTY: replace this with an appropriate call within this function
		-- when Session class gets removed.
		_Game.session:destroyAllSpheres()
	elseif effect.type == "destroyColor" then
		-- Same as above.
		_Game.session:destroyColor(effect.color)
	elseif effect.type == "spawnScorpion" then
		local path = self:getMostDangerousPath()
		if path then
			path:spawnScorpion()
		end
	elseif effect.type == "lightningStorm" then
		self.lightningStormCount = effect.count
	elseif effect.type == "activateNet" then
		self.netTime = effect.time
	elseif effect.type == "changeGameSpeed" then
		self.gameSpeed = effect.speed
		self.gameSpeedTime = effect.duration
	elseif effect.type == "setCombo" then
		self.combo = effect.combo
	elseif effect.type == "grantScore" then
		self:grantScore(effect.score)
		self:spawnFloatingText(_NumStr(effect.score), TMP_pos, "fonts/score0.json")
	elseif effect.type == "grantCoin" then
		self:grantCoin()
	elseif effect.type == "incrementGemStat" then
		self:grantGem()
	elseif effect.type == "addTime" then
        self.objectives[1].target = self.objectives[1].target + effect.amount
		self.extraTimeAdded = self.extraTimeAdded + effect.amount
    elseif effect.type == "addMultiplier" then
		self.multiplier = self.multiplier + effect.amount
	end
end



---Strikes a single time during a lightning storm.
function Level:spawnLightningStormPiece()
	-- get a sphere candidate to be destroyed
	local sphere = self:getLightningStormSphere()
	-- if no candidate, the lightning storm is over
	if not sphere then
		self.lightningStormCount = 0
		self.lightningStormTime = 0
		return
	end

	-- spawn a particle, add points etc
	local pos = sphere:getPos()
	self:grantScore(10)
	self:spawnFloatingText(_NumStr(10), pos, _Game.configManager.spheres[sphere.color].matchFont)
	_Game:spawnParticle("particles/lightning_beam.json", pos)
	_Game:playSound("sound_events/lightning_storm_destroy.json")
	-- destroy it
	sphere.sphereGroup:destroySphere(sphere.sphereGroup:getSphereID(sphere))
end



---Picks a sphere to be destroyed by a lightning storm strike, or `nil` if no spheres are found.
---@return Sphere|nil
function Level:getLightningStormSphere()
	local ln = _Game.session:getLowestMatchLength()
	-- first, check for spheres that would make matching easier when destroyed
	local spheres = _Game.session:getSpheresWithMatchLength(ln, true)
	if #spheres > 0 then
		return spheres[math.random(#spheres)]
	end
	-- if none, then check for any of the shortest groups
	spheres = _Game.session:getSpheresWithMatchLength(ln)
	if #spheres > 0 then
		return spheres[math.random(#spheres)]
	end
	-- if none, return nothing
	return nil
end





---Returns currently used color generator data.
---@return table
function Level:getCurrentColorGenerator()
	if self.danger then
		return _Game.configManager.colorGenerators[self.colorGeneratorDanger]
	else
		return _Game.configManager.colorGenerators[self.colorGeneratorNormal]
	end
end



---Generates a new color for the Shooter.
---@return integer
function Level:getNewShooterColor()
	return self:generateColor(self:getCurrentColorGenerator())
end



---Generates a color based on the data.
---@param data table Shooter color generator data.
---@return integer
function Level:generateColor(data)
	if data.type == "random" then
		-- Make a pool with colors which are on the board.
		local pool = {}
		for i, color in ipairs(data.colors) do
			if not data.hasToExist or _Game.session.colorManager:isColorExistent(color) then
				table.insert(pool, color)
			end
		end
		-- Return a random item from the pool.
		if #pool > 0 then
			return pool[math.random(#pool)]
		end

	elseif data.type == "near_end" then
		-- Select a random path.
		local path = _Game.session.level:getRandomPath(true, data.paths_in_danger_only)
		if not path:getEmpty() then
			-- Get a SphereChain nearest to the pyramid
			local sphereChain = path.sphereChains[1]
			-- Iterate through all groups and then spheres in each group
			local lastGoodColor = nil
			-- reverse iteration!!!
			for i, sphereGroup in ipairs(sphereChain.sphereGroups) do
				for j = #sphereGroup.spheres, 1, -1 do
					local sphere = sphereGroup.spheres[j]
					local color = sphere.color
					-- If this color is generatable, check if we're lucky this time.
					if _MathIsValueInTable(data.colors, color) then
						if math.random() < data.select_chance then
							return color
						end
						-- Save this color in case if no more spheres are left.
						lastGoodColor = color
					end
				end
			end
			-- no more spheres left, get the last good one if exists
			if lastGoodColor then
				return lastGoodColor
			end
		end
	end

	-- Else, return a fallback value.
	if type(data.fallback) == "table" then
		return self:generateColor(data.fallback)
	end
	return data.fallback
end





---Returns `true` if no Paths on this Level's Map contain any Spheres.
---@return boolean
function Level:getEmpty()
	for i, path in ipairs(self.map.paths) do
		if not path:getEmpty() then
			return false
		end
	end
	return true
end



---Returns `true` if any Paths on this Level's Map are in danger.
---@return boolean
function Level:getDanger()
	for i, path in ipairs(self.map.paths) do
		for j, sphereChain in ipairs(path.sphereChains) do
			if sphereChain:getDanger() then
				return true
			end
		end
	end
	return false
end



---Returns the maximum percentage distance which is occupied by spheres on all paths.
---@return number
function Level:getMaxDistance()
	local distance = 0
	for i, path in ipairs(self.map.paths) do
		distance = math.max(distance, path:getMaxOffset() / path.length)
	end
	return distance
end



---Returns the maximum danger percentage distance from all paths.
---Danger percentage is a number interpolated from 0 at the beginning of a danger zone to 1 at the end of the path.
---@return number
function Level:getMaxDangerProgress()
	local distance = 0
	for i, path in ipairs(self.map.paths) do
		distance = math.max(distance, path:getDangerProgress())
	end
	return distance
end



---Returns the Path which has the maximum percentage distance which is occupied by spheres on all paths.
---@return Path
function Level:getMostDangerousPath()
	local distance = nil
	local mostDangerousPath = nil
	for i, path in ipairs(self.map.paths) do
		local d = path:getMaxOffset() / path.length
		if not distance or d > distance then
			distance = d
			mostDangerousPath = path
		end
	end
	return mostDangerousPath
end



---Returns a randomly selected path.
---@param notEmpty boolean? If set to `true`, this call will prioritize paths which are not empty.
---@param inDanger boolean? If set to `true`, this call will prioritize paths which are in danger.
---@return Path
function Level:getRandomPath(notEmpty, inDanger)
	-- Set up a pool of paths.
	local paths = self.map.paths
	local pool = {}
	for i, path in ipairs(paths) do
		-- Insert a path into the pool if it meets the criteria.
		if not (notEmpty and path:getEmpty()) and not (inDanger and not path:isInDanger()) then
			table.insert(pool, path)
		end
	end
	-- If any path meets the criteria, pick a random one.
	if #pool > 0 then
		return pool[math.random(#pool)]
	end
	-- Else, loosen the criteria.
	if inDanger then
		return self:getRandomPath(notEmpty, false)
	else
		return self:getRandomPath()
	end
end



---FORK-SPECIFIC CODE:
---Get the Target score values that changes depending on the Fruit and Spirit Animal.
---@return number[]
function Level:getTargetHitScoreValues()
    local currentScore = 3000
    local profile = _Game:getCurrentProfile()

    if profile:getFrogatarEffects().fruitValueModifier then
        currentScore = currentScore + profile:getFrogatarEffects().fruitValueModifier
    end
	if profile:getEquippedFoodItemEffects().fruitValueModifier then
		currentScore = currentScore + profile:getEquippedFoodItemEffects().fruitValueModifier
	end
	local useFilter = false
	local filterScore = 0
	local tbl = {}

	for _ = 1, 6 do
		table.insert(tbl, (useFilter and filterScore) or currentScore)
		useFilter = false
		currentScore = _MathRoundUp((currentScore + (currentScore * 0.5)), 25)
		local odd = tostring(currentScore):match("[27]5$")
		if odd == "25" then
			filterScore = currentScore + 25
			useFilter = true
		elseif odd == "75" then
			filterScore = currentScore - 25
			useFilter = true
		end
    end
	return tbl
end



---Increments the level's Blitz Meter by a given amount and launches the Hot Frog if reaches 1.
---@param amount any
---@param chain? boolean used for spirit turtle
function Level:incrementBlitzMeter(amount, chain)
	if not chain and self.blitzMeter == 1 then
		return
    end
	
	self.blitzMeter = math.min(self.blitzMeter + amount, 1)
    if (not chain and self.blitzMeter == 1) or (chain and self.blitzMeter >= 1) then
        -- hot frog
		local infernoFrog = _Game:getCurrentProfile():getEquippedPower("inferno_frog")
		local additiveAmount = (infernoFrog and infernoFrog:getCurrentLevelData().additiveAmount) or 0
        self.shooter:getMultiSphere(-2, (3 + additiveAmount))
		_Game:playSound("sound_events/hot_frog_activate.json")
		_Game:spawnParticle("particles/hf_blast.json", self.shooter.pos)
	end
end



---Returns `true` when there are no more spheres on the board and no more spheres can spawn, too.
---@return boolean
function Level:hasNoMoreSpheres()
	return self:areAllObjectivesReached() and not self.lost and self:getEmpty()
end



---Returns `true` if there are any shot spheres in this level, `false` otherwise.
---@return boolean
function Level:hasShotSpheres()
	return #self.shotSpheres > 0
end



---Returns `true` if the current level score is the highest in history for the current Profile.
---@return boolean
function Level:hasNewScoreRecord()
	return _Game:getCurrentProfile():getLevelHighscoreInfo(self.score)
end



---Returns `true` if there are any matches predicted (spheres that magnetize to each other), `false` otherwise.
---@return boolean
function Level:areMatchesPredicted()
	for i, path in ipairs(self.map.paths) do
		for j, chain in ipairs(path.sphereChains) do
			if chain:isMatchPredicted() then
				return true
			end
		end
	end
	return false
end



---Returns `true` if the level has been finished, i.e. there are no more spheres and no more collectibles.
---@return boolean
function Level:getFinish()
	return self:hasNoMoreSpheres() and #self.collectibles == 0
end



---Takes one life away from the current Profile, and either restarts this Level, or ends the game.
function Level:tryAgain()
	if _Game:getCurrentProfile():loseLevel() then
		_Game.uiManager:executeCallback("levelStart")
		self:reset()
	else
		_Game.session:terminate()
	end
end



---Starts the Level.
function Level:begin()
	self.started = true
	self.controlDelay = _Game.configManager.gameplay.level.controlDelay
	_Game:getMusic(self.musicName):reset()
end



---Resumes the Level after loading data.
function Level:beginLoad()
	self.started = true
	_Game:getMusic(self.musicName):reset()
	if not self.bonusDelay and not self.map.paths[self.bonusPathID] then
		self.wonDelay = _Game.configManager.gameplay.level.wonDelay
	end
end



---Saves the current progress on this Level.
function Level:save()
	_Game:getCurrentProfile():saveLevel(self:serialize())
end



---Erases saved data from this Level.
function Level:unsave()
	_Game:getCurrentProfile():unsaveLevel()
end



---Marks this level as completed and forgets its saved data.
-- Currently, the xp / coins will be granted after the close button is clicked, but later on this will happen when the win box pops up.
-- Grant some coins / xp that will be tweaked later

function Level:win()

	local xp_granted = 0 
	local coins_granted = 0

	-- only give xp / coins if the destroyed spheres is at least zero
	if self.destroyedSpheres > 0 then
		xp_granted = math.floor(((self.destroyedSpheres / 25)^0.4) * 200)
		coins_granted = math.floor(((self.destroyedSpheres / 70)^0.75) * 300)
	end

	_Game:getCurrentProfile():winLevel(self.score)
	_Game:getCurrentProfile():unsaveLevel()
	_Game:getCurrentProfile():grantCurrency(coins_granted)
	_Game:getCurrentProfile():grantXP(xp_granted)
	local cur_level = _Game:getCurrentProfile():getLevel()

	_Game:save()
end



---Uninitialization function. Uninitializes Level's elements which need deinitializing.
function Level:destroy()
	self.shooter:destroy()
	for i, shotSphere in ipairs(self.shotSpheres) do
		shotSphere:destroy()
	end
	for i, collectible in ipairs(self.collectibles) do
		collectible:destroy()
	end
	for i, path in ipairs(self.map.paths) do
		path:destroy()
    end
	if self.target then
		self.target:destroy()
    end
	if self.rollingSound then
		self.rollingSound:stop()
	end

	if self.ambientMusicName then
		local ambientMusic = _Game:getMusic(self.ambientMusicName)

		-- Stop any ambient music.
		ambientMusic:setVolume(0)
	end
end



---Resets the Level data.
function Level:reset()
	self.score = 0
	self.coins = 0
	self.gems = 0
	self.combo = 0
	self.destroyedSpheres = 0
	self.targets = 0
    self.time = 0
	self.stateCount = 0

	-- add in current speedbonus
	self.speedBonus = 0
	self.speedTimer = 0

    self.target = nil
	if _MathAreKeysInTable(self, "targetFrequency", "type") == "seconds" then
        self.targetSecondsCooldown = self.targetFrequency.initialDelay
		local fruitMaster = _Game:getCurrentProfile():getEquippedPower("fruit_master")
		if fruitMaster then
			self.targetSecondsCooldown = self.targetSecondsCooldown - fruitMaster:getCurrentLevelData().subtractiveSeconds
		end
	end

    self.blitzMeter = 0
	self.blitzMeterCooldown = 0
	self.shotLastHotFrogBall = false
    self.multiplier = 1
	-- TODO: Fix this unless this is the only way.
    -- For some stupid reason, _Game:getCurrentProfile() doesn't work here.
	-- Yet, the value that returns from that function works fine??
    local multiMultiplier = _Game.runtimeManager.profileManager:getCurrentProfile():getEquippedPower("multi_multiplier")
	if multiMultiplier then
		self.multiplier = self.multiplier + multiMultiplier:getCurrentLevelData().additiveAmount
	end

	self.spheresShot = 0
	self.sphereChainsSpawned = 0
	self.maxChain = 0
	self.maxCombo = 0

	self.shotSpheres = {}
	self.collectibles = {}
	self.floatingTexts = {}

	self.danger = false
	self.dangerSound = nil
	self.warningDelay = 0
	self.warningDelayMax = nil

	self.pause = false
	self.canPause = true
	self.started = false
	self.controlDelay = nil
	self.lost = false
	self.ended = false
	self.wonDelay = nil
	self.finish = false
	self.finishDelay = nil
	self.bonusPathID = 1
	self.bonusDelay = nil

	self.gameSpeed = 1
	self.gameSpeedTime = 0
	self.lightningStormTime = 0
	self.lightningStormCount = 0
	self.netTime = 0
	self.shooter.speedShotTime = 0
	_Game.session.colorManager:reset()

	-- other in-game statistics
	self.gapsNum = 0
	self.combosScore = 0
	self.gapsScore = 0
	self.speedScore = 0
	self.chainScore = 0
	self.combosNum = 0
	self.chainsNum = 0
	self.curveClearsScore = 0
	self.curveClearsNum = 0
	self.chronoBallsMatched = 0
	self.extraTimeAdded = 0
	self.fruitScore = 0
	self.fruitCollected = 0
	self.fruitSpawned = 0
	self.hotFrogStarts = 0
	self.ballsMissed = 0
	self.multipliersSpawned = 0
	self.chronoBallsSpawned = 0
	self.bombsSpawned = 0
	self.cannonsSpawned = 0
	self.colorNukesSpawned = 0
	self.hotFrogShots = 0
	self.bombsMatched = 0
	self.cannonsMatched = 0
	self.colorNukesMatched = 0
	self.hotFrogShotsFired = 0

	-- TODO
	self.spinnerSpawned = 0
	self.cannonsScore = 0
	self.wildShotScore = 0
	self.hotFrogScore = 0
	self.chainBlastsNum = 0
	self.chainBlastsScore = 0
	self.cannonConsolationScore = 0
	self.chronoBallsConsolationScore = 0
	self.spiritBlastScore = 0
	self.wildShotSpawned = 0
	self.spiritShotSpawned = 0
	self.spiritShotScore = 0
	self.colorNukesScore = 0
	self.spinnerMatched = 0
	self.lastHurrahScore = 0
	self.bombsScore = 0
	self.hotFrogConsolationScore = 0
	self.wildShotShots = 0

end



---Forfeits the level. The shooter is emptied, and spheres start rushing into the pyramid.
function Level:lose()
	if self.lost then return end
	self.lost = true
	-- empty the shooter
	self.shooter:empty()
	-- delete all shot balls
	for i, shotSphere in ipairs(self.shotSpheres) do
		shotSphere:destroy()
	end
	self.shotSpheres = {}
	self.rollingSound = _Game:playSound("sound_events/sphere_roll.json")
    _Game:playSound("sound_events/level_lose.json")
end



---Sets the pause flag for this Level.
---@param pause boolean Whether the level should be paused.
function Level:setPause(pause)
	if self.pause == pause or (not self.canPause and not self.pause) then return end
	self.pause = pause
end



---Inverts the pause flag for this Level.
function Level:togglePause()
	self:setPause(not self.pause)
end



---Spawns a new Shot Sphere into the level.
---@param shooter Shooter The shooter which has shot the sphere.
---@param pos Vector2 Where the Shot Sphere should be spawned at.
---@param angle number Which direction the Shot Sphere should be moving, in radians. 0 is up.
---@param color integer The sphere ID to be shot.
---@param speed number The sphere speed.
function Level:spawnShotSphere(shooter, pos, angle, color, speed)
	table.insert(self.shotSpheres, ShotSphere(nil, shooter, pos, angle, color, speed))
end



---Spawns a new Collectible into the Level.
---@param pos Vector2 Where the Collectible should be spawned at.
---@param name string The collectible ID.
function Level:spawnCollectible(pos, name)
	table.insert(self.collectibles, Collectible(nil, pos, name))
end



---Spawns a new FloatingText into the Level.
---@param text string The text to be displayed.
---@param pos Vector2 The starting position of this text.
---@param font string Path to the Font which is going to be used.
function Level:spawnFloatingText(text, pos, font)
	table.insert(self.floatingTexts, FloatingText(text, pos, font))
end



---Draws this Level and all its components.
function Level:draw()
	self.map:draw()
	self.shooter:drawSpeedShotBeam()
	self.map:drawSpheres()
	self.shooter:draw()

	for i, shotSphere in ipairs(self.shotSpheres) do
		shotSphere:draw()
	end
	for i, collectible in ipairs(self.collectibles) do
		collectible:draw()
	end
	for i, floatingText in ipairs(self.floatingTexts) do
		floatingText:draw()
    end
	if self.target then
		self.target:draw()
	end

	-- local p = posOnScreen(Vec2(20, 500))
	-- love.graphics.setColor(1, 1, 1)
	-- love.graphics.print(tostring(self.warningDelay) .. "\n" .. tostring(self.warningDelayMax), p.x, p.y)
end



---Stores all necessary data to save the level in order to load it again with exact same things on board.
---@return table
function Level:serialize()
	local t = {
		stats = {
			score = self.score,
			coins = self.coins,
			gems = self.gems,
			spheresShot = self.spheresShot,
            sphereChainsSpawned = self.sphereChainsSpawned,
			targets = self.targets,
			maxChain = self.maxChain,
			maxCombo = self.maxCombo
		},
        time = self.time,
        stateCount = self.stateCount,
		powerupList = self.powerupList,
		lastPowerupDeltas = self.lastPowerupDeltas,
        target = (self.target and self.target:serialize()),
		targetSprite = self.targetSprite,
        targetSecondsCooldown = self.targetSecondsCooldown,
        targetInitialDelaySecondsElapsed = self.targetInitialDelaySecondsElapsed,
        targetHitScore = self.targetHitScore,
		blitzMeter = self.blitzMeter,
        blitzMeterCooldown = self.blitzMeterCooldown,
		shotLastHotFrogBall = self.shotLastHotFrogBall,
		multiplier = self.multiplier,
		controlDelay = self.controlDelay,
		finish = self.finish,
		finishDelay = self.finishDelay,
		bonusPathID = self.bonusPathID,
		bonusDelay = self.bonusDelay,
		shooter = self.shooter:serialize(),
		shotSpheres = {},
		collectibles = {},
		combo = self.combo,
		lightningStormCount = self.lightningStormCount,
		lightningStormTime = self.lightningStormTime,
		destroyedSpheres = self.destroyedSpheres,
		paths = self.map:serialize(),
		lost = self.lost,
		speedBonus = self.speedBonus,
		speedTimer = self.speedTimer
	}
	for i, shotSphere in ipairs(self.shotSpheres) do
		table.insert(t.shotSpheres, shotSphere:serialize())
	end
	for i, collectible in ipairs(self.collectibles) do
		table.insert(t.collectibles, collectible:serialize())
	end
	return t
end


---Stores all ingame statistics to be submitted online.
function Level:saveStats()
	local s = {
		destroyedSpheres = self.destroyedSpheres,
		spheresShot = self.spheresShot,
		ProductName = "ZumaBlitzRemake",
		PlatformName = "Social",
		ClientVersion = "ZBR 0.1.1 alpha",
		MetricsType = "Gameplay",
		GapsNum = self.gapsNum,
		BallsClearedNum = self.destroyedSpheres,
		MultiplierMax = self.multiplier,
		XpEarned = (100 + self.targets + self.curveClearsNum + self.hotFrogStarts + self.chronoBallsMatched),
		ChainMax = self.maxCombo,
		SNSUserID = "aaa",
		XpStartingLevel = 80,
		FruitSpawned = self.fruitSpawned,
		NukesMatched = self.colorNukesMatched,
		CombosNum = self.combosNum,
		CombosScore = self.combosScore,
		WildShotScore = self.wildShotScore,
		CombosMax = self.maxChain,
		CannonsScore = self.cannonsScore,
		ChainNum = self.chainsNum,
		HotFrogScore = self.hotFrogScore,
		ChainScore = self.chainScore,
		ChainBlastsNum = self.chainBlastsNum,
		SpeedScore = self.speedScore,
		CurveClearsScore = self.curveClearsScore,
		CannonConsolationScore = self.cannonConsolationScore,
		TimePlayed = self.time,
		CurveClearsNum = self.curveClearsNum,
		MultipliersSpawned = self.multipliersSpawned,
		ChainBlastsScore = self.chainBlastsScore,
		ChronoBallsSpawned = self.chronoBallsSpawned,
		NukesSpawned = self.colorNukesSpawned,
		ChronoBallsMatched = self.chronoBallsMatched,
		BallsMissed = self.ballsMissed,
		ChronoBallsConsolationScore = self.chronoBallsConsolationScore,
		SpiritBlastScore = self.spiritBlastScore,
		HotFrogShots = self.hotFrogShotsFired,
		WildShotSpawned = self.wildShotSpawned,
		SpiritShotSpawned = self.spiritShotSpawned,
		FruitScore = self.fruitScore,
		MapName = "test",
		CoinStartingBalance = 7500000,
		SpinnerSpawned = self.spinnerSpawned,
		XpStarting = 500000,
		NukesScore = self.colorNukesScore,
		FrogatarID = "1",
		SpinnerMatched = self.spinnerMatched,
		LifeBankStartingNum = 0,
		SpiritShotScore = self.spiritShotScore,
		PowerupSlot3 = "0",
		PowerupSlot2 = "0",
		LastHurrahScore = self.lastHurrahScore,
		PowerupSlot1 = "0",
		FoodID = 0,
		Score = self.score,
		BombsSpawned = self.bombsSpawned,
		BombsMatched = self.bombsMatched,
		GameFinished = 1,
		BombsScore = self.bombsScore,
		GapsScore = self.gapsScore,
		CannonsSpawned = self.cannonsSpawned,
		HotFrogConsolationScore = self.hotFrogConsolationScore,
		CannonsMatched = self.cannonsMatched,
		HotFrogStarts = self.hotFrogStarts,
		WildShotShots = self.wildShotShots,
		FruitMatched = self.targets,
		ExtraTimeAdded = self.extraTimeAdded,
		RandomSeed = self.rngseed,
		LastPlayed = os.date("%Y-%m-%d %X")
	}
	-- set finished to 0 if the game was lost.
	if self.lost then
		s.GameFinished = 0
	end
	-- TODO: Set XP to zero if the game was aborted, and x2 if a potion was used.

	local post_body = json.encode(s)

	-- add http post request here

end


---Restores all data that was saved in the serialization method.
---@param t table The data to be deserialized.
function Level:deserialize(t)
	-- Prepare the counters
	_Game.session.colorManager:reset()

	-- Level stats
	self.score = t.stats.score
	self.coins = t.stats.coins
	self.gems = t.stats.gems
	self.spheresShot = t.stats.spheresShot
    self.sphereChainsSpawned = t.stats.sphereChainsSpawned
	self.targets = t.stats.targets
	self.maxChain = t.stats.maxChain
	self.maxCombo = t.stats.maxCombo
	self.combo = t.combo
	self.destroyedSpheres = t.destroyedSpheres
	self.time = t.time
    self.stateCount = t.stateCount
	self.powerupList = t.powerupList
    self.lastPowerupDeltas = t.lastPowerupDeltas
	self.targetSprite = t.targetSprite
	if t.target then
		self.target = Target(self.targetSprite, Vec2(t.target.pos.x, t.target.pos.y), false)
	end
    self.targetSecondsCooldown = t.targetSecondsCooldown
	self.targetHitScore = t.targetHitScore
	self.targetInitialDelaySecondsElapsed = t.targetInitialDelaySecondsElapsed
	self.blitzMeter = t.blitzMeter
	self.blitzMeterCooldown = t.blitzMeterCooldown
	self.shotLastHotFrogBall = t.shotLastHotFrogBall
	self.multiplier = t.multiplier
	self.lost = t.lost
	-- ingame counters
	self.speedBonus = t.speedBonus or 0
	self.speedTimer = t.speedTimer or 0
	-- Utils
	self.controlDelay = t.controlDelay
	self.finish = t.finish
	self.finishDelay = t.finishDelay
	self.bonusPathID = t.bonusPathID
	self.bonusDelay = t.bonusDelay
	-- Paths
	self.map:deserialize(t.paths)
	-- Shooter
	self.shooter:deserialize(t.shooter)
	-- Shot spheres, collectibles
	self.shotSpheres = {}
	for i, tShotSphere in ipairs(t.shotSpheres) do
		table.insert(self.shotSpheres, ShotSphere(tShotSphere))
	end
	self.collectibles = {}
	for i, tCollectible in ipairs(t.collectibles) do
		table.insert(self.collectibles, Collectible(tCollectible))
	end
	-- Effects
	self.lightningStormCount = t.lightningStormCount
	self.lightningStormTime = t.lightningStormTime

	-- Pause
	self:setPause(true)
	self:updateObjectives()
end



return Level
