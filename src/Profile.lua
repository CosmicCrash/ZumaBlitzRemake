local class = require "com.class"

---Represents a single Profile.
---@class Profile
---@overload fun(data, name):Profile
local Profile = class:derive("Profile")



---Constructs a Profile.
---@param data table? Data to be deserialized, if any.
---@param name string The profile name.
function Profile:new(data, name)
	self.name = name

	-- unique identifier used in score submissions and cloud data.
	self.uniqueid = math.random(1,4294967295)
	self.is_local = true
	self.is_discord_user = false -- also used to determine whether to display the discord friends leaderboard and other things.

	-- progression data saved in the server or locally.
	self.xplevel = 1
	self.xp = 0
	self.currency = 0

	-- initalize player data. If online account, data will be loaded from cloud instead.
	-- TODO: Consider extracting this variable and associated functions to ProfileSession.lua
	self.session = nil
	self.levels = {}
	self.checkpoints = {}
	self.variables = {}
	self.frogatar = "basic"
	self.monument = nil
    self.equippedPowers = {}
    self.powerCatalog = {}
	self.equippedFood = nil
    self.foodInventory = {}

	if data then
		self:deserialize(data)
	else
		for i, checkpoint in ipairs(_Game.configManager.levelSet.startCheckpoints) do
			self.checkpoints[i] = checkpoint
        end
		for power, v in pairs(_Game.configManager.powers) do
            self.powerCatalog[power] = {
                level = 1,
				amount = 0 -- if this is 0 then pay up
			}
		end
	end
end



-- Core stuff

---Returns the player's session data. This does NOT return a Session instance; they are separate entities.
---@return table
function Profile:getSession()
	return self.session
end



---Returns the player's current level data. This is the raw level data which is written in `config/levels/level_*.json`.
---@return table
function Profile:getLevelData()
	return _Game.configManager.levels[self:getLevelID()]
end



---Returns the player's current level's map data. This is the raw map data which is written in `maps/*/config.json`.
---@return table
function Profile:getMapData()
	return _Game.configManager.maps[self:getLevelData().map]
end



-- Variables

---Sets the player's variable. Used to store various states per profile, saved between opens.
---@param name string The name of the variable.
---@param value any The value to be stored. Only primitive types are allowed.
function Profile:setVariable(name, value)
	self.variables[name] = value
end



---Retrieves a previously stored profile variable. If it has not been stored, this function will return `nil`.
---@param name string The name of a previously stored variable.
---@return any
function Profile:getVariable(name)
	return self.variables[name]
end



-- Core level stuff
-- Level number: Starts at one, each level and each subsequent entry in randomizers count separately.
-- Level pointer: Starts at one and points towards an entry in the level order.
-- Level ID: ID of a particular level file.
-- Level data: Stores profile-related data per level, such as win/lose count or some other statistics.

---Returns the player's current level number.
---@return integer
function Profile:getLevel()
	-- Count (current level pointer - 1) entries from the level set.
	local n = _Game.configManager:getLevelCountFromEntries(self.session.level - 1)

	return n + self.session.sublevel
end

---Returns the player's current level number as a string.
---@return string
function Profile:getLevelStr()
	return tostring(self:getLevel())
end



---Returns the player's current level pointer value.
---@return integer
function Profile:getLevelPtr()
	return self.session.level
end

---Returns the player's current level pointer value as a string.
---@return string
function Profile:getLevelPtrStr()
	return tostring(self:getLevel())
end



---Returns the player's current level entry.
---@return table
function Profile:getLevelEntry()
	return _Game.configManager.levelSet.levelOrder[self.session.level]
end



---Returns the player's current level ID.
---@return integer
function Profile:getLevelID()
	return self.session.levelID
end

---Returns the player's current level ID as a string.
---@return string
function Profile:getLevelIDStr()
	return tostring(self:getLevelID())
end



