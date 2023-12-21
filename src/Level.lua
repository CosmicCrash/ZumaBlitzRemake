local class = require "com.class"

---Represents a Level. Houses the Map, Shooters, Shot Spheres, Collectibles and Floating Texts. Handles elements such as level objectives and general level event order.
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
local Replay = require("src.Replay")

-- send stuff
local http = require("socket.http")
local ltn12 = require"ltn12"


---Constructs a new Level.
---@param data table The level data, specified in a level config file.
function Level:new(data)
	
	self.pending_action = 0

	-- Initalize replay
	self.replayCore = Replay()

	-- Initalize level parameters
	self.levelParameters = {}
	self:setLevelDefaultParameters()
	self.mapEffects = data.effects or {}

	-- Add the values from powers, fruit, spirit animals, and the like.
	self:addPowerEffects()

	self.level_colors = data.pathsBehavior[1].colors
    self.map = Map(self, "maps/" .. data.map, data.pathsBehavior)
    self.shooter = Shooter(data.shooter or self.map.shooter)

    -- FORK-SPECIFIC CHANGE: Change to frogatar, then spirit animal if any
    -- Yes this is the order and there should be an animation soon
	local frogatar = _Game:getCurrentProfile():getFrogatar()
	self.monument = _Game:getCurrentProfile():getActiveMonument()
	_Game.configManager.frogatars[frogatar]:changeTo(self)

	self.matchEffect = data.matchEffect or "match"

	local objectives = data.objectives

	-- if there are no objectives defined on the map, create one with timer = 60
	if objectives == nil then
		objectives = {{type = "timeSurvived", target = 60}}
	end
	self.objectives = {}

	-- account for extra time
	-- this might not work correctly if type is other than timeSurvived
	for i, objective in ipairs(objectives) do
		table.insert(self.objectives, {type = objective.type, target = objective.target + self:getParameter("extraStartingTime"), progress = 0, reached = false})
	end

	self.stateCount = 0

	self.colorGeneratorNormal = data.colorGeneratorNormal or "default"
	self.colorGeneratorDanger = data.colorGeneratorDanger or "default"

	self.musicName = data.music or "game3"
	self.dangerMusicName = data.dangerMusic or "danger2"
	self.ambientMusicName = data.ambientMusic

	self.dangerSoundName = data.dangerSound or "sound_events/warning.json"
	self.dangerLoopSoundName = data.dangerLoopSound or "sound_events/warning_loop.json"
	-- TODO: Resolve this ambiguity (use warmupLoopName and failLoopName, remove CC-exclusive rollingSound)
	-- Do this when the whole level pipeline is rebuilt in the base OpenSMCE
	self.warmupLoopName = data.warmupLoopSound or "sound_events/sphere_roll.json"
	self.failLoopName = data.failLoopSound or "sound_events/sphere_roll.json"
	self.rollingSound = nil

	-- Initalize random seed for ball generation
	self.rngseed = os.time()
	self.ball_rng = love.math.newRandomGenerator(self.rngseed)
	self.ball_rng_streak = love.math.newRandomGenerator(self.rngseed)
	self.next_ball_rng = love.math.newRandomGenerator(self.rngseed)
	self.powerup_rng = love.math.newRandomGenerator(self.rngseed)
	self.fruit_rng = love.math.newRandomGenerator(self.rngseed)
	self.powerup_position_rng = love.math.newRandomGenerator(self.rngseed)

	---@type Sprite
	self.targetSprite = _Game.configManager.targetSprites.random[self.fruit_rng:random(1, #_Game.configManager.targetSprites.random)]
	
	-- Additional variables come from this method!
	self:reset()
	self:resetGameStatistics()


	-- calculate fruit values
	self.targetHitScore = self:getParameter("fruitPointsBase")
	
	-- TODO: retrieve the game constants from server when POSTing start of game.

end

-- Change phase, setting all variables from skipping the intro.
-- Called from shooter.lua
function Level:changePhase()
	-- skip the sparkle phase 
	if self.phase == 3 then
		self.started = true
		self.phase = 4
		self.rollingSound = _Game:playSound(self.warmupLoopName)
	-- skip the food eating animation
	elseif self.phase == 2 then
		if self.foodSoundResource then
			self.foodSoundResource:stop()
			self.foodSoundResource = nil
		end
		self.foodDelay = -1
		self.phase = 3
	-- skip the spirit animal sequence
	elseif self.phase == 1 then
		if self.spiritAnimalTransformResource then
			self.spiritAnimalTransformResource:stop()
			self.spiritAnimalTransformResource = nil
		end
		self.spiritAnimalDelay = -1
		-- destroy all transformation particle effects
		if self.spiritAnimalTransformParticle1 then
			self.spiritAnimalTransformParticle1:destroy()
			self.spiritAnimalTransformParticle1 = nil
		end
		if self.spiritAnimalTransformParticle2 then
			self.spiritAnimalTransformParticle2:destroy()
			self.spiritAnimalTransformParticle2 = nil
		end
		-- transform if that was skipped
		if not self.spiritAnimalTransformed then
			_Game.configManager.frogatars[self.monument]:changeTo(self)
			self.spiritAnimalTransformed = true
		end

		self.phase = 2
	end
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

	self:updateMusic()
end



---Updates the Level's logic.
---@param dt number Delta time in seconds.
function Level:updateLogic(dt)
	-- Objectives
	self:updateObjectives()

	self.map:update(dt)
    self.shooter:update(dt)
    self.stateCount = self.stateCount + dt

	-- intro handling
	
	if self.phase == 1 then
		self.spiritAnimalDelay = self.spiritAnimalDelay - dt 

		if self.spiritAnimalDelay < 2.5 and not self.spiritAnimalTransformed then
			_Game.configManager.frogatars[self.monument]:changeTo(self)
			self.spiritAnimalTransformed = true
			self.spiritAnimalTransformParticle2 = _Game:spawnParticle("particles/spirit_release.json", self.shooter.pos)
		end

		if self.spiritAnimalDelay < 0 then
			self.map.level:spawnFloatingText(
				_Game:getCurrentProfile():getFrogatarInstance().transformText,
				Vec2(380, 236),
				"fonts/score0.json"
			)
			
			self.phase = 2
		end
	end

	if self.phase == 2 then
		if not _Game:getCurrentProfile():getEquippedFoodItem() or foodSprite == nil then 
			self.phase = 3
		else
			if self.foodSound == false then
				self.foodSoundResource = _Game:playSound("sound_events/food_eat.json")
				self.foodSound = true	
			end
			self.foodDelay = self.foodDelay - dt
			
			if self.foodDelay < 0 then
				self.phase = 3
			end

		end
		
	end

	-- draw the intro sparkle trail
	-- More than one particle per frame is drawn for faster speeds
	-- TODO: Adjust trail to cover the entire board in x seconds, add sounds

	if self.phase == 3 then
		local path = self.map.paths[self.drawCurve]
		local pos = path:getPos(self.drawOffset)
		self.drawOffset = self.drawOffset + 6
		_Game:spawnParticle("particles/sparkle.json", pos)
		self.drawOffset = self.drawOffset + 6
		pos = path:getPos(self.drawOffset)
		_Game:spawnParticle("particles/sparkle.json", pos)
		if self.drawOffset > path.length then
			self.drawCurve = self.drawCurve + 1
			self.drawOffset = 0
		end
		
		if self.drawCurve > self.curveCount then
			self.phase = 4
			self.started = true
			self.rollingSound = _Game:playSound(self.warmupLoopName)
		end

	end
		
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

	-- If there is a pending action (signaled from game.lua) execute it and set to zero
	
	if (self.pending_action and not self.replayCore.replay_loaded) then
		if self.pending_action == 1 then
			self.shooter:shoot()
		elseif self.pending_action == 2 then
			self.shooter:swapColors()
		end
		self.pending_action = 0
	end

	-- REPLAY
	-- if the current time is greater than the replay data current line, advance and line and... shoot

	local replay_angle, replay_button = self.replayCore:advance(self.time)
	if (replay_angle) then
		self.shooter:setAngle(replay_angle)
	end
	if (replay_button) then
		if replay_button == 1 then
			self.shooter:shoot()
		elseif replay_button == 2 then
			self.shooter:swapColors()
		end
	end

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
			self:destroyNetParticle()
		end
	end



	-- Time counting
	if self.started and self.phase == 4 and not self:getFinish() and not self.finish and not self.lost then
		self.time = self.time + dt
    end



    -- Hot Frog handling
	if self.started and not self:getFinish() and not self.finish and not self.lost then
		if self.blitzMeter == 1 then
			-- We're in hot frog mode, reset once the shooter has a ball other than the fireball.
			if self.shooter.color > 0 then
				self.shotLastHotFrogBall = true
				self.blitzMeter = 0
                self.blitzMeterCooldown = 0
			end
        else
			self.shotLastHotFrogBall = false
			if self.blitzMeterCooldown == 0 and self.blitzMeter > 0 then
				self.blitzMeter = math.min(math.max(self.blitzMeter - (self:getParameter("hotFrogDecayPerSecond") / self:getParameter("hotFrogGoal") * dt), 0),0.99)
			else
				self.blitzMeterCooldown = math.max(self.blitzMeterCooldown - dt, 0)
			end
		end
    end


-- todo - get # of balls with a certain attribute

	-- Zuma Blitz style powerups
    if self.started and not self.finish and not self:areAllObjectivesReached() and not self:getEmpty() then

		-- timer will tick down even if the powerup isn't active, but needs to be active for it to spawn
		self.multiplierCooldown = self.multiplierCooldown - dt
		self.timeballCooldown = self.timeballCooldown - dt
		self.bombsCooldown = self.bombsCooldown - dt
		self.cannonCooldown = self.cannonCooldown - dt
		self.colorNukeCooldown = self.colorNukeCooldown - dt
		local multiplierCap = self:getParameter("multiplierMaximum") 
		
		if self.multiplierCooldown <= 0 and self.multiplier < multiplierCap and self:getParameter("multiplierBallsEnabled") > 0 then
			self.multipliersSpawned = self.multipliersSpawned + 1
			self.multiplierCooldown = self:getParameter("multiplierFrequencyBase") + self.multipliersMatched + (self.powerup_rng:random() * self:getParameter("multiplierFrequencyRange"))
			self:addPowerup("multiplier", self:getParameter("multiplierLifetime"))
		end
		if self.timeballCooldown <= 0 and self:getParameter("timeBallsEnabled") > 0 then
			self.chronoBallsSpawned = self.chronoBallsSpawned + 1
			self.timeballCooldown = self:getParameter("timeBallsFrequencyBase") + (self.powerup_rng:random() * (self:getParameter("timeBallsFrequencyRange") + math.min(self.time * self:getParameter("timeBallsFreqIncreasePerSecond") , self:getParameter("timeBallsFrequencyRangeMax") )) )
			self:addPowerup("timeball", self:getParameter("timeBallsLifetime"))
		end
		if self.bombsCooldown <= 0 and self:getParameter("bombsEnabled") > 0 then
			self.bombsSpawned = self.bombsSpawned + 1
			self.bombsCooldown = self:getParameter("bombsFrequencyBase") + (self.powerup_rng:random() * self:getParameter("bombsFrequencyRange"))
			self:addPowerup("bombs", self:getParameter("bombsLifetime"))
		end
		if self.cannonCooldown <= 0 and self:getParameter("cannonsEnabled") > 0 then
			self.cannonsSpawned = self.cannonsSpawned + 1
			self.cannonCooldown = self:getParameter("cannonsFrequencyBase") + (self.powerup_rng:random() * self:getParameter("cannonsFrequencyRange"))
			self:addPowerup("cannons", self:getParameter("cannonsLifetime"))
		end
		if self.colorNukeCooldown <= 0 and self:getParameter("colorNukeEnabled") > 0 then
			self.colorNukesSpawned = self.colorNukesSpawned + 1
			self.colorNukeCooldown = self:getParameter("colorNukeFrequencyBase") + (self.powerup_rng:random() * self:getParameter("colorNukeFrequencyRange"))
			self:addPowerup("colornuke", self:getParameter("colorNukeLifetime"))
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
		if not self.target and (self.map.targetPoints) then
            local validPoints = {}
				self.targetSecondsCooldown = self.targetSecondsCooldown - dt
				if self.targetSecondsCooldown < 0 then
					for i, point in ipairs(self.map.targetPoints) do
						for j, path in ipairs(self.map.paths) do
							local d = path:getMaxOffset() / path.length
							if d > point.distance then
								table.insert(validPoints, Vec2(point.pos.x, point.pos.y))
							end
						end
					end
				end
			if #validPoints > 0 then
				self.target = Target(
					self.targetSprite,
					validPoints[self.fruit_rng:random(1, #validPoints)],
					false -- no slot machine yet!
                )
				_Game:playSound("sound_events/target_spawn.json")
				self.fruitSpawned = self.fruitSpawned + 1 
			end
		elseif self.target then
			-- don't tick the timer down if there's fruit present
			-- if cooldown is already established do not do it again.
			if self.targetSecondsCooldown <= 0 then 
           		self.targetSecondsCooldown = self:getParameter("fruitFrequency") + (self.fruit_rng:random() * self:getParameter("fruitFrequencyRange"))
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
		-- FORK-SPECIFIC CODE: Add a highscore after the board
		_Game:getCurrentProfile():writeHighscore()
		_Game.uiManager:executeCallback("levelComplete")
		self.ended = true
		self:saveStats()
	end

	-- Other variables, such as the speed timer
	-- timer will not tick down when under hot frog.
	if self.speedTimer > 0 and self.blitzMeter < 1 then
		self.speedTimer = self.speedTimer - dt
	end

end

--- Add powerup, default 20 seconds if not defined
--- Only spawn if duration is positive

function Level:addPowerup(name, duration)
	if duration == nil then duration = 20 end
	local position = self.powerup_position_rng:random(1,65536)
	local sphere = _Game.session:getRandomSphere(position)
	if sphere and duration > 0 then
		sphere:addPowerup(name, nil, duration)
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


---Adds one sphere to the destroyed sphere counter.
function Level:destroySphere()
	if self.lost then
		return
	end

	self.destroyedSpheres = self.destroyedSpheres + 1
end



---Adds one to the successful shot counter, which is used to calculate accuracy.
function Level:markSuccessfulShot()
	self.successfulShots = self.successfulShots + 1
end



---Returns the percentage of shot spheres which have successfully landed.
---@return number
function Level:getShotAccuracy()
	if self.spheresShot == 0 then
		return 1
	end
	return self.successfulShots / self.spheresShot
end



---Adds one to the successful shot counter, which is used to calculate accuracy.
function Level:markSuccessfulShot()
	self.successfulShots = self.successfulShots + 1
end



---Returns the percentage of shot spheres which have successfully landed.
---@return number
function Level:getShotAccuracy()
	if self.spheresShot == 0 then
		return 1
	end
	return self.successfulShots / self.spheresShot
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
		self:spawnNetParticle()
	elseif effect.type == "changeGameSpeed" then
		self.gameSpeed = effect.speed
		self.gameSpeedTime = effect.duration
	elseif effect.type == "setCombo" then
		self.combo = effect.combo
	elseif effect.type == "grantScore" then
		self:grantScore(effect.score)
		self:spawnFloatingText(_NumStr(effect.score), TMP_pos, "fonts/score0.json")
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

---Generates a new color for the Shooter, based on the colors on the level.
---@return integer
function Level:getNewShooterColor()
	-- Make a pool with colors which are on the board.
	local pool = {}
	for i, color in ipairs(self.level_colors) do
		table.insert(pool, color)
		--if not data.hasToExist or _Game.session.colorManager:isColorExistent(color) then
		--	table.insert(pool, color)
		--end
	end
	-- Return a random item from the pool.
	if #pool > 0 then
		print("new item")
		return pool[self.next_ball_rng:random(#pool)]
	end

	-- Else, return a fallback value.
	return 0
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
    local currentScore = self:getParameter("fruitPointsBase")
	local useFilter = false
	local filterScore = 0
	local tbl = {}

	for _ = 1, 6 do
		table.insert(tbl, (useFilter and filterScore) or currentScore)
		useFilter = false
		currentScore = _Utils.roundUp((currentScore + (currentScore * 0.5)), 25)
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

	-- Use the values of goal and match value instead
	amount = self:getParameter("hotFrogMatchValue") / self:getParameter("hotFrogGoal")

	-- If hot frog is not enabled, then matching will go no further than 99% of the meter
	if self:getParameter("hotFrogEnabled") == 0 then
		self.blitzMeter = math.min(self.blitzMeter + amount, 0.99)
	end

	self.blitzMeter = math.min(self.blitzMeter + amount, 1)
    if (not chain and self.blitzMeter == 1) or (chain and self.blitzMeter >= 1) then
        -- hot frog
		-- minimum hot frog shots is 1 otherwise graphics won't work properly
		local additiveAmount = math.max(self:getParameter("hotFrogShots"), 1)
        self.shooter:getMultiSphere(-2, (additiveAmount))
		_Game:playSound("sound_events/hot_frog_activate.json")
		_Game:spawnParticle("particles/hf_blast.json", self.shooter.pos)
		self.hotFrogStarts = self.hotFrogStarts + 1
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

---Starts the Level. 
function Level:begin()
	self.phase = 3

	if self.monument then
		self.spiritAnimalTransformParticle1 = _Game:spawnParticle("particles/spirit_absorb.json", self.shooter.pos)
		local transformSound = _Game:getCurrentProfile():getFrogatarInstance().transformSound
		if transformSound then
			self.spiritAnimalTransformResource = _Game:playSound(transformSound)
		end
		self.phase = 1
	elseif _Game:getCurrentProfile():getEquippedFoodItem() then
		-- TBD: Food Animation
		self.phase = 2
	end

	-- get path information
	self.curveCount = #self.map.paths

	_Game:getMusic(self.musicName):reset()
	if self.warmupLoopName then
		self.warmupLoop = _Game:playSound(self.warmupLoopName)
	end
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
	self:destroyNetParticle()
	if self.target then
		self.target:destroy()
    end

	if self.ambientMusicName then
		local ambientMusic = _Game:getMusic(self.ambientMusicName)

		-- Stop any ambient music.
		ambientMusic:setVolume(0)
	end

	if self.warmupLoop then
		self.warmupLoop:stop()
	end
	if self.failLoop then
		self.failLoop:stop()
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
	self.speedBonusIncrement = 0
	self.speedTimer = 0

    self.target = nil
	self.targetSecondsCooldown = self:getParameter("fruitFrequency") + (self.fruit_rng:random() * self:getParameter("fruitFrequencyRange"))
	self.multiplierCooldown = self:getParameter("multiplierFrequencyBase") + (self.powerup_rng:random() * self:getParameter("multiplierFrequencyRange"))
	self.timeballCooldown = self:getParameter("timeBallsFrequencyBase") + (self.powerup_rng:random() * self:getParameter("timeBallsFrequencyRange"))
	self.bombsCooldown = self:getParameter("bombsFrequencyBase") + (self.powerup_rng:random() * self:getParameter("bombsFrequencyRange"))
	self.cannonCooldown = self:getParameter("cannonsFrequencyBase") + (self.powerup_rng:random() * self:getParameter("cannonsFrequencyRange"))
	self.colorNukeCooldown = self:getParameter("colorNukeFrequencyBase") + (self.powerup_rng:random() * self:getParameter("colorNukeFrequencyRange"))

    self.blitzMeter = 0
	self.blitzMeterCooldown = 0
	self.shotLastHotFrogBall = false
    self.multiplier = self:getParameter("multiplierStarting")

	self.spheresShot = 0
	self.successfulShots = 0
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
	-- phase to control level before and after level sequencing 
	-- 1 = spirit animal, 2 = food, 3 = sparkle, 4 = regular game, 5 = spirit animal ending, 6 = last hurrah
	-- 1-3 can be skipped via mouse click
	self.phase = 0
	self.drawOffset = 0
	self.drawCurve = 1
	self.curveCount = 1
	self.spiritAnimalDelay = 3.5
	self.spiritAnimalTransformResource = nil
	self.spiritAnimalTransformParticle1 = nil
	self.spiritAnimalTransformParticle2 = nil
	self.spiritAnimalTransformed = false
	self.foodDelay = 5
	self.foodSound = false
	self.foodSoundResource = nil
	if _Game:getCurrentProfile():getEquippedFoodItem() then
		self.foodSprite = _Game:getCurrentProfile():getEquippedFoodItem().sprite or " "
		self.displayEffects = " "
		self.foodLabel = _Game:getCurrentProfile():getEquippedFoodItem().displayEffects or " "
	end
	self.foodLabelDrawn = false
	
    self.foodShader = love.graphics.newShader [[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
                // a discarded pixel wont be applied as the stencil.
                discard;
            }
            return vec4(1.0);
        }
    ]]

	self.lost = false
	self.ended = false
	self.wonDelay = nil
	self.finish = false
	self.finishDelay = nil
	self.bonusPathID = 1
	self.bonusDelay = nil
	self.introductionPathID = nil

	self.gameSpeed = 1
	self.gameSpeedTime = 0
	self.lightningStormTime = 0
	self.lightningStormCount = 0
	self.netTime = 0
	self:destroyNetParticle()

	self.shooter.speedShotTime = 0
	_Game.session.colorManager:reset()


	-- Set game constants here. 

end

	-- other in-game statistics

function Level:resetGameStatistics()

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
	self.multipliersMatched = 0
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

-- set level scoring constants
-- We convert 32 to 29px (TODO)
function Level:setLevelDefaultParameters()
	self.levelParameters["shotSpeedBase"] = 0
	self.levelParameters["shotSpeedMultiplier"] = 1
	self.levelParameters["speedUpShotsTotalIncrease"] = 0
	self.levelParameters["bombsExplosionRadius"] = 107
	self.levelParameters["bombsFrequencyBase"] = 7
	self.levelParameters["bombsFrequencyRange"] = 3
	self.levelParameters["bombsLifetime"] = 21
	self.levelParameters["bombsMaxBalls"] = -1
	self.levelParameters["bombsBasePoints"] = 0
	self.levelParameters["bombsEachPoints"] = 10
	self.levelParameters["bombsMultPoints"] = 1
	self.levelParameters["bombsEffectiveBallExponent"] = 1
	self.levelParameters["cannonsFrequencyBase"] = 7
	self.levelParameters["cannonsFrequencyRange"] = 3
	self.levelParameters["cannonsLifetime"] = 21
	self.levelParameters["cannonsPointsBase"] = 10
	self.levelParameters["cannonsPointsMultiplier"] = 1
	self.levelParameters["cannonsSpread"] = 2
	self.levelParameters["cannonsMaxBalls"] = -1
	self.levelParameters["cannonsSpreadSpread"] = 15
	self.levelParameters["chainBlastEnabled"] = 0
	self.levelParameters["chainBlastExplosionRadius"] = 107
	self.levelParameters["chainBlastIncrement"] = 5
	self.levelParameters["chainBlastMinimum"] = 10
	self.levelParameters["chainBlastScoreBase"] = 0
	self.levelParameters["chainBlastScoreEach"] = 10
	self.levelParameters["chainBlastScoreMult"] = 1
	self.levelParameters["chainBlastEffectiveBallExponent"] = 1
	self.levelParameters["frogatar"] = 1
	self.levelParameters["multiplierMaximum"] = 9
	self.levelParameters["multiplierStarting"] = 1
	self.levelParameters["extraStartingTime"] = 0
	self.levelParameters["xpMultiplier"] = 1
	self.levelParameters["coinsMultiplier"] = 1
	self.levelParameters["matchPointsBase"] = 10
	self.levelParameters["fruitFrequency"] = 12
	self.levelParameters["fruitFrequencyRange"] = 5
	self.levelParameters["fruitLifetime"] = 10
	self.levelParameters["fruitPointsBase"] = 3000
	self.levelParameters["fruitPointsMultiplier"] = 1
	self.levelParameters["fruitRadius"] = 24
	self.levelParameters["fruitTicksAdded"] = 0
	self.levelParameters["fruitFactor"] = 0.5
	self.levelParameters["fruitCap"] = 5
	self.levelParameters["fruitRoundingValue"] = 50
	self.levelParameters["hotFrogEnabled"] = 1
	self.levelParameters["hotFrogShots"] = 3
	self.levelParameters["hotFrogRadius"] = 112
	self.levelParameters["hotFrogPointsBase"] = 1000
	self.levelParameters["hotFrogPointsInc"] = 100
	self.levelParameters["hotFrogDecayPerSecond"] = 600
	self.levelParameters["hotFrogMatchValue"] = 1000
	self.levelParameters["hotFrogGoal"] = 18000
	self.levelParameters["hotFrogFruitInc"] = 1
	self.levelParameters["hotFrogExplosionInc"] = 1
	self.levelParameters["hotFrogDelaySeconds"] = 0.5
	self.levelParameters["hotFrogComboBreaker"] = 0
	self.levelParameters["hotFrogJackpotInc"] = 500
	self.levelParameters["hotFrogGoalInc"] = 0
	self.levelParameters["hotFrogGoalCap"] = 0
	self.levelParameters["hotFrogGapInc"] = 0
	self.levelParameters["hotFrogShotSpeed"] = 20
	self.levelParameters["hotFrogEffectiveBallExponent"] = 1
	self.levelParameters["lastHurrahMultiplier"] = 1
	self.levelParameters["lastHurrahRadius"] = 112
	self.levelParameters["lastHurrahPointBase"] = 1000
	self.levelParameters["lastHurrahPointInc"] = 100
	self.levelParameters["spiritShotThreshold"] = 13
	self.levelParameters["spiritShotRadius"] = 112
	self.levelParameters["spiritShotPointsBase"] = 10
	self.levelParameters["spiritShotPointsEach"] = 10
	self.levelParameters["spiritShotPointsMult"] = 1
	self.levelParameters["spiritShotEffectiveBallExponent"] = 1
	self.levelParameters["multiplierBallsEnabled"] = 1
	self.levelParameters["multiplierBallsEnabled"] = 1
	self.levelParameters["multiplierFrequencyBase"] = 5
	self.levelParameters["multiplierFrequencyRange"] = 14
	self.levelParameters["multiplierLifetime"] = 21
	self.levelParameters["multiplierMaxBalls"] = -1
	self.levelParameters["spiritBlastPointsBase"] = 0
	self.levelParameters["spiritBlastPointsIncrement"] = 0
	self.levelParameters["spiritBlastEnabled"] = 0
	self.levelParameters["spiritBlastColor"] = 0
	self.levelParameters["timeBallsEnabled"] = 1
	self.levelParameters["timeBallsFrequencyBase"] = 8
	self.levelParameters["timeBallsFrequencyRange"] = 5
	self.levelParameters["timeBallsFreqIncreasePerSecond"] = 0
	self.levelParameters["timeBallsFrequencyRangeMax"] = 0
	self.levelParameters["timeBallsLifetime"] = 21
	self.levelParameters["timeBallsTimeBonus"] = 5
	self.levelParameters["timeBallsMaxBalls"] = -1
	self.levelParameters["chainBonusChainMin"] = 6
	self.levelParameters["chainBonusPointsInc"] = 10
	self.levelParameters["chainBonusPointsBase"] = 100
	self.levelParameters["chainBonusJackpotPoints"] = 500
	self.levelParameters["chainBonusJackpotEachPoints"] = 250
	self.levelParameters["chainBonusJackpotEach"] = 5
	self.levelParameters["chainBonusJackpotStart"] = 10
	self.levelParameters["curveSpeedFactor"] = 1
	self.levelParameters["curveIncreasePctPerSecond"] = 0
	self.levelParameters["curveMaxSingleAdj"] = 0
	self.levelParameters["curveMaxClumpAdj"] = 0
	self.levelParameters["curveMatchPercentAdj"] = 0
	self.levelParameters["gapPointsRounding"] = 10
	self.levelParameters["gapPointMin"] = 50
	self.levelParameters["gapGapMax"] = 300
	self.levelParameters["gapPointsBase"] = 10000
	self.levelParameters["gapMultSingle"] = 1
	self.levelParameters["gapMultDouble"] = 2
	self.levelParameters["gapMultTriple"] = 3
	self.levelParameters["gapMinAdjustment"] = 0
	self.levelParameters["speedBonusPointsBase"] = 10
	self.levelParameters["speedBonusMaxMult"] = 12
	self.levelParameters["speedBonusTimeBase"] = 2.75
	self.levelParameters["wildBallEnabled"] = 0
	self.levelParameters["wildBallThreshold"] = 15
	self.levelParameters["wildBallPointsBase"] = 20
	self.levelParameters["powerballDurationModifier"] = 1
	self.levelParameters["powerballGraceFrames"] = 100
	self.levelParameters["treasureSpawnMax"] = 2
	self.levelParameters["treasureEnabled"] = 1
	self.levelParameters["treasurePercentChance"] = 2
	self.levelParameters["colorNukeMaxBalls"] = -1
	self.levelParameters["colorNukeEnabled"] = 0
	self.levelParameters["colorNukeLifetime"] = 16
	self.levelParameters["colorNukeFrequencyRange"] = 5
	self.levelParameters["colorNukePointsMultiplier"] = 1
	self.levelParameters["colorNukePointsBase"] = 50
	self.levelParameters["colorNukeFrequencyBase"] = 12
	self.levelParameters["colorNukeCurveCount"] = 1
	self.levelParameters["colorNukeLifetimeRange"] = 0
	self.levelParameters["colorNukePointsEach"] = 10
	self.levelParameters["comboBonusPointsBase"] = 1000
	self.levelParameters["curveClearTicksAdded"] = 0
	self.levelParameters["curveClearPointsBase"] = 1000
end

function Level:addPowerEffects()
	
	local mapEffects = self.mapEffects

	for k, v in pairs(mapEffects) do
		self:setParameter(k, mapEffects[k])
	end

	local fruitEffects = _Game:getCurrentProfile():getEquippedFoodItemEffects()

	for k, v in pairs(fruitEffects) do
		self:setParameterAdd(k, fruitEffects[k])
	end

	local frogatarEffects = _Game:getCurrentProfile():getFrogatarEffects()

    for k, v in pairs(frogatarEffects) do
		self:setParameterAdd(k, frogatarEffects[k])
	end
	
	--load effects from all powers
	
	for i, power in ipairs(_Game:getCurrentProfile().equippedPowers) do
		if _Game:getCurrentProfile().powerCatalog[power] == nil then
			print("WARNING: " .. power .. " does not exist in powerCatalog")
		else
			local power_level = _Game:getCurrentProfile().powerCatalog[power].level

			local power_effects = _Game:getCurrentProfile():getEquippedPower(power):getEffects(power_level) or {}

			if power_effects ~= nil then
				for k, v in pairs(power_effects) do
					self:setParameterAdd(k, power_effects[k])
				end
			end
		end

	end

end


function Level:getParameter(parameter)
	return self.levelParameters[parameter] or 0

end

-- set parameter used for boolean items
function Level:setParameter(parameter, value)
	if self.levelParameters[parameter] == nil then self.levelParameters[parameter] = parameter end
	self.levelParameters[parameter] = value
end

-- set parameter stacking additively, for setting values of powers and such
-- If the value does not exist, this will be set to whatever value is
function Level:setParameterAdd(parameter, value)	
	if self.levelParameters[parameter] == nil then 
		self.levelParameters[parameter] = value
	else
		self.levelParameters[parameter] = self.levelParameters[parameter] + value
	end
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
    _Game:playSound("sound_events/level_lose.json")
	if self.failLoopName then
		self.failLoop = _Game:playSound(self.failLoopName)
	end
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
---@param size number The diameter of the Shot Sphere, in pixels.
---@param color integer The sphere ID to be shot.
---@param speed number The sphere speed.
function Level:spawnShotSphere(shooter, pos, angle, size, color, speed)
	table.insert(self.shotSpheres, ShotSphere(nil, shooter, pos, angle, size, color, speed))
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



---Spawns the Net particle, if it doesn't exist yet.
function Level:spawnNetParticle()
	if self.netParticle then
		return
	end
	local netConfig = _Game.configManager.gameplay.net
	self.netParticle = _Game:spawnParticle(netConfig.particle, Vec2(_Game:getNativeResolution().x / 2, netConfig.posY))
end



---Despawns the Net particle, if it exists.
function Level:destroyNetParticle()
	if not self.netParticle then
		return
	end
	self.netParticle:destroy()
	self.netParticle = nil
end



---Draws this Level and all its components.
function Level:draw()
	self.map:draw()
	self.shooter:drawSpeedShotBeam()
	self.map:drawSpheres()
	self.shooter:draw()

	if self.phase == 1 then
		self.shooter:drawSpiritTransformation(self.shooter.pos, self.spiritAnimalDelay)
	end

	-- draw the food portion with the shooter, since it's positioned relative to it
	if self.phase == 2 then
		local food_sprite_pos = self.shooter.pos
		local food_sprite_offset = {x = -50, y = 80}
		
		-- draw from y = 300 to y = position within one second.
		-- TODO: Start from the top if the frog is too far down that the food doesn't show.
		local timer_offset = {x = 0, y = math.max((self.foodDelay-4)*300,0) }
		food_sprite_pos = food_sprite_pos + food_sprite_offset + timer_offset
		
		if self.foodDelay < 3.2 then
			love.graphics.stencil(function()
				love.graphics.setShader(self.foodShader)
				local eat_mask1 = _Game.resourceManager:getSprite("sprites/food_items/eating_mask_1.json")
				local eat_mask2 = _Game.resourceManager:getSprite("sprites/food_items/eating_mask_2.json")

				if self.foodDelay >= 2.4 then			
					eat_mask1:draw(food_sprite_pos)
				end

				if self.foodDelay < 2.4 then			
					eat_mask2:draw(food_sprite_pos)
				end
			
				love.graphics.setShader()
			end, "replace", 1)
			love.graphics.setStencilTest("greater", 0)
		end

		local sprite2 = _Game.resourceManager:getSprite(self.foodSprite)
		
		if self.foodDelay > 2.1 then
			if sprite2 then sprite2:draw(food_sprite_pos) end
		end
		
		local food_sprite_pos_label = food_sprite_pos
		food_sprite_pos_label.y = food_sprite_pos_label.y + 50
		food_sprite_pos_label.x = food_sprite_pos_label.x + 50

		if self.foodDelay < 2.1 and not self.foodLabelDrawn then
			self:spawnFloatingText(self.foodLabel, food_sprite_pos, "fonts/score0.json")
			self.foodLabelDrawn = true
		end

		love.graphics.setStencilTest()
		
		-- code to counter the offset being preserved next draw, remove when it gets fixed
		food_sprite_pos = food_sprite_pos - food_sprite_offset - timer_offset
	end

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
			successfulShots = self.successfulShots,
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
        targetHitScore = self.targetHitScore,
		blitzMeter = self.blitzMeter,
        blitzMeterCooldown = self.blitzMeterCooldown,
		shotLastHotFrogBall = self.shotLastHotFrogBall,
		multiplier = self.multiplier,
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
		netTime = self.netTime,
		destroyedSpheres = self.destroyedSpheres,
		paths = self.map:serialize(),
		lost = self.lost,
		speedBonus = self.speedBonus,
		speedBonus = self.speedBonusIncrement,
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
	local currentProfile = _Game:getCurrentProfile()
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
		SNSUserID = currentProfile:getPlayerID(),
		XpStartingLevel = math.floor(currentProfile:getLevel()),
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
		CoinStartingBalance = currentProfile:getCurrency(),
		SpinnerSpawned = self.spinnerSpawned,
		XpStarting = currentProfile.xp,
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

	for k, v in pairs(s) do print(k, v) end
	local post_body = json.encode(s)
	print(post_body)


	if self.replayCore.replay_loaded then
		_Debug.console:print(self.score)
		_TimeScale = 1
	else
		local filename_save = "replay_" .. os.date("%Y%m%d_%H%M%S") .. "_" .. self.score .. ".txt"
		_Utils.saveFile(filename_save, self.replayCore:save())
		_Utils.saveJson("stats.json", s)
		_Utils.saveJson("level_parameters.json", self.levelParameters)
	end
	

	-- add http post request here

end


---Restores all data that was saved in the serialization method.
---@param t table The data to be deserialized.
function Level:deserialize(t)
	-- Prepare the counters
	_Game.session.colorManager:reset()

	-- Re-create the scoring default parameters (instead of storing it on the savefile).
	self:setLevelDefaultParameters()

	-- Level stats
	self.score = t.stats.score
	self.coins = t.stats.coins
	self.gems = t.stats.gems
	self.spheresShot = t.stats.spheresShot
	self.successfulShots = t.stats.successfulShots
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
	self.blitzMeter = t.blitzMeter
	self.blitzMeterCooldown = t.blitzMeterCooldown
	self.shotLastHotFrogBall = t.shotLastHotFrogBall
	self.multiplier = t.multiplier
	self.lost = t.lost
	-- ingame counters
	self.speedBonus = t.speedBonus or 0
	self.speedBonusIncrement = t.speedBonusIncrement or 0
	self.speedTimer = t.speedTimer or 0
	-- Utils
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
	self.netTime = t.netTime
	if self.netTime > 0 then
		self:spawnNetParticle()
	end

	-- Pause
	self:setPause(true)
	self:updateObjectives()
end

function Level:recordFiredBall(angle)
	self.replayCore:record(self.time, angle, 1)
end

function Level:recordSwap()
	self.replayCore:record(self.time, nil, 2)

end


return Level
