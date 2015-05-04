local tiny = require "tiny"
local cpml = require "cpml"

local geometry = {}
function geometry.calc_bounding_box(model, min, max)
	local vertices = {
		cpml.vec3(max.x, max.y, min.z),
		cpml.vec3(max.x, min.y, min.z),
		cpml.vec3(max.x, min.y, max.z),
		cpml.vec3(min.x, min.y, max.z),
		cpml.vec3(min),
		cpml.vec3(max),
		cpml.vec3(min.x, max.y, min.z),
		cpml.vec3(min.x, max.y, max.z),
	}

	for i, v in ipairs(vertices) do
		vertices[i] = cpml.vec3(model * { v.x, v.y, v.z, 1 })
	end

	local tris = {
		vertices[1], vertices[2], vertices[3],
		vertices[2], vertices[4], vertices[3],
		vertices[1], vertices[5], vertices[2],
		vertices[2], vertices[5], vertices[4],
		vertices[6], vertices[3], vertices[4],
		vertices[1], vertices[3], vertices[6],
		vertices[1], vertices[7], vertices[5],
		vertices[6], vertices[7], vertices[1],
		vertices[6], vertices[4], vertices[8],
		vertices[6], vertices[8], vertices[7],
		vertices[5], vertices[8], vertices[4],
		vertices[5], vertices[7], vertices[8],
	}

	return tris
end

function new_triangles(t, offset, mesh)
	offset = offset or cpml.vec3(0, 0, 0)
	local data, indices = {}, {}
	for k, v in ipairs(t) do
		local current = {}
		table.insert(current, v.x + offset.x)
		table.insert(current, v.y + offset.y)
		table.insert(current, v.z + offset.z)
		table.insert(data, current)
		if not mesh then
			table.insert(indices, k)
		end
	end

	if not mesh then
		local layout = {
			{ "VertexPosition", "float", 3 }
		}

		local m = love.graphics.newMesh(layout, data, "triangles", "dynamic")
		m:setVertexMap(indices)
		return m
	else
		if mesh.setVertices then
			mesh:setVertices(data)
		else
			-- XXX: REMOVE WHEN WE GET A NEW BUILD
			for i, v in ipairs(data) do
				mesh:setVertex(i, v)
			end
		end
		return mesh
	end
end

return function(camera)
	local movement_system  = tiny.processingSystem()
	movement_system.filter = tiny.requireAll("position", "orientation", "velocity", "rot_velocity")

	-- Only used client-side
	if camera then
		movement_system.camera = camera
		Signal.register('client-id', function(id) movement_system.id = id end)
	end

	function movement_system:process(entity, dt)
		entity.position    = entity.position    + entity.velocity * dt
		entity.orientation = entity.orientation + entity.rot_velocity * dt

		if camera and entity.possessed == true then
			self.camera:move(entity.velocity, 1 * dt)
			entity.position = self.camera.position

			if not console.visible and love.window.hasFocus() and love.mouse.getRelativeMode() then
				local state = Gamestate.current()
				self.camera:rotateXY(state.dx, state.dy)

				entity.orientation = cpml.mat4.from_direction(self.camera.direction, self.camera.up):to_quat()
			end

			self.camera:update(dt)
		end

		if self.id and entity.id ~= self.id and entity.real_position and entity.real_orientation then
			local adjust = 0.1
			entity.position    = entity.position:lerp(entity.real_position, adjust)
			entity.orientation = entity.orientation:lerp(entity.real_orientation, adjust)
		end

		entity.model_matrix = cpml.mat4()
			:translate(entity.position)
			:rotate(entity.orientation)
			:scale(entity.scale)

		if entity.model and (not entity.bounds or entity.needs_update) then
			-- should be the bounding box triangles in world space
			local triangles = geometry.calc_bounding_box(
				entity.model_matrix,
				entity.model.bounds.min,
				entity.model.bounds.max
			)
			entity.bound_triangles = triangles
			entity.bounds = new_triangles(triangles, nil, entity.bounds)
		end
	end

	return movement_system
end
