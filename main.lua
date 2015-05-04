love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";libs/?.lua;libs/?/init.lua")

-- local all_requires = {}
-- local real_require = require
-- require = function(...)
-- 	local path = select(1, ...)
-- 	if not all_requires[path] then
-- 		print(...)
-- 		all_requires[path] = true
-- 	end
-- 	return real_require(...)
-- end

require("love3d").import(true) -- prepare your body, love2d

Gamestate = require "hump.gamestate"
Signal    = require "hump.signal"
console   = require "console"

local default_callbacks = {
	errhand = love.errhand
}

local output = love.thread.getChannel("output")

function love.load()
	console.load(love.graphics.newFont("assets/fonts/unifont-7.0.06.ttf", 16), true)

	--THIS IS A REALLY DANGEROUS FUNCTION, REMOVE IT IF YOU DONT NEED IT
	console.defineCommand(
		"lua",
		"Lets you run lua code from the terminal",
		function(...)
			local cmd = ""
			for i = 1, select("#", ...) do
				cmd = cmd .. tostring(select(i, ...)) .. " "
			end
			if cmd == "" then
				console.i("This command lets you run lua code from the terminal.")
				console.i("It's a really dangerous command. Don't use it!")
				return
			end
			xpcall(loadstring(cmd), console.e)
		end,
		true
	)

	local server = love.thread.newThread("server.lua")
	server:start()

	Gamestate.registerEvents()
	Gamestate.switch(require("states.editor")())
end

function love.threaderror(t, e)
	console.e("%s: %s", t, e)
end

function love.update(dt)
	if Gamestate.current().next then
		Gamestate.switch(Gamestate.current().next)
	end
	love.window.setTitle(string.format("Ex Editor (FPS: %0.2f, MSPF: %0.3f)", love.timer.getFPS(), love.timer.getAverageDelta() * 1000))
	local s = output:pop()
	while s do
		(console[s:sub(1,1)] or console.e)(s:sub(2))
		s = output:pop()
	end

	local state = Gamestate.current()
	if state.world then
		state.world:update(dt)
	end
end

function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
		for i=1,3 do love.math.random() end
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return
					end
				end
				if not console[name] or not console[name](a,b,c,d,e,f) then
					love.handlers[name](a,b,c,d,e,f)
				end
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- Call update and draw
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()

			console.update(dt) -- make sure the console is always updated
			love.update(dt) -- will pass 0 if love.timer is disabled

			if console then console.draw() end
			love.graphics.present()
		end
		-- if love.timer then love.timer.sleep(0.001) end
	end
end
