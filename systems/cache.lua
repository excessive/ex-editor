local tiny = require "libs.tiny"

return function(world)
	local cache_system  = tiny.system()
	cache_system.scan   = { "position", "orientation", "scale", "velocity", "rot_velocity" }
	cache_system.filter = tiny.requireOne(unpack(cache_system.scan))
	cache_system.cache  = {}
	cache_system.world  = world

	function cache_system:onAdd(entity)
		self.cache[entity] = {}
		for _, key in ipairs(self.scan) do
			if entity[key] then
				self.cache[entity][key] = entity[key]:clone()
			end
		end
	end

	function cache_system:onRemove(entity)
		self.cache[entity] = nil
	end

	function cache_system:update(entities, dt)
		for _, entity in ipairs(entities) do
			for _, key in ipairs(self.scan) do
				if entity[key] ~= self.cache[entity][key] then
					entity.needs_update = true
					self.world:removeEntity(entity)
					self.world:addEntity(entity)
				end
			end
		end
	end

	return cache_system
end