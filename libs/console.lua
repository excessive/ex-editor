local console = {
	_LICENSE = [[
		The MIT License (MIT)

		Copyright (c) 2014 Maciej Lopacinski

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]],
	_VERSION = 'love-console v0.1.0',
	_DESCRIPTION = 'Simple love2d console overlay',
	_URL = 'https://github.com/hamsterready/love-console',
	_KEY_TOGGLE = "`",
	_KEY_SUBMIT = "return",
	_KEY_CLEAR = "escape",
	_KEY_DELETE = "backspace",
	_KEY_UP = "up",
	_KEY_DOWN = "down",
	_KEY_PAGEDOWN = "pagedown",
	_KEY_PAGEUP = "pageup",

	visible = false,
	delta = 0,
	logs = {},
	history = {},
	historyPosition = 0,
	linesPerConsole = 0,
	fontSize = 20,
	font = nil,
	firstLine = 0,
	lastLine = 0,
	input = "",
	ps = "> ",
	height_divisor = 3,
	motd = "Greetings, traveler!\nType \"help\" for an index of available commands.",

	-- This table has as its keys the names of commands as
	-- strings, which the user must type to run the command. The
	-- values are themselves tables with two properties:
	--
	-- 1. 'description' A string of information to show via the
	-- /help command.
	--
	-- 2. 'implementation' A function implementing the command.
	--
	-- See the function defineCommand() for examples of adding
	-- entries to this table.
	commands = {}
}

-- used to draw the arrows
local function up(x, y, w)
	w = w * .7
	local h = w * .7
	return {
		x, y + h,
		x + w, y + h,
		x + w/2, y
	}
end

local function down(x, y, w)
	w = w * .7
	local h = w * .7
	return {
		x, y,
		x + w, y,
		x + w/2, y + h
	}
end

local function toboolean(v)
	return (type(v) == "string" and v == "true") or (type(v) == "string" and v == "1") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end

-- http://lua-users.org/wiki/StringTrim trim2
local function trim(s)
	s = s or ""
	return s:match "^%s*(.-)%s*$"
end

-- http://wiki.interfaceware.com/534.html
local function string_split(s, d)
	local t = {}
	local i = 0
	local f
	local match = '(.-)' .. d .. '()'

	if string.find(s, d) == nil then
		return {s}
	end

	for sub, j in string.gmatch(s, match) do
		i = i + 1
		t[i] = sub
		f = j
	end

	if i ~= 0 then
		t[i+1] = string.sub(s, f)
	end

	return t
end

local function merge_quoted(t)
	local ret = {}
	local merging = false
	local buf = ""
	for k, v in ipairs(t) do
		local f, l = v:sub(1,1), v:sub(v:len())
		if f == "\"" and l ~= "\"" then
			merging = true
			buf = v
		else
			if merging then
				buf = buf .. " " .. v
				if l == "\"" then
					merging = false
					table.insert(ret, buf:sub(2,-2))
				end
			else
				if f == "\"" and l == f then
					table.insert(ret, v:sub(2, -2))
				else
					table.insert(ret, v)
				end
			end
		end
	end
	return ret
end

function console.load(font, keyRepeat, inputCallback)
	love.keyboard.setKeyRepeat(keyRepeat or false)

	console.font		= font or love.graphics.newFont(console.fontSize)
	console.fontSize	= font and font:getHeight() or console.fontSize
	console.margin		= console.fontSize
	console.lineSpacing	= 1.25
	console.lineHeight	= console.fontSize * console.lineSpacing
	console.x, console.y = 0, 0

	console.colors = {}
	console.colors["I"] = {r = 251, g = 241, b = 213, a = 255}
	console.colors["D"] = {r = 235, g = 197, b =  50, a = 255}
	console.colors["E"] = {r = 222, g =  69, b =  61, a = 255}
	console.colors["C"] = {r = 150, g = 150, b = 150, a = 255}
	console.colors["P"] = {r = 200, g = 200, b = 200, a = 255}

	console.colors["background"] = {r = 23, g = 55, b = 86, a = 240}
	console.colors["editing"]    = {r = 80, g = 140, b = 200, a = 200}
	console.colors["input"]      = {r = 23, g = 55, b = 86, a = 255}
	console.colors["default"]    = {r = 215, g = 213, b = 174, a = 255}

	console.inputCallback = inputCallback or console.defaultInputCallback

	console.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function console.newHotkeys(toggle, submit, clear, delete)
	console._KEY_TOGGLE = toggle or console._KEY_TOGGLE
	console._KEY_SUBMIT = submit or console._KEY_SUBMIT
	console._KEY_CLEAR = clear or console._KEY_CLEAR
	console._KEY_DELETE = delete or console._KEY_DELETE
end

function console.setMotd(message)
	console.motd = message
end

function console.resize(w, h)
	console.w, console.h = w, h / console.height_divisor
	console.y = console.lineHeight - console.lineHeight * console.lineSpacing

	console.linesPerConsole = math.floor((console.h - console.margin * 2) / console.lineHeight) - 1

	console.h = math.floor(console.linesPerConsole * console.lineHeight + console.margin * 2)

	console.firstLine = console.lastLine - console.linesPerConsole
	console.lastLine = console.firstLine + console.linesPerConsole
