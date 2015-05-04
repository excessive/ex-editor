local tiny = require "tiny"
local cpml = require "cpml"

return function(camera)
	local render_system  = tiny.system()
	render_system.filter = tiny.requireAll("model_matrix", "model")
	render_system.camera = camera
	Signal.register('client-network-id', function(id) render_system.id = id end)

	local bounds = love.graphics.newShader("assets/shaders/shader.glsl")

	function render_system:update(entities, dt)
		local cc = love.math.gammaToLinear
		local color = cpml.vec3(cc(unpack(cpml.color.darken({255,255,255,255}, 0.75))))
		love.graphics.setBackgroundColor(color.x, color.y, color.z, color:dot(cpml.vec3(0.299, 0.587, 0.114)))

		love.graphics.clearDepth()
		love.graphics.setDepthTest("less")
		love.graphics.setCulling("back")
		love.graphics.setFrontFace("cw")
		love.graphics.setBlendMode("replace")

		for _, entity in ipairs(entities) do
			local model = entity.model_matrix:to_vec4s()
			entity.model.shader:send("u_model", model)
			self.camera:send(entity.model.shader)
			entity:draw()
			love.graphics.setShader(bounds)
			love.graphics.setWireframe(true)

			if entity.closest then
				love.graphics.setColor(0, 255, 0, 255)
				entity.closest = nil
			elseif entity.highlight then
				love.graphics.setColor(255, 0, 0, 255)
				entity.highlight = nil
			else
				love.graphics.setColor(cc(80, 80, 80, 255))
			end

			if entity.locked then
				if entity.locked == self.id then
					love.graphics.setColor(0, 0, 255, 255)
				elseif entity.locked ~= self.id then
					love.graphics.setColor(255, 0, 255, 255)
				end
			end

			self.camera:send(bounds)
			bounds:sendInt("u_shading", 1)
			bounds:send("u_Ka", { 1, 0, 0 })
			bounds:send("u_model", cpml.mat4():to_vec4s())
			-- love.graphics.setCulling()
			love.graphics.draw(entity.bounds)
			-- love.graphics.setCulling("back")
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setWireframe(false)
			love.graphics.setShader()
		end

		love.graphics.setDepthTest()
		love.graphics.setCulling()
		love.graphics.setFrontFace()
		love.graphics.setBlendMode("alpha")

		love.graphics.print(tostring(self.camera.position), 0, 50)
	end

	return render_system
end
