-- INCLUDE ZONE

-- custom error handler
require("crash")

-- global utility methods
_Utils = require("com.utils")

local json = require("com.json")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

local Log = require("src.Kernel.Log")
local Debug = require("src.Kernel.Debug")

local BootScreen = require("src.Kernel.BootScreen")
local Game = require("src.Game")
local Verifier = require("src.Verifier")

local ExpressionVariables = require("src.ExpressionVariables")
local Settings = require("src.Kernel.Settings")

local DiscordRichPresence = require("src.DiscordRichPresence")
local Network = require("src.Kernel.Network")
local ThreadManager = require("src.ThreadManager")



-- CONSTANT ZONE
_VERSION = "vZB"
_VERSION_NAME = "Zuma Blitz Remake"
_DISCORD_APPLICATION_ID = "797956172539887657"
_START_TIME = love.timer.getTime()

-- Set this to a string of your choice. This will be only printed in log files and is not used anywhere else.
-- You can automate this in i.e. a script by simply adding a `_BUILD_NUMBER = "<your number>"` line at the end of this main.lua file.
_BUILD_NUMBER = "2023-06-30"





-- GLOBAL ZONE
_DisplaySize = Vec2(800, 600)
_DisplayFullscreen = false
_MousePos = Vec2(0, 0)
_KeyModifiers = {lshift = false, lctrl = false, lalt = false, rshift = false, rctrl = false, ralt = false}
-- File system prefix. On Windows defaults to "", on Android defaults to "/sdcard/".
_FSPrefix = ""

---@type Game|BootScreen|Verifier
_Game = nil

---@type Log
_Log = nil

---@type Debug
_Debug = nil

_Vars = ExpressionVariables()
_Network = Network()
_ThreadManager = ThreadManager()



_TotalTime = 0
_TimeScale = 1

---@type Settings
_EngineSettings = nil

---@type DiscordRichPresence
_DiscordRPC = nil








-- CALLBACK ZONE
function love.load(args)
	-- Parse command line arguments.
	local arg = _ParseCommandLineArguments(args)

	-- Initialize RNG for Boot Screen
	local _ = math.randomseed(os.time())

	-- Initalize save location
	love.filesystem.setIdentity("ZumaBlitzRemake")

	-- Initialize some classes
	_Log = Log()
	_Debug = Debug()
	if arg.mode ~= "verifier" then
		_DiscordRPC = DiscordRichPresence()
		_EngineSettings = Settings("settings.json")
	end

    -- Autoload ZBR by default, there is no need to access the boot screen unless requested
	if arg.mode == "game" then
		_LoadGame("ZumaBlitzRemake")
	elseif arg.mode == "boot" then
		_LoadBootScreen()
	elseif arg.mode == "verifier" then
		_LoadVerifier(arg.cores)
	end
end

function love.update(dt)
	_Debug:profUpdateStart()

	_MousePos = _PosFromScreen(Vec2(love.mouse.getPosition()))
	if _Game then _Game:update(dt * _TimeScale) end

	_Log:update(dt)
	_Debug:update(dt)
	_ThreadManager:update(dt)
	if _DiscordRPC then
		_DiscordRPC:update(dt)
	end

	-- rainbow effect for the shooter and console cursor blink; to be phased out soon
	_TotalTime = _TotalTime + dt

	_Debug:profUpdateStop()
end

function love.draw()
	--dbg:profDrawStart()

	-- Main
	if _Game then _Game:draw() end

	-- Tests
	_Debug:draw()

	--dbg:profDrawStop()
end

function love.mousepressed(x, y, button)
	if _Game then _Game:mousepressed(x, y, button) end
end

function love.mousereleased(x, y, button)
	if _Game then _Game:mousereleased(x, y, button) end
end

function love.mousemoved(x, y, dx, dy, istouch)
	if _Game then _Game:mousemoved(x, y) end
end

function love.wheelmoved(x, y)
	if _Game then _Game:wheelmoved(x, y) end
end

function love.keypressed(key)
	for k, v in pairs(_KeyModifiers) do if key == k then _KeyModifiers[k] = true end end
	-- Backspace is treated exclusively and will trigger repeatedly when held.
	love.keyboard.setKeyRepeat(key == "backspace")

	if not _Debug.console.active then
		if _Game then _Game:keypressed(key) end
	end

	_Debug:keypressed(key)
