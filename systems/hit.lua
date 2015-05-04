local tiny = require "tiny"
local cpml = require "cpml"

return function(camera)
	local hit_system  = tiny.processingSystem()
	hit_system.filter = tiny.requireAll("model_matrix", "model")
	hit_system.camera = camera

	function hit_system:update(entities, dt)
		local w, h = love.graphics.getDimensions()
		local x, y
		if love.mouse.getRelativeMode() then
			x, y = w/2, h/2
		else
			x, y = love.mouse.getPosition()
		end
		local modelview = self.camera.view
		local proj = self.camera.projection
		local viewport = { 0, 0, w, h }
		local ray = {
			point     = cpml.mat4.unproject(cpml.vec3(x, h-y, 0), modelview, proj, viewport),
			direction = cpml.mat4.unproject(cpml.vec3(x, h-y, 1), modelview, proj, viewport)
		}
		-- local plane = {
		-- 	point = cpml.vec3(0, 0, 0),
		-- 	normal = cpml.vec3(0, 0, 1)
		-- }
		-- print(cpml.intersect.ray_plane(ray, plane))
		local highlighted = {}
		for _, entity in ipairs(entities) do
			local triangles = entity.bound_triangles
			if triangles then
				for i = 1, #triangles, 3 do
					local hit = cpml.intersect.ray_triangle(ray, { triangles[i], triangles[i+1], triangles[i+2] })
					if hit then
						table.insert(highlighted, entity)
						entity.highlight = true
						break
					end
				end
			end
		end

		local state = Gamestate.current()
		if #highlighted >= 1 then
			table.sort(highlighted, function(a, b)
				return self.camera.position:dist(a.position) < self.camera.position:dist(b.position)
			end)
			local first = highlighted[1]
			first.closest = true
			first.highlight = nil

			state.hit = highlighted
		else
			state.hit = false
		end
	end

	return hit_system
end
