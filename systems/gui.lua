local domy = require "libs.DOMy"
local tiny = require "libs.tiny"

return function(state)
	local gui_system = tiny.system()
	gui_system.gui   = domy.new()
	gui_system.gui:add_widget_directory("assets/ui/widgets")
	gui_system.gui:import_markup("assets/ui/editor.lua")
	gui_system.gui:import_styles("assets/ui/style.lua")
	gui_system.gui:resize()
	gui_system.gui:import_scripts("assets/ui/scripts.lua")
	gui_system.gui:register_callbacks(state, { "update", "draw", "errhand" })

	Signal.register("ui_file_exit", function(el)
		love.event.quit()
	end)

	Signal.register("ui_file_connect", function(el)
		if not el.action or el.action == "connect" then
			Signal.emit('client-disconnect')
			Signal.emit('client-connect')
			el.action = "disconnect"
			el.value = "Disconnect"
		elseif el.action == "disconnect" then
			Signal.emit('client-disconnect')
			el.value = "Connect"
			el.action = "connect"
		end
	end)

	Signal.register("ui_file_connect_local", function(el)
		if not el.action or el.action == "connect" then
			Signal.emit('client-disconnect')
			Signal.emit('client-connect', "localhost")
			el.action = "disconnect"
			el.value = "Disconnect"
		elseif el.action == "disconnect" then
			Signal.emit('client-disconnect')
			el.value = "Connect"
			el.action = "connect"
		end
	end)

	Signal.register("ui_file_server", function(el)
		if not el.action or el.action == "start" then
			Signal.emit('server-start')
			el.action = "stop"
			el.value = "Stop Server"
		elseif el.action == "stop" then
			Signal.emit('server-stop')
			el.value = "Start Server"
			el.action = "start"
		end
	end)

	Signal.register("ui_asset_list", function(el)
		local list = gui_system.gui:get_element_by_id("file_browser")
		local model_path = "assets/models"
		local files = love.filesystem.getDirectoryItems(model_path)
		for _, file in ipairs(files) do
			local pos = file:match("^.*()%.")
			if file:sub(pos) == ".lua" then
				local require_path = ("%s/%s"):format(model_path, file:sub(1,pos-1)):gsub("/", "%.")
				local data = require(require_path)
				data.path = require_path
				-- for k, v in pairs(data) do
				-- 	console.d("%s: %s", k, v)
				-- end
				local new = gui_system.gui:new_element({ "button", require_path }, list)
				new.data = data
			end
		end

		list:set_property("visible", true)

		for k,v in ipairs(list.children) do
			print(k, v.value)
		end
	end)

	Signal.register("ui_asset_add", function(el)
		local entity      = {
			position_x    = love.math.random(-5, 5),
			position_y    = love.math.random(-5, 5),
			position_z    = love.math.random(-5, 5),
			orientation_x = love.math.random(-1, 1),
			orientation_y = love.math.random(-1, 1),
			orientation_z = love.math.random(-1, 1),
			orientation_w = 0,
			scale_x       = love.math.random(1, 3),
			scale_y       = love.math.random(1, 3),
			scale_z       = love.math.random(1, 3),
			model_path    = "tsubasa",
		}
		Signal.emit('client-send', entity, "spawn_entity")
	end)

	function gui_system:update(entities, dt)
		self.gui:update(dt)
		self.gui:draw()
	end

	return gui_system
end