end

function love.keyreleased(key)
	for k, v in pairs(_KeyModifiers) do if key == k then _KeyModifiers[k] = false end end

	if not _Debug.console.active then
		if _Game then _Game:keyreleased(key) end
	end

	_Debug:keyreleased(key)
end

function love.textinput(t)
	if not _Debug.console.active then
		if _Game then _Game:textinput(t) end
	end

	_Debug:textinput(t)
end

function love.resize(w, h)
	_DisplaySize = Vec2(w, h)
end

function love.quit()
	_Log:printt("main", "User-caused Exit...")
	if _Game and _Game.quit then
		_Game:quit(true)
	end
	if _DiscordRPC then
		_DiscordRPC:disconnect()
	end
	_Log:save(true)
end

function love.filedropped(file)
	_Debug.console:filedropped(file)
end



-- FUNCTION ZONE

---Parses command-line arguments (currently, `--boot`, `--verifier`, `--verifierw` and `-c X` are supported) and returns a table with the following fields:
--- - `mode` (`"game"`, `"boot"` or `"verifier"`) - Which mode the program will be run in.
--- - `window` (`true` or `false`) - Whether the window will be visible. Matters when `mode` is `"verifier"`.
--- - `cores` (`nil` or a number) - The number of cores allotted for the Verifier.
---@param args any
---@return table
function _ParseCommandLineArguments(args)
	local out = {
		mode = "game",
		window = true
	}
	local currentSwitch = nil

	for i, v in ipairs(args) do
		if not currentSwitch then
			if v == "--boot" then
				out.mode = "boot"
			elseif v == "--verifier" then
				out.mode = "verifier"
				out.window = false
			elseif v == "--verifierw" then
				out.mode = "verifier"
			elseif string.sub(v, 1, 2) == "-j" then
				out.cores = tonumber(string.sub(v, 3))
			end
		else
			--if currentSwitch == "-j" then
			--	out.cores = tonumber(v)
			--end
			currentSwitch = nil
		end
	end

	return out
end

function _LoadGame(gameName)
	_Game = Game(gameName)
	_Game:init()
end

function _LoadBootScreen()
	_Game = BootScreen()
	_Game:init()
end

---Loads the Verifier program, used in game servers.
---@param cores integer? Amount of workers at maximum. See `Verifier:new()`.
function _LoadVerifier(cores)
	_Game = Verifier(cores)
end






function _GetDisplayOffsetX()
	return (_DisplaySize.x - _Game:getNativeResolution().x * _GetResolutionScale()) / 2
end

function _GetResolutionScale()
	return _DisplaySize.y / _Game:getNativeResolution().y
end

function _PosOnScreen(pos)
	return pos * _GetResolutionScale() + Vec2(_GetDisplayOffsetX(), 0)
end

function _PosFromScreen(pos)
	return (pos - Vec2(_GetDisplayOffsetX(), 0)) / _GetResolutionScale()
end



---Returns precise time amount since this program has been launched.
---The output is more precise than the `_TotalTime` field.
---@return number
function _GetPreciseTime()
	return love.timer.getTime() - _START_TIME
end



---Used internally as a common part of `_GetNewestVersion` and `_GetNewestVersionThreaded`.
---Don't call this function directly. Instead, use one of the aforementioned functions.
---@see _GetNewestVersion
---@see _GetNewestVersionThreaded
---@param result table HTTPS request result.
---@return string?
function _ParseNewestVersion(result)
	if result.code == 200 and result.body then
		-- Trim everything before the first square bracket.
		while result.body:sub(1, 1) ~= "[" do
			result.body = result.body:sub(2)
		end
		-- And everything after the last square bracket.
		while result.body:sub(-1) ~= "]" do
			result.body = result.body:sub(1, -2)
		end
		result.body = json.decode(result.body)
		return result.body[1].name
	end
	return nil
end



---Checks online and returns the newest engine version tag available (i.e. `v0.47.0`). Returns `nil` on failure (for example, when you go offline).
---@return string?
function _GetNewestVersion()
	local result = _Network:get("https://api.github.com/repos/jakubg1/OpenSMCE/tags")
	return _ParseNewestVersion(result)
end



