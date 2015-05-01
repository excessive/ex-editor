require "love.filesystem" -- fixes require paths!
require "love.timer"

-- Relay console output to main thread.
local output = love.thread.getChannel("output")

console = {}

local function a(str, level)
	output:push(level:lower() .. str)
end

function console.d(fmt, ...)
	local str = fmt
	if select("#", ...) > 0 then
		str = string.format(tostring(fmt), ...)
	end
	a(str, 'D')
end

function console.i(fmt, ...)
	local str = fmt
	if select("#", ...) > 0 then
		str = string.format(tostring(fmt), ...)
	end
	a(str, 'I')
end

function console.e(fmt, ...)
	local str = fmt
	if select("#", ...) > 0 then
		str = string.format(tostring(fmt), ...)
	end
	a(str, 'E')
end

print = function(...)
	local str = ""
	local num = select("#", ...)
	for i = 1, num do
		str = str .. tostring(select(i, ...))
		if i < num then
			local len = utf8.len(str) + 1
			local tab = 8
			str = str .. string.rep(" ", tab - len % tab)
		end
	end
	a(str, "P")
end

local function main()
	local tiny = require "libs.tiny"
	local world = tiny.world()

	world:addSystem(require("systems.cache")(world))
	world:addSystem(require("systems.movement")())

	local server = require("systems.server")(world)
	server:start()

	world:addSystem(server)

	local _then = love.timer.getTime()
	repeat
		local now = love.timer.getTime()
		local dt = now - _then
		_then = now

		world:update(dt)
		love.timer.sleep(1/100)
	until infinity
end

xpcall(main, console.e)
