local cpml = require "libs.cpml"
local tiny = require "libs.tiny"

return function(camera)
	local render_system  = tiny.system()
	render_system.filter = tiny.requireAll("position", "orientation", "scale", "model")
	render_system.camera = camera

	function render_system:update(entities, dt)
		self.camera:update(dt)

		local cc = love.math.gammaToLinear
		local color = cpml.vec3(cc(unpack(cpml.color.darken({255,255,255,255}, 0.75))))
		love.graphics.setBackgroundColor(color.x, color.y, color.z, color:dot(cpml.vec3(0.299, 0.587, 0.114)))

		love.graphics.clearDepth()
		love.graphics.setDepthTest("less")
		love.graphics.setCulling("back")
		love.graphics.setFrontFace("cw")
		love.graphics.setBlendMode("replace")

		for _, entity in ipairs(entities) do
			love.graphics.push()
			local model = love.graphics.getMatrix()
				:translate(entity.position)
				:rotate(entity.orientation)
				:scale(entity.scale)
			entity.model.shader:send("u_model", model:to_vec4s())
			self.camera:send(entity.model.shader)
			entity:draw()
			love.graphics.pop()
		end

		love.graphics.setDepthTest()
		love.graphics.setCulling()
		love.graphics.setFrontFace()
		love.graphics.setBlendMode("alpha")
	end

	return render_system
end
