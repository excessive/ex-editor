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