---Checks online and executes a function with the newest engine version tag available (i.e. `v0.47.0`) as an argument or `nil` on failure (for example, when you go offline).
---Threaded version: non-blocking call.
---@param onFinish function A function which will be called once the checking process is finished. A version argument is passed.
---@param caller any? An optional instance of any class on which the function will be executed. Useful if you don't want to create anonymous functions.
function _GetNewestVersionThreaded(onFinish, caller)
	_Network:getThreaded("https://api.github.com/repos/jakubg1/OpenSMCE/tags", false, function(result)
		if caller then
			onFinish(caller, _ParseNewestVersion(result))
		else
			onFinish(_ParseNewestVersion(result))
		end
	end)
end



function _ParsePath(data)
	if not data then
		return nil
	end
	return _FSPrefix .. "games/" .. _Game.name .. "/" .. data
end

function _ParsePathDots(data)
	if not data then
		return nil
	end
	return _FSPrefix .. "games." .. _Game.name .. "." .. data
end

function _ParseNumber(data)
	if not data then
		return nil
	end
	if type(data) == "number" then
		return data
	end
	if type(data) == "string" then
		return tonumber(data)
	end
	if data.type == "randomSign" then
		local value = _ParseNumber(data.value)
		return math.random() < 0.5 and -value or value
	end
	if data.type == "randomInt" then
		local min = _ParseNumber(data.min)
		local max = _ParseNumber(data.max)
		return math.random(min, max)
	end
	if data.type == "randomFloat" then
		local min = _ParseNumber(data.min)
		local max = _ParseNumber(data.max)
		return min + math.random() * (max - min)
	end
	if data.type == "expr_graph" then
		local value = _ParseNumber(data.value)
		local points = {}
		for i, point in ipairs(data.points) do
			points[i] = _ParseVec2(point)
		end
		for i, point in ipairs(points) do
			if value < point.x then
				local prevPoint = points[i - 1]
				if prevPoint and point.x - prevPoint.x > 0 then
					local t = (point.x - value) / (point.x - prevPoint.x)
					return prevPoint.y * t + point.y * (1 - t)
				end
				return point.y
			end
		end
		return points[#points].y
	end
end

function _ParseVec2(data)
	if not data then
		return nil
	end
	return Vec2(_ParseNumber(data.x), _ParseNumber(data.y))
end

function _ParseColor(data)
	if not data then
		return nil
	end
	return Color(_ParseNumber(data.r), _ParseNumber(data.g), _ParseNumber(data.b))
end



---Parses a number or an Expression which evaluates to a number, enclosed in a `"$expr{...}"` clause.
---@param data number|string A number or an Expression which evaluates to a number.
---@return number?
function _ParseExprNumber(data)
	if type(data) == "number" then
		return data
	end
	if type(data) == "string" then
		return _Vars:evaluateExpression(data)
	end
	return Vec2(_ParseNumber(data.x), _ParseNumber(data.y))
end



---Parses a table of `{x=number, y=number}` format or an Expression which evaluates to a Vector2, enclosed in a `"$expr{...}"` clause.
---@param data table|string A table or an Expression which evaluates to a number.
---@return Vector2?
function _ParseExprVec2(data)
	if type(data) == "table" then
		return _ParseVec2(data)
	end
	if type(data) == "string" then
		return _Vars:evaluateExpression(data)
	end
end



function _NumStr(n)

	-- in expressions the result can either be a number or string. We will return if we find that it isn't a number.
	if type(n) == "string" then
		return n
	end

	local text = ""
	local s = tostring(n)
	local l = s:len()
	for i = 1, l do
		text = text .. s:sub(i, i)
		if l - i > 0 and (l - i) % 3 == 0 then text = text .. "," end
	end
	return text
end

-- One-dimensional cubic Beazier curve.
-- More info: http://www.demofox.org/bezcubic1d.html
-- The given expression can be simplified, because we are defining A = 0 and D = 1.
-- The shortened expression: y = B * 3x(1-x)^2 + C * 3x^2(1-x) + x^3
-- x is t, B is p1 and C is p2.
function _BzLerp(t, p1, p2)
	local b = p1 * (3 * t * math.pow(1 - t, 2))
	local c = p2 * (3 * math.pow(t, 2) * (1 - t))
	local d = math.pow(t, 3)
	return b + c + d
end
