local file_button = gui:get_element_by_id("file_button")
local file_menu = gui:get_element_by_id("file_menu")

local toolbar = gui:get_elements_by_query("#toolbar button")
for _, item in ipairs(toolbar) do
	local open = gui:get_element_by_id(item.open)
	function item:on_mouse_clicked(button)
		if button == 1 then
			open:set_property("visible", not open:get_property("visible"))
		end
	end
	open:set_property("visible", false)
	open:set_property("left", item.position.x)
	open:set_property("top",  item.position.y + item:get_property("height"))
	function open:on_mouse_leave()
		self:set_property("visible", false)
		return false
	end
end

local elements = gui:get_elements_by_query(".menu button")
for _, element in ipairs(elements) do
	function element:on_mouse_clicked(button)
		if button == 1 then
			Signal.emit("ui_" .. self.id, self)
		end
	end
end

local windows = gui:get_elements_by_class("window")

for _, window in ipairs(windows) do
	function window:on_mouse_pressed(button)
		if button ~= 1 then
			return
		end
		self.pressed = true
		self:bring_to_front()
		local mx, my = love.mouse.getPosition()

		-- offset within element
		self.ox = self.position.x - self.properties.margin_left - mx
		self.oy = self.position.y - self.properties.margin_top - my
	end

	function window:on_mouse_released(button)
		if button == 1 then
			self.pressed = false
		end
	end

	function window:update(dt)
		self:default_update(dt)

		if not self.pressed then return end

		local nx, ny = love.mouse.getPosition()
		nx = nx + self.ox
		ny = ny + self.oy

		self:set_property("left", nx)
		self:set_property("top",  ny)
	end
end

for _, close in ipairs(gui:get_elements_by_query(".window_close")) do
	function close:on_mouse_pressed(button)
		if button == 1 then
			return false
		end
	end
	function close:on_mouse_clicked(button)
		if button ~= 1 then
			return
		end
		self.parent.parent:set_property("visible", false)
	end
end
