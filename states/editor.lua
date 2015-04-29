local Entity = require "entity"
local Camera = require "libs.camera3d"
local cpml = require "libs.cpml"
local tiny = require "libs.tiny"

return function()
	local state = {}
	function state:enter()
		self.world = tiny.world()

		-- TODO: Camera system
		local camera  = Camera(cpml.vec3(0, -2, 1.5))
		-- camera:rotateXY(0, -250)

		self.gui_system = require("systems.gui")(state)

		self.world:addSystem(require("systems.cache")(self.world))
		self.world:addSystem(require("systems.input")(self.world))
		self.world:addSystem(require("systems.movement")(camera))

		local server = require("systems.server")(self.world)
		self.world:addSystem(server)
		self.world:deactivate(server)

		local client = require("systems.client")(self.world)
		self.world:addSystem(client)
		self.world:deactivate(client)

		self.world:addSystem(require("systems.client_update")(self.world))

		self.world:addSystem(require("systems.render")(camera))
		self.world:addSystem(self.gui_system)

		self.world:addEntity(Entity(require "assets.models.tsubasa"))
	end

	function state:leave()
	end

	function state:keypressed(key, is_repeat)
		if key == "escape" then
			love.event.quit()
			return
		end

		if key == "g" then
			love.mouse.setVisible(not love.mouse.isVisible())
			love.mouse.setGrabbed(not love.mouse.isGrabbed())
		end
		self.gui_system.gui:keypressed(key, is_repeat)
	end
	return state
end
