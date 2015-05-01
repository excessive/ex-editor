local domy = require "libs.DOMy"
local tiny = require "libs.tiny"

return function(state)
	local gui_system = tiny.system()
	gui_system.gui   = domy.new()
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

	function gui_system:update(entities, dt)
		self.gui:update(dt)
		self.gui:draw()
	end

	return gui_system
end
