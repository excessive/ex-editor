require "love.filesystem" -- fixes require paths!
require "love.timer"

-- Relay console output to main thread.
local output = love.thread.getChannel("output")

console = {}


-- From: https://raw.githubusercontent.com/alexander-yakushev/awesompd/master/utf8.lua
local utf8 = {}

function utf8.charbytes (s, i)
	-- argument defaults
	i = i or 1
	local c = string.byte(s, i)

	-- determine bytes needed for character, based on RFC 3629
	if c > 0 and c <= 127 then
		-- UTF8-1
		return 1
	elseif c >= 194 and c <= 223 then
		-- UTF8-2
		local c2 = string.byte(s, i + 1)
		return 2
	elseif c >= 224 and c <= 239 then
		-- UTF8-3
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		return 3
	elseif c >= 240 and c <= 244 then
		-- UTF8-4
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		local c4 = s:byte(i + 3)
		return 4
	end
end

-- returns the number of characters in a UTF-8 string
function utf8.len (s)
	local pos = 1
	local bytes = string.len(s)
	local len = 0
	while pos <= bytes and len ~= chars do
		local c = string.byte(s,pos)
		len = len + 1

		pos = pos + utf8.charbytes(s, pos)
	end
	if chars ~= nil then
		return pos - 1
	end
	return len
end

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
function utf8.sub(s, i, j)
	j = j or -1
	if i == nil then
		return ""
	end
	local pos = 1
	local bytes = string.len(s)
	local len = 0
	-- only set l if i or j is negative
	local l = (i >= 0 and j >= 0) or utf8.len(s)
	local startChar = (i >= 0) and i or l + i + 1
	local endChar = (j >= 0) and j or l + j + 1
	-- can't have start before end!
	if startChar > endChar then
		return ""
	end
	-- byte offsets to pass to string.sub
	local startByte, endByte = 1, bytes
	while pos <= bytes do
		len = len + 1
		if len == startChar then
	 		startByte = pos
		end
		pos = pos + utf8.charbytes(s, pos)
		if len == endChar then
	 		endByte = pos - 1
	 		break
		end
	end
	return string.sub(s, startByte, endByte)
end

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

local function error_printer(msg, layer)
	a((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")), "E")
end

local function main()
	local tiny = require "tiny"
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

		xpcall(function() world:update(dt) end, function(msg) error_printer(tostring(msg), 2) end)
		love.timer.sleep(1/100)
	until infinity
end

xpcall(main, console.e)
