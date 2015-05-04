local tiny = require "tiny"
local cpml = require "cpml"

return function(world)
	local input_system  = tiny.processingSystem()
	input_system.filter = tiny.requireAll("possessed")
	input_system.world  = world

	-- Note: this will happen every time filters change, too!
	function input_system:onAdd(entity)
		-- console.d("Possessed %s (%d)", entity, entity.id)
	end

	function input_system:onRemove(entity)
		-- console.d("Un-possessed %s (%d)", entity, entity.id)
	end

	function input_system:process(entity, dt)
		-- reset velocity (later: this should probably have some falloff instead)
		entity.velocity.x = 0
		entity.velocity.y = 0
		entity.velocity.z = 0

		if console.visible then
			return
		end

		down = love.keyboard.isDown
		if down "d" or down "right" then
			entity.velocity.x = entity.velocity.x + 1
		end
		if down "a" or down "left" then
			entity.velocity.x = entity.velocity.x - 1
		end
		if down "w" or down "up" then
			entity.velocity.y = entity.velocity.y + 1
		end
		if down "s" or down "down" then
			entity.velocity.y = entity.velocity.y - 1
		end
		if down "e" or down "kp0" then
			entity.velocity.z = entity.velocity.z + 1
		end
		if down "q" or down "rshift" then
			entity.velocity.z = entity.velocity.z - 1
		end
		entity.velocity = entity.velocity:normalize()
	end

	return input_system
end
