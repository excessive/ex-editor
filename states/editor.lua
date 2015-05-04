local tiny   = require "tiny"
local cpml   = require "cpml"
local Entity = require "entity"
local Camera = require "camera3d"

return function()
	local state = {}
	function state:enter()
		self.grabbed = false

		self.world = tiny.world()

		self.camera  = Camera(cpml.vec3(0, 10, 1.5))

		self.gui_system = require("systems.gui")(state)

		self.world:addSystem(require("systems.input")(self.world))
		self.world:addSystem(require("systems.movement")(self.camera))
		self.world:addSystem(require("systems.hit")(self.camera))

		-- queue object updates for the next frame
		self.world:addSystem(require("systems.cache")(self.world))

		self.client = require("systems.client")(self.world)
		self.world:addSystem(self.client)
		self.world:deactivate(self.client)
		self.client:connect("localhost")

		self.world:addSystem(require("systems.client_update")(self.world))

		self.world:addSystem(require("systems.render")(self.camera))
		self.world:addSystem(self.gui_system)

		-- reset dx/dy so input doesn't stick
		self.world:addSystem {
			update = function()
				local x, y = love.mouse.getPosition()
				self:mousemoved(x, y, 0, 0)
			end
		}

		self.dx = 0
		self.dy = 0
	end

	function state:keypressed(key, is_repeat)
		if key == "f5" then
			self.gui_system:refresh()
		end

		if key == "escape" then
			love.event.quit()
			return
		end

		self.gui_system.gui:keypressed(key, is_repeat)
	end

	function state:mousemoved(x, y, dx, dy)
		self.dx = -dx
		self.dy = -dy

		self.gui_system.gui:mousemoved(x, y, dx, dy)
	end

	function state:mousereleased(x, y, button)
		if button == 2 and self.restore_pos and not self.grabbed then
			love.mouse.setRelativeMode(false)
			love.mouse.setPosition(self.restore_pos.x, self.restore_pos.y)
		end
		self.gui_system.gui:mousereleased(x, y, button)
	end

	function state:mousepressed(x, y, button)
		-- here until we give inputsystem callbacks, I guess?
		if button == 1 and self.hit then
			local picked = self.hit[1]

			if picked.locked and picked.locked == self.client.client_id then
				print("UNLOCKING")
				Signal.emit("client-action-unlock", picked.id)
			elseif not picked.locked then
				print("LOCKING")
				Signal.emit("client-action-lock", picked.id)
			else
				print("GET FUCKED")
			end
		end
		if button == 2 then
			love.mouse.setRelativeMode(true)
			self.restore_pos = { x=x, y=y }
		end
		if button == 3 then
			self.grabbed = not self.grabbed
			love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
			if love.mouse.getRelativeMode() then
				self.restore_pos = { x=x, y=y }
			elseif self.restore_pos then
				love.mouse.setPosition(self.restore_pos.x, self.restore_pos.y)
			end
		end
		self.gui_system.gui:mousepressed(x, y, button)
	end

	return state
end
