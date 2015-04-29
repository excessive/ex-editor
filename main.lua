require("libs.love3d").import(true) -- prepare your body, love2d

Gamestate = require "libs.hump.gamestate"
Signal    = require "libs.hump.signal"
console   = require "libs.console"

local default_callbacks = {
	errhand = love.errhand
}

function love.load()
	console.load(love.graphics.newFont("assets/fonts/Inconsolata.otf", 14), true)

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
			-- console.d(cmd)
			xpcall(loadstring(cmd), console.e)
		end,
		true
	)

	Gamestate.registerEvents()
	Gamestate.switch(require("states.editor")())
end

function love.update(dt)
	if Gamestate.current().next then
		Gamestate.switch(Gamestate.current().next)
	end
	love.window.setTitle(string.format("Ex Editor (FPS: %0.2f, MSPF: %0.3f)", love.timer.getFPS(), love.timer.getAverageDelta() * 1000))

	-- enforce this shit
	if love.errhand ~= default_callbacks.errhand then
		love.errhand = default_callbacks.errhand
	end
end

function love.draw()
	local dt = love.timer.getDelta()
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
			for e,a,b,c,d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				if not console[e] or not console[e](a, b, c, d) then
					love.handlers[e](a,b,c,d)
				end
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- Call update and draw
		if love.update then
			console.update(dt)
			love.update(dt)
		end -- will pass 0 if love.timer is disabled

		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			if console then console.draw() end
			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end
