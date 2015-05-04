local tiny         = require "tiny"
local cpml         = require "cpml"
local packet_types = require "packet_types"
local cdata        = packet_types.cdata
local packets      = packet_types.packets

return function(world)
	local client_update_system  = tiny.system()
	client_update_system.filter = tiny.requireAll("replicate", "needs_update")
	client_update_system.world  = world
	client_update_system.dt     = 0

	Signal.register("client-connected", function(connection) client_update_system.connection = connection end)

	function client_update_system:update(entities, dt)
		if not self.connection then
			self.dt = 0
			return
		end

		self.dt = self.dt + dt

		if self.dt >= 1/20 then
			self.dt = self.dt - 1/20

			for _, entity in ipairs(entities) do
				local data   = {
					type           = packets.update_entity,
					id             = entity.id,
					position_x     = entity.position.x,
					position_y     = entity.position.y,
					position_z     = entity.position.z,
					orientation_x  = entity.orientation.x,
					orientation_y  = entity.orientation.y,
					orientation_z  = entity.orientation.z,
					orientation_w  = entity.orientation.w,
					velocity_x     = entity.velocity.x,
					velocity_y     = entity.velocity.y,
					velocity_z     = entity.velocity.z,
					rot_velocity_x = entity.rot_velocity.x,
					rot_velocity_y = entity.rot_velocity.y,
					rot_velocity_z = entity.rot_velocity.z,
					rot_velocity_w = entity.rot_velocity.w,
					scale_x        = entity.scale.x,
					scale_y        = entity.scale.y,
					scale_z        = entity.scale.z,
				}

				local struct = cdata:set_struct("update_entity", data)
				local encoded = cdata:encode(struct)
				self.connection:send(encoded)

				-- Update filters
				entity.needs_update = nil
				self.world:removeEntity(entity)
				self.world:addEntity(entity)
			end
		end
	end

	return client_update_system
end