end

function console.textedit(t, s, l)
	if t == "" then
		console.editBuffer = nil
	else
		console.editBuffer = { text = t, sel = s }
	end
end

function console.textinput(t)
	if t ~= console._KEY_TOGGLE and console.visible then
		console.input = console.input .. t
		return true
	end
	return false
end

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

function console.keypressed(key)
	local function push_history(input)
		local trimmed = trim(console.input)
		local valid = trimmed ~= ""
		if valid then
			table.insert(console.history, trimmed)
			console.historyPosition = #console.history
		end
		console.input = ""
		return valid
	end
	if key ~= console._KEY_TOGGLE and console.visible then
		if key == console._KEY_SUBMIT and not console.editBuffer then
			local msg = console.input
			if push_history() then
				console.inputCallback(msg)
			end
		elseif key == console._KEY_CLEAR then
			console.input = ""
		elseif key == console._KEY_DELETE and not console.editBuffer then
			console.input = utf8.sub(console.input, 1, utf8.len(console.input) - 1)
		end

		-- history traversal
		if #console.history > 0 then
			if key == console._KEY_UP then
				console.historyPosition = math.min(math.max(console.historyPosition - 1, 1), #console.history)
				console.input = console.history[console.historyPosition]
			elseif key == console._KEY_DOWN then
				local pushing = console.historyPosition + 1 == #console.history + 1
				console.historyPosition = math.min(console.historyPosition + 1, #console.history)
				console.input = console.history[console.historyPosition]
				if pushing then
					console.input = ""
				end
			end
		end

		if key == console._KEY_PAGEUP then
			console.firstLine = math.max(0, console.firstLine - console.linesPerConsole)
			console.lastLine = console.firstLine + console.linesPerConsole
		elseif key == console._KEY_PAGEDOWN then
			console.firstLine = math.min(console.firstLine + console.linesPerConsole, #console.logs - console.linesPerConsole)
			console.lastLine = console.firstLine + console.linesPerConsole
		end

		return true
	elseif key == console._KEY_TOGGLE then
		-- IME support stuff.
		if console.visible and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
			return true
		end
		console.visible = not console.visible
		love.keyboard.setTextInput(console.visible)
		return true
	end
	return false
end

function console.update(dt)
	console.delta = console.delta + dt
end

function console.draw()
	if not console.visible then
		return
	end

	-- backup
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	-- draw console
	local cc = select(3, love.window.getMode()).srgb and love.math.gammaToLinear or function(...) return ... end
	local color = console.colors.background
	love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
	love.graphics.rectangle("fill", console.x, console.y, console.w, console.h)
	color = console.colors.input
	love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
	love.graphics.rectangle("fill", console.x, console.y + console.h, console.w, console.lineHeight)
	color = console.colors.default
	love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
	love.graphics.setFont(console.font)
	local current = console.ps .. " " .. console.input
	local x, y = console.x + console.margin, console.y + console.h + (console.lineHeight - console.fontSize) / 2 -1
	local h = console.font:getHeight()
	love.graphics.print(current, x, y)
	local pos = console.font:getWidth(current)
	local cursor_pos = pos
	if console.editBuffer then
		local buf = console.editBuffer
		local w = console.font:getWidth(buf.text)
		local edit = console.colors.editing
		cursor_pos = cursor_pos + w
		love.keyboard.setTextInput(true, pos, y, w, h) -- NOTE: Added in Love 0.10
		love.graphics.setColor(cc(edit.r, edit.g, edit.b, edit.a))
		love.graphics.rectangle("fill", x + pos, y, w, h)
		love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
		love.graphics.print(buf.text, x + pos, y)
	end
	if math.floor(console.delta * 2) % 2 == 0 then
		love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
	else
		love.graphics.setColor(cc(color.r, color.g, color.b, 0))
	end
	love.graphics.rectangle("fill", x + cursor_pos, y, 2, h)

	love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
	if console.firstLine > 0 then
		love.graphics.polygon("fill", up(console.x + console.w - console.margin - (console.margin * 0.3), console.y + console.margin, console.margin))
	end

	if console.lastLine < #console.logs then
		love.graphics.polygon("fill", down(console.x + console.w - console.margin - (console.margin * 0.3), console.y + console.h - console.margin, console.margin))
	end

	for i, t in pairs(console.logs) do
		if i > console.firstLine and i <= console.lastLine then
			local color = console.colors[t.level]
			love.graphics.setColor(cc(color.r, color.g, color.b, color.a))
			love.graphics.print(t.msg, console.x + console.margin, console.y + (i - console.firstLine)*console.lineHeight)
		end
	end

	-- rollback
	love.graphics.setFont(font)
	love.graphics.setColor(cc(r, g, b, a))
end

local function in_window(x, y)
	if not (x >= console.x and x <= (console.x + console.w)) then
		return false
	end
	if not (y >= console.y and y <= (console.y + console.h + console.lineHeight)) then
		return false
	end
	return true
end

-- eat all mouse events over the console
function console.mousemoved(x, y, rx, ry)
	if not console.visible then
		return false
	end

	local x, y = love.mouse.getPosition()

	if not in_window(x, y) then
		return false
	end

	return true
end

function console.wheelmoved(wx, wy)
	if not console.visible then
		return false
	end

	local x, y = love.mouse.getPosition()

	if not in_window(x, y) then
		return false
	end

	local consumed = false

	if wy == 1 then
		console.firstLine = math.max(0, console.firstLine - 1)
		consumed = true
	end

	if wy == -1 then
		console.firstLine = math.min(#console.logs - console.linesPerConsole, console.firstLine + 1)
		consumed = true
	end
	console.lastLine = console.firstLine + console.linesPerConsole

	return consumed
end

function console.mousepressed(x, y, button)
	if not console.visible then
		return false
	end

	if not in_window(x, y) then
		return false
	end

	return true
end

function console.d(fmt, ...)
	local str = fmt
	if #{...} > 0 then
		str = string.format(fmt, ...)
	end
	a(str, 'D')
end

function console.i(fmt, ...)
	local str = fmt
	if #{...} > 0 then
		str = string.format(fmt, ...)
	end
	a(str, 'I')
end

function console.e(fmt, ...)
	local str = fmt
	if #{...} > 0 then
		str = string.format(fmt, ...)
	end
	a(str, 'E')
end

function console.clearCommand(name)
	console.commands[name] = nil
end

function console.defineCommand(name, description, implementation, hidden)
	console.commands[name] = {
		description = description,
		implementation = implementation,
		hidden = hidden or false
	}
end

-- private stuff

console.defineCommand(
	"help",
	"Shows information on all commands.",
	function ()
		console.i("Available commands are:")
		for name,data in pairs(console.commands) do
			if not data.hidden then
				console.i(string.format("  %s - %s", name, data.description))
			end
		end
	end
)

console.defineCommand(
	"quit",
	"Quits your application.",
	function () love.event.quit() end
)

console.defineCommand(
	"clear",
	"Clears the console.",
	function ()
		console.firstLine = 0
		console.lastLine = 0
		console.logs = {}
	end
)

console.defineCommand(
	"sv_cheats",
	"~It is a mystery~",
	function(enable)
		local change = toboolean(dopefish)
		dopefish = toboolean(enable)
		change = dopefish ~= change
		if not change then
			console.e("No change")
			return
		end
		if dopefish then
			console.e("The rain in spain stays mainly in the plain.")
		else
			console.i("How now brown cow.")
		end
	end,
	true
)

console.defineCommand(
	"motd",
	"Shows/sets the intro message.",
	function(motd)
		if motd then
			console.motd = motd
			console.i("Motd updated.")
		else
			console.i(console.motd)
		end
	end
)

console.defineCommand(
	"flush",
	"Flush console history to disk",
	function(file)
		if file then
			local t = love.timer.getTime()

			love.filesystem.write(file, "")
			local buffer = ""
			local lines = 0
			for _, v in ipairs(console.logs) do
				buffer = buffer .. v.msg .. "\n"
				lines = lines + 1
				if lines >= 2048 then
					love.filesystem.append(file, buffer)
					lines = 0
					buffer = ""
				end
			end
			love.filesystem.append(file, buffer)

			t = love.timer.getTime() - t
			console.i(string.format("Successfully flushed console logs to \"%s\" in %fs.", love.filesystem.getSaveDirectory() .. "/" .. file, t))
		else
			console.e("Usage: flush <filename>")
		end
	end
)

function console.invokeCommand(name, ...)
	local args = {...}
	if console.commands[name] ~= nil then
		local status, error = pcall(function()
			console.commands[name].implementation(unpack(args))
		end)
		if not status then
			console.e(error)
			console.e(debug.traceback())
		end
	else
		console.e("Command \"" .. name .. "\" not supported, type help for help.")
	end
end

function console.defaultInputCallback(input)
	local commands = string_split(input, ";")
	a(input, 'C')

	for _, line in ipairs(commands) do
		local args = merge_quoted(string_split(trim(line), " "))
		local name = args[1]
		table.remove(args, 1)
		console.invokeCommand(name, unpack(merge_quoted(args)))
	end
end

local original_print = print

function a(str, level)
	str = tostring(str)
	for _, str in ipairs(string_split(str, "\n")) do
		local msg = string.format("%07.02f [".. level .. "] %s", console.delta, str)
		-- XXX: This is totally inflexible.
		if level == "C" then
			msg = string.format("%07.02f -> %s", console.delta, str)
		end
		table.insert(console.logs, #console.logs + 1, {level = level, msg = msg})
		console.lastLine = #console.logs
		console.firstLine = console.lastLine - console.linesPerConsole
		original_print(msg)
	end
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

-- auto-initialize so that console.load() is optional
console.load()
console.i(console.motd)

return console
