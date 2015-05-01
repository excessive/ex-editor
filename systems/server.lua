local ffi          = require "ffi"
local tiny         = require "libs.tiny"
local cpml         = require "libs.cpml"
local lube         = require "libs.lube"
local actions      = require "action_enum"
local packet_types = require "packet_types"
local cdata        = packet_types.cdata
local packets      = packet_types.packets

return function(world)
	local server_system        = tiny.system()
	server_system.filter       = tiny.requireAll("replicate", "id")
	server_system.world        = world
	server_system.recvcommands = {}
	server_system.cache        = {}
	server_system.id           = 0 -- used to generate ids for entities

	function server_system:onAdd(entity)
		self.cache[entity.id] = entity
	end

	function server_system:onRemove(entity)
		self.cache[entity.id] = nil
	end

	function server_system:update(entities, dt)
		if self.connection then
			self.connection:update(dt)
			require("libs.lovebird").update()
		end
	end

	function server_system:start(port)
		self.world:activate(self)

		port = port or 2808
		self.connection = lube.enetServer()
		self.connection.handshake = "ドキドキ"
		self.connection:setPing(true, 6, "プリキュア\n")

		self.connection:listen(tonumber(port))
		console.i("Server starting on port %s", port)

		function self.connection.callbacks.recv(d, id) self:recv(d, id) end
		function self.connection.callbacks.connect(id) self:connect(id) end
		function self.connection.callbacks.disconnect(id) self:disconnect(id) end
	end

	function server_system:stop()
		self.world:deactivate(self)
	end

	function server_system:connect(client_id)
		console.i("Client %s connected", tostring(client_id))

		self:recv_acquire_entities(client_id)

		-- Generate unique ID
		self.id = self.id + 1

		-- Create new entity
		local data = {
			id            = self.id,
			position_x    = 0,
			position_y    = 0,
			position_z    = 0,
			orientation_x = 0,
			orientation_y = 0,
			orientation_z = 1,
			orientation_w = 0,
			scale_x       = 1,
			scale_y       = 1,
			scale_z       = 1,
			model_path    = "player",
		}
		self:recv_spawn_entity(data, client_id)

		-- Tell client to possess new entity
		self:recv_possess_entity(data, client_id)
	end

	function server_system:disconnect(client_id)
		console.i("Client %s disconnected", tostring(client_id))

		for _, entity in pairs(self.cache) do
			if entity.possessed == tonumber(client_id) then
				local data = { id = entity.id }
				self:recv_despawn_entity(data, client_id)
			end
		end
	end

	function server_system:send(data, client_id)
		self.connection:send(data, client_id)
	end

	function server_system:recv(data, client_id)
		if data then
			local header = cdata:decode("packet_type", data)

			local map = packets[header.type]
			if not map then
				console.e("Invalid packet type (%s) from client %d!", header.type, client_id)
				return
			end

			self["recv_"..map.name](self, cdata:decode(map.name, data), client_id)
		end
	end

	function server_system:recv_client_action(data, client_id)
		local entity = self.cache[tonumber(data.id)]

		if action == actions.select then
			-- set locked flag of target to player's id
			-- so that only that player can modify target

			data.type     = packets.client_action
			local struct  = cdata:set_struct("client_action", data)
			local encoded = cdata:encode(struct)
			self.connection:send(encoded)
		end
	end

	function server_system:recv_acquire_entities(client_id)
		local data = {
			type = packets.acquire_entities
		}

		for _, entity in pairs(self.cache) do
			data.id            = entity.id
			data.position_x    = entity.position.x
			data.position_y    = entity.position.y
			data.position_z    = entity.position.z
			data.orientation_x = entity.orientation.x
			data.orientation_y = entity.orientation.y
			data.orientation_z = entity.orientation.z
			data.orientation_w = entity.orientation.w
			data.scale_x       = entity.scale.x
			data.scale_y       = entity.scale.y
			data.scale_z       = entity.scale.z
			data.model_path    = entity.model_path

			local struct  = cdata:set_struct("acquire_entities", data)
			local encoded = cdata:encode(struct)
			self.connection:send(encoded, client_id)
		end
	end

	function server_system:recv_spawn_entity(data, client_id)
		local entity = {}

		-- Check ID
		local id = tonumber(data.id)
		if id == 0 then
			-- Generate unique ID
			self.id = self.id + 1
			id = self.id
		end

		-- Assign data
		entity.id           = id
		entity.position     = cpml.vec3(data.position_x,    data.position_y,    data.position_z)
		entity.orientation  = cpml.quat(data.orientation_x, data.orientation_y, data.orientation_z, data.orientation_w)
		entity.scale        = cpml.vec3(data.scale_x,       data.scale_y,       data.scale_z)
		entity.velocity     = cpml.vec3(0, 0, 0)
		entity.rot_velocity = cpml.quat(0, 0, 0, 0)
		entity.model_path   = ffi.string(data.model_path)
		entity.replicate    = true

		-- Cache new entity
		self.world:addEntity(entity)
		self.cache[entity.id] = entity
		console.d("Spawned entity %s (%s)", entity.id, self.cache[entity.id])

		-- Send data
		data.type     = packets.spawn_entity
		local struct  = cdata:set_struct("spawn_entity", data)
		local encoded = cdata:encode(struct)
		self.connection:send(encoded)
	end

	function server_system:recv_despawn_entity(data, client_id)
		local entity = self.cache[tonumber(data.id)]
		self.world:removeEntity(entity)

		data.type     = packets.despawn_entity
		local struct  = cdata:set_struct("despawn_entity", data)
		local encoded = cdata:encode(struct)
		self.connection:send(encoded)
	end

	function server_system:recv_update_entity(data, client_id)
		local entity = self.cache[tonumber(data.id)]

		if not entity then return end

		-- Process data
		local position     = cpml.vec3(data.position_x,     data.position_y,     data.position_z)
		local orientation  = cpml.quat(data.orientation_x,  data.orientation_y,  data.orientation_z,  data.orientation_w)
		local velocity     = cpml.vec3(data.velocity_x,     data.velocity_y,     data.velocity_z)
		local rot_velocity = cpml.quat(data.rot_velocity_x, data.rot_velocity_y, data.rot_velocity_z, data.rot_velocity_w)
		local scale        = cpml.vec3(data.scale_x,        data.scale_y,        data.scale_z)

		-- Determine latency
		local server = self.connection.socket
		local peer   = server:get_peer(client_id)
		local ping   = peer:round_trip_time() / 1000 / 2

		-- Compensate for latency
		position      = position      + velocity * ping
		--orientation.x = orientation.x + rot_velocity.x * ping
		--orientation.y = orientation.y + rot_velocity.y * ping
		--orientation.z = orientation.z + rot_velocity.z * ping
		--orientation.w = orientation.w + rot_velocity.w * ping

		-- Assign data
		entity.position     = position
		entity.orientation  = orientation
		entity.velocity     = velocity
		entity.rot_velocity = rot_velocity
		entity.scale        = scale

		-- Prepare new data
		data.type           = packets.update_entity
		data.position_x     = position.x
		data.position_y     = position.y
		data.position_z     = position.z
		data.orientation_x  = orientation.x
		data.orientation_y  = orientation.y
		data.orientation_z  = orientation.z
		data.orientation_w  = orientation.w
		data.velocity_x     = velocity.x
		data.velocity_y     = velocity.y
		data.velocity_z     = velocity.z
		data.rot_velocity_x = rot_velocity.x
		data.rot_velocity_y = rot_velocity.y
		data.rot_velocity_z = rot_velocity.z
		data.rot_velocity_w = rot_velocity.w
		data.scale_x        = scale.x
		data.scale_y        = scale.y
		data.scale_z        = scale.z

		-- Send data
		local struct  = cdata:set_struct("update_entity", data)
		local encoded = cdata:encode(struct)
		self.connection:send(encoded)
	end

	function server_system:recv_possess_entity(data, client_id)
		-- Possessing another entity? Not any more!
		for _, entity in pairs(self.cache) do
			if entity.possessed == tonumber(client_id) then
				entity.possessed = nil
				break
			end
		end

		-- Possess a new entity!
		local entity     = self.cache[tonumber(data.id)]
		entity.possessed = tonumber(client_id)
		self.world:removeEntity(entity)
		self.world:addEntity(entity)

		data.type     = packets.possess_entity
		local struct  = cdata:set_struct("possess_entity", data)
		local encoded = cdata:encode(struct)
		self.connection:send(encoded, client_id)
	end

	return server_system
end