---Returns the player's current level name.
---@return string
function Profile:getLevelName()
	local entry = self:getLevelEntry()

	if entry.type == "level" then
		return entry.name
	elseif entry.type == "randomizer" then
		return entry.names[self.session.sublevel]
	end
	return "ERROR"
end



---Goes on to a next level, either another one in a subset, or in a main level set.
function Profile:incrementLevel()
	local entry = self:getLevelEntry()

	-- Update the pointers.
	if entry.type == "level" then
		self.session.level = self.session.level + 1
		self:setupLevel()
	elseif entry.type == "randomizer" then
		-- Check whether it's the last sublevel.  If so, get outta there and move on.
		if self.session.sublevel == entry.count then
			self.session.level = self.session.level + 1
			self:setupLevel()
		else
			self.session.sublevel = self.session.sublevel + 1
		end
	end

	-- Generate a new level ID.
	self:generateLevelID()
end



---Generates a new level ID, based on the current entry type and data.
function Profile:generateLevelID()
	local entry = self:getLevelEntry()

	-- Now we are going to generate the level ID from the pool, if this is a randomizer,
	-- or just replace it if it's a normal level.
	if entry.type == "level" then
		self.session.levelID = entry.level
	elseif entry.type == "randomizer" then
		-- Use local data to generate a level.
		if entry.mode == "repeat" then
			self.session.levelID = self.session.sublevel_pool[math.random(#self.session.sublevel_pool)]
		elseif entry.mode == "noRepeat" then
			local i = math.random(#self.session.sublevel_pool)
			self.session.levelID = self.session.sublevel_pool[i]
			table.remove(self.session.sublevel_pool, i)
		elseif entry.mode == "order" then
			while true do
				local chance = (entry.count - self.session.sublevel + 1) / #self.session.sublevel_pool
				local n = self.session.sublevel_pool[1]
				table.remove(self.session.sublevel_pool, 1)
				if math.random() < chance then
					self.session.levelID = n
					break
				end
			end
		end
	end
end



---Sets up values for a level set entry the level pointer is currently pointing to.
function Profile:setupLevel()
	local entry = self:getLevelEntry()

	self.session.sublevel = 1
	self.session.sublevel_pool = {}
	-- If this entry is a randomizer, copy the pool to an internal profile field.
	if entry.type == "randomizer" then
		for i, levelID in ipairs(entry.pool) do
			self.session.sublevel_pool[i] = levelID
		end
	end
end



---Returns the checkpoint ID which is assigned to the most recent level compared to the player's current level number.
---@return integer
function Profile:getLatestCheckpoint()
	local checkpoint = nil
	local diff = nil

	for i, level in ipairs(_Game.configManager.levelSet.checkpoints) do
		if level == self.session.level then
			return i
		end
		local d = self.session.level - level
		if d > 0 and (not diff or diff > d) then
			checkpoint = i
			diff = d
		end
	end

	return checkpoint
end



---Returns `true` if the player's next level number is on the checkpoint list.
---@return boolean
function Profile:isCheckpointUpcoming()
	local entry = self:getLevelEntry()

	-- A checkpoint can't be upcoming if we are in the middle of a randomizer section.
	if entry.type == "randomizer" and self.session.sublevel < entry.count then
		return false
	end

	for i, level in ipairs(_Game.configManager.levelSet.checkpoints) do
		if level == self.session.level + 1 then
			return true
		end
	end
	return false
end



---Returns the player's current level data. This is NOT level data which is stored on any config file!
---The returned level data structure contains information about win and lose count, and level record.
---@return table
function Profile:getCurrentLevelData()
	return self.levels[self:getLevelIDStr()]
end

---Overwrites the player's current level data with the given data.
---See `Profile:getCurrentLevelData()` for more information about the data.
---@param data table
function Profile:setCurrentLevelData(data)
	self.levels[self:getLevelIDStr()] = data
end


-- Score

---Returns the player's current score.
---@return integer
function Profile:getScore()
	return self.session.score
end

---Adds a given amount of points to the player's current score.
---@param score integer The score to be added.
function Profile:grantScore(score)
	self.session.score = self.session.score + score
end

---Gives currency.
function Profile:grantCurrency(amount)
	self.currency = self.currency + amount
end

---Gives xp. XP cannot go below zero.
function Profile:grantXP(amount)
	self.xp = self.xp + amount
	if self.xp < 0 then self.xp = 0 end
end


---Get number of coins
function Profile:getCurrency()
	return self.currency
end

--- Return player ID
function Profile:getPlayerID()
	return self.uniqueid
end

---Calculates the level from XP. Normally 55 more per level, but it will be 250 here to adjust for xp scaling.
---Fractional values are used to determine the length of the XP bar.
function Profile:getLevel()
	if self.xp <= 0 then return 1 end

	local efflevel = (math.sqrt((8 * self.xp / 250)+1)-1)*0.5

	-- level cap
	if efflevel > 500 then efflevel = 500 end

	return efflevel
end

-- Lives

-- Unlocked checkpoints

---Returns a list of checkpoints this player has unlocked.
---@return table
function Profile:getUnlockedCheckpoints()
	return self.checkpoints
end

---Returns whether this player has unlocked a given checkpoint.
---@param n integer The checkpoint ID to be checked.
---@return boolean
function Profile:isCheckpointUnlocked(n)
	return _MathIsValueInTable(self.checkpoints, n)
end

---Unlocks a given checkpoint for the player if it has not been unlocked yet.
---@param n integer The checkpoint ID to be unlocked.
function Profile:unlockCheckpoint(n)
	if self:isCheckpointUnlocked(n) then
		return
	end
	table.insert(self.checkpoints, n)
end



-- Game

---Starts a new game for this player, starting from a specified checkpoint.
---@param checkpoint integer The checkpoint ID of the game's starting point.
function Profile:newGame(checkpoint)
	self.session = {}
	self.session.lives = 2
	self.session.coins = 0
	self.session.score = 0
	self.session.difficulty = 1

	self.session.level = _Game.configManager.levelSet.checkpoints[checkpoint]
	self.session.sublevel = 1
	self.session.sublevel_pool = {}
	self.session.levelID = 0
	
	self:setupLevel()
	self:generateLevelID()
end

---Ends a game for the player and removes all its data.
function Profile:deleteGame()
	self.session = nil
end



-- Level

---Increments the level win count, updates the level record if needed and removes the saved level data.
---Does not increment the level itself!
---@param score integer The level score.
function Profile:winLevel(score)
	local levelData = self:getCurrentLevelData() or {score = 0, won = 0, lost = 0}

	levelData.score = math.max(levelData.score, score)
	levelData.won = levelData.won + 1
	self:setCurrentLevelData(levelData)
	self:unsaveLevel()
end



---Advances the profile to the next level.
function Profile:advanceLevel()
	-- Check if beating this level unlocks some checkpoints.
	local checkpoints = self:getLevelEntry().unlockCheckpointsOnBeat
	if checkpoints then
		for i, checkpoint in ipairs(checkpoints) do
			self:unlockCheckpoint(checkpoint)
		end
	end

	self:incrementLevel()
	_Game:playSound("sound_events/level_advance.json")
end



---Returns `true` if score given in parameter would yield a new record for the current level.
---@param score integer The score value to be checked against.
---@return boolean
function Profile:getLevelHighscoreInfo(score)
	local levelData = self:getCurrentLevelData()
	return not levelData or score > levelData.score
end

-- Level saves

---Saves a level to the profile.
---@param t table The serialized level data to be saved.
function Profile:saveLevel(t)
	self.session.levelSaveData = t
end

---Returns a previously saved level from the profile.
---@return table
function Profile:getSavedLevel()
	return self.session.levelSaveData
end

---Removes level save data from this profile.
function Profile:unsaveLevel()
	self.session.levelSaveData = nil
end



-- Highscore

---Writes this profile onto the highscore list using its current score.
---If successful, returns the position on the leaderboard. If not, returns `false`.
---@return integer|boolean
function Profile:writeHighscore()
	local pos = _Game.runtimeManager.highscores:getPosition(self:getScore())
	if not pos then
		return false
	end

	-- returns the position if it got into top 10
	_Game.runtimeManager.highscores:storeProfile(self, pos)
	return pos
end



-- FORK-SPECIFIC CODE GOES HERE
-- Frogatars/Monuments

---@return string
function Profile:getFrogatar()
	return "frogatar_"..(self.frogatar or "basic")
end

function Profile:setFrogatar(frogatar)
    self.frogatar = frogatar
end

---Sets this Profile's Spirit Monument (`"spirit_"..animal`).
---Pass `nil` to clear it.
function Profile:setActiveMonument(animal)
	if animal then
		self.monument = animal
		return
    end
	self.monument = nil
end

---@return string|nil
function Profile:getActiveMonument()
	if self.monument == nil then
		return nil
	end
	local monumentString = "spirit_" .. (self.monument)
    if _Game.configManager.frogatars[monumentString] then
        return monumentString
    end
end

---@return string
function Profile:getFrogatarInstanceKey()
	local activeMonument = self:getActiveMonument()
    if activeMonument then
        return activeMonument
    else
        return self:getFrogatar()
    end
end

---@return Frogatar
function Profile:getFrogatarInstance()
	return _Game.configManager.frogatars[self:getFrogatarInstanceKey()]
end

function Profile:getFrogatarEffects()
	return self:getFrogatarInstance():getEffects()
end



-- Powers

---Equips a Power.
---@param power string
function Profile:equipPower(power)
	if not _Game.configManager.powers[power] then
		_Log:printt("Profile", string.format("Power ID %s does not exist", power))
		return
	end
	if not self:isPowerEquipped(power) then
		if #self.equippedPowers <= 3 then
			table.insert(self.equippedPowers, power)
		else
			_Log:printt("Profile", string.format("Equipped powers is already 3", power))
        end
	else
		_Log:printt("Profile", string.format("Power ID %s is already equipped", power))
	end
end



---Unequips a Power.
---@param power string
function Profile:unequipPower(power)
	if not _Game.configManager.powers[power] then
		_Log:printt("Profile", string.format("Power ID %s does not exist", power))
		return
	end
	if self:isPowerEquipped(power) then
		for i, v in ipairs(self.equippedPowers) do
			if self.equippedPowers[i] == power then
				table.remove(self.equippedPowers, i)
			end
		end
	else
		_Log:printt("Profile", string.format("Power ID %s is already unequipped", power))
	end
end



---Gets a power's level.
---@param power string
---@return number|nil
function Profile:getPowerLevel(power)
	if not _Game.configManager.powers[power] then
		_Log:printt("Profile", string.format("Power ID %s does not exist", power))
		return
	end
	return self.powerCatalog[power] and self.powerCatalog[power].level or 1
end



---Returns true if a Power is already equipped.
---@param power string
---@return boolean
function Profile:isPowerEquipped(power)
	for i, value in ipairs(self.equippedPowers) do
		if value == power then
			return true
		end
	end
	return false
end



---Returns the specified Power if it is equipped or `nil`.
---
---Use this instead of `Profile:isPowerEquipped` and `_Game.configManager:getPower()`.
---This will then let you use `Power:getCurrentLevelData()`.
---@return Power|nil
function Profile:getEquippedPower(power)
	if not _Game.configManager.powers[power] then
		_Log:printt("Profile", string.format("Power ID %s does not exist", power))
		return
	end
	for i, value in ipairs(self.equippedPowers) do
		if value == power then
			return _Game.configManager:getPower(power)
		end
	end
end



-- Food items



---Equips a Food Item.
---@param foodItem string
function Profile:equipFoodItem(foodItem)
	if not _Game.configManager.foodItems[foodItem] then
		_Log:printt("Profile", string.format("Food ID %s does not exist", foodItem))
		return
	end
	if not self:isFoodItemEquipped(foodItem) then
		self.equippedFood = foodItem
	else
		_Log:printt("Profile", string.format("Food ID %s is already equipped", foodItem))
	end
end



---Unequips a Food Item.
---@param foodItem string
function Profile:unequipFoodItem(foodItem)
	if not _Game.configManager.powers[foodItem] then
		_Log:printt("Profile", string.format("Food ID %s does not exist", foodItem))
		return
	end
	if self:isPowerEquipped(foodItem) then
		self.equippedFood = nil
	else
		_Log:printt("Profile", string.format("Food ID %s is already unequipped", foodItem))
	end
end



---Returns true if a Food Item is already equipped.
---@param foodItem string
---@return boolean
function Profile:isFoodItemEquipped(foodItem)
	if self.equippedFood == foodItem then
		return true
	end
	return false
end



---Returns the equipped Food Item or `nil`.
---
---This should only be used for UI related functions.
---If you wish to get the gameplay effects, use `Profile:getEquippedFoodItemEffects()`.
---@return FoodItem|nil
function Profile:getEquippedFoodItem()
	if self.equippedFood then
		return _Game.configManager:getFoodItem(self.equippedFood)
	end
end



---Returns the specified Food Item's effects if it is equipped or an empty table.
---
---Use this instead of `Profile:getEquippedFoodItem()`.
---@return table
function Profile:getEquippedFoodItemEffects()
	if not self.equippedFood then
		return {}
	end
	return self:getEquippedFoodItem().effects or {}
end



-- Serialization

---Serializes the Profile's data for saving purposes.
---@return table
function Profile:serialize()
	local t = {
		session = self.session,
		levels = self.levels,
		checkpoints = self.checkpoints,
        variables = self.variables,
		frogatar = self.frogatar or "basic", -- Reverse compatibility with older profiles
        monument = self.monument,
		equippedPowers = self.equippedPowers,
        equippedFood = self.equippedFood,
        powerCatalog = self.powerCatalog,
		foodInventory = self.foodInventory,
		xplevel = self.xplevel,
		xp = self.xp,
		uniqueid = self.uniqueid,
		currency = self.currency
	}
	return t
end



---Restores all data which has been saved by the serialization function.
---@param t table The data to be serialized.
function Profile:deserialize(t)
	self.session = t.session
	self.levels = t.levels
	self.checkpoints = t.checkpoints
	if t.variables then
		self.variables = t.variables
	end
	self.frogatar = t.frogatar
	self.monument = t.monument
    self.equippedPowers = t.equippedPowers
	self.powerCatalog = t.powerCatalog
	self.foodInventory = t.foodInventory
	self.equippedFood = t.equippedFood
	self.xplevel = t.xplevel
	self.xp = t.xp
	self.uniqueid = t.uniqueid
	self.currency = t.currency
	self:migration()

	-- Equipped Powers routines
    local hash = {}
    local res = {}
	-- 1. Handle duplicates
	for _, v in pairs(self.equippedPowers) do
		if (not hash[v]) then
            res[#res + 1] = v
			hash[v] = true
		end
    end
    self.equippedPowers = res
	
    -- 2. Handle equippedPowers[>=4]
	if #self.equippedPowers >= 4 then
		for i = #self.equippedPowers, 4, -1 do
            table.remove(self.equippedPowers, i)
		end
	end
end

---Migrate older savefiles to current version used to populate tables when they didn't exist in older savefiles, etc.
function Profile:migration()
	if self.xp == nil then
		print ("WARNING: no xp detected in savefile, resetting xp values")
		self.xp = 0
		self.xplevel = 1
	end

	if self.currency == nil then
		print ("WARNING: no coins detected in savefile, resetting coins values")
		self.currency = 0
	end

	if self.uniqueid == nil then
		print ("WARNING: no uniqueid detected in savefile, generating new uniqueid")
		self.uniqueid = math.random(1,4294967295)
	end


end



return Profile
