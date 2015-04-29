local ffi          = require "ffi"
local tiny         = require "libs.tiny"
local cpml         = require "libs.cpml"
local lube         = require "libs.lube"
local Entity       = require "entity"
local actions      = require "action_enum"
local packet_types = require "packet_types"
local cdata        = packet_types.cdata
local packets      = packet_types.packets

return function(world)
	local client_system        = tiny.system()
	client_system.filter       = tiny.requireAll("replicate")
	client_system.world        = world
	client_system.recvcommands = {}
	client_system.cache        = {}

	function client_system:onAdd(entity)
		self.cache[entity.id] = entity
	end

	function client_system:onRemove(entity)
		self.cache[entity.id] = nil
	end

	function client_system:update(entities, dt)
		if not self.connection then return end
		self.connection:update(dt)
	end

	function client_system:connect(host, port)
		self.world:activate(self)

		self.connection = lube.enetClient()
		self.connection.handshake = "ドキドキ"
		self.connection:setPing(true, 2, "プリキュア\n")
		self.host = host or "50.132.59.168"--"localhost"
		self.port = port or 2808

		local connected, err = self.connection:connect(self.host, tonumber(self.port), true)
		if connected then
			console.i("Connected to %s:%s", self.host, self.port)
			Signal.emit("client-connected", self.connection)
		else
			console.i(err)
		end

		function self.connection.callbacks.recv(d) self:recv(d) end

		return connected, err
	end

	function client_system:disconnect()
		self.world:deactivate(self)
		self.connection:disconnect()
	end

	function client_system:send(data, packet_type)
		if not self.connection then return false end

		if packet_type then
			data.type = packets[packet_type]
			local struct = cdata:set_struct(packet_type, data)
			local encoded = cdata:encode(struct)
			self.connection:send(encoded)
		else
			self.connection:send(data)
		end
	end

	function client_system:recv(data)
		if data then
			local header = cdata:decode("packet_type", data)

			local map = packets[header.type]
			if not map then
				console.e("Invalid packet type (%s) from server!", header.type)
				return
			end

			self.recvcommands[map.name](self, cdata:decode(map.name, data))
		end
	end

	function client_system.recvcommands:client_action(data)
		if actions[action] then
			local state = Gamestate:current()
			state["action_"..actions[action]](state, id)
		else
			console.e("Invalid action: %d", action)
		end
	end

	function client_system.recvcommands:acquire_entities(data)
		client_system.recvcommands:spawn_entity(data)
	end

	function client_system.recvcommands:spawn_entity(data)
		local entity            = Entity(require("assets.models."..ffi.string(data.model_path)))
		entity.id               = tonumber(data.id)
		entity.position         = cpml.vec3(data.position_x,    data.position_y,    data.position_z)
		entity.orientation      = cpml.quat(data.orientation_x, data.orientation_y, data.orientation_z, data.orientation_w)
		entity.scale            = cpml.vec3(data.scale_x,       data.scale_y,       data.scale_z)
		entity.velocity         = cpml.vec3(0, 0, 0)
		entity.rot_velocity     = cpml.quat(0, 0, 0, 0)
		entity.real_position    = position
		entity.real_orientation = orientation
		entity.replicate        = true

		client_system.world:addEntity(entity)
		client_system.cache[entity.id] = entity
	end

	function client_system.recvcommands:despawn_entity(data)
		local entity = client_system.cache[tonumber(data.id)]
		client_system.world:removeEntity(entity)
	end

	function client_system.recvcommands:update_entity(data)
		-- Process data
		local entity       = client_system.cache[tonumber(data.id)]
		local position     = cpml.vec3(data.position_x,     data.position_y,     data.position_z)
		local orientation  = cpml.quat(data.orientation_x,  data.orientation_y,  data.orientation_z,  data.orientation_w)
		local velocity     = cpml.vec3(data.velocity_x,     data.velocity_y,     data.velocity_z)
		local rot_velocity = cpml.quat(data.rot_velocity_x, data.rot_velocity_y, data.rot_velocity_z, data.rot_velocity_w)
		local scale        = cpml.vec3(data.scale_x,        data.scale_y,        data.scale_z)

		if not entity then return end

		-- Only update entities that are not me or locked by me
		if entity.id ~= client_system.id and entity.lock ~= client_system.id then
			-- Determine latency
			local peer   = client_system.connection.peer
			local ping   = peer:round_trip_time() / 1000 / 2

			-- Compensate for latency
			position      = position      + velocity * ping

			-- I'm pretty sure this won't work right.
			orientation.x = orientation.x + rot_velocity.x * ping
			orientation.y = orientation.y + rot_velocity.y * ping
			orientation.z = orientation.z + rot_velocity.z * ping
			orientation.w = orientation.w + rot_velocity.w * ping

			-- Assign data
			entity.real_position    = position     or entity.real_position
			entity.real_orientation = orientation  or entity.real_orientation
			entity.velocity         = velocity     or entity.velocity
			entity.rot_velocity     = rot_velocity or entity.rot_velocity
			entity.scale            = scale        or entity.scale
		end
	end

	function client_system.recvcommands:possess_entity(data)
		client_system.id = tonumber(data.id)
		Signal.emit("client-id", client_system.id)

		-- Possessing another entity? Not any more!
		for _, entity in pairs(client_system.cache) do
			if entity.possessed then
				entity.possessed = nil
				break
			end
		end

		-- Possess a new entity!
		local entity     = client_system.cache[client_system.id]
		entity.possessed = true
		client_system.world:removeEntity(entity)
		client_system.world:addEntity(entity)
	end

	Signal.register('client-connect',    function(...) client_system:connect(...) end)
	Signal.register('client-disconnect', function(...) client_system:disconnect(...) end)
	Signal.register('client-send',       function(...) client_system:send(...) end)

	return client_system
end