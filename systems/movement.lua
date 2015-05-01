local tiny = require "libs.tiny"
local cpml = require "libs.cpml"

return function(camera)
	local movement_system  = tiny.processingSystem()
	movement_system.filter = tiny.requireAll("position", "orientation", "velocity", "rot_velocity")

	-- Only used client-side
	if camera then
		movement_system.camera = camera
		movement_system.prevx, movement_system.prevy = love.mouse.getPosition()
		Signal.register('client-id', function(id) movement_system.id = id end)
	end

	function movement_system:process(entity, dt)
		entity.position    = entity.position    + entity.velocity * dt
		entity.orientation = entity.orientation + entity.rot_velocity * dt

		if camera and entity.possessed == true then
			local w, h = love.graphics.getDimensions()
			local mx, my = love.mouse.getPosition()
			local dx, dy = self.prevx - mx, self.prevy - my
			self.prevx, self.prevy = mx, my

			self.camera:move(entity.velocity, 1 * dt)
			entity.position = self.camera.position

			if not console.visible and love.window.hasFocus() and love.mouse.isGrabbed() then
				--love.mouse.setVisible(false)
				--love.mouse.setGrabbed(true)

				dx, dy = love.mouse.getPosition()
				dx, dy = w/2 - dx, h/2 - dy
				love.mouse.setPosition(w/2, h/2)
				self.camera:rotateXY(dx, dy)

				-- local forward = self.camera.direction
				-- local rotation = cpml.vec3(
				-- 	-- -math.atan2(forward.y, math.sqrt((forward.x * forward.x) + (forward.z * forward.z))),
				-- 	-- math.atan2(forward.x, forward.z),
				-- 	-- math.atan2(forward.y, forward.x)
				-- 	0,
				-- 	0,
				-- 	self.camera.direction:angle_to(cpml.vec3(0, -1, 0))
				-- )
				--
				-- local c1, c2, c3 = math.cos(rotation.z / 2), math.cos(rotation.x / 2), math.cos(rotation.y / 2)
				-- local s1, s2, s3 = math.sin(rotation.z / 2), math.sin(rotation.x / 2), math.sin(rotation.y / 2)
				--
				-- local c1c2 = c1*c2
				-- local s1s2 = s1*s2
				-- local w = c1c2*c3 - s1s2*s3
				-- local x = c1c2*s3 + s1s2*c3
				-- local y = s1*c2*c3 + c1*s2*s3
				-- local z = c1*s2*c3 - s1*c2*s3
				--
				-- entity.orientation.x = x
				-- entity.orientation.y = y
				-- entity.orientation.z = z
				-- entity.orientation.w = w

				entity.orientation = cpml.mat4.from_direction(self.camera.direction, self.camera.up):to_quat()
			else
				--love.mouse.setVisible(true)
				--love.mouse.setGrabbed(false)
			end
		end

		if self.id and entity.id ~= self.id and entity.real_position and entity.real_orientation then
			local adjust = 0.1
			entity.position    = entity.position:lerp(entity.real_position, adjust)
			entity.orientation = entity.orientation:lerp(entity.real_orientation, adjust)
		end

		-- entity.direction = player.orientation:orientation_to_direction()
	end

	return movement_system
end
