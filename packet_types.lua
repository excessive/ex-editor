local cdata   = require "cdata"
local packets = {}

-- all structs get a type field so we don't lose our minds.
function add_struct(name, fields, map)
	local struct = string.format("typedef struct { uint8_t type; %s } %s;", fields, name)
	cdata:new_struct(name, struct)

	-- the packet_type struct isn't a real packet, so don't index it.
	if map then
		map.name = name
		table.insert(packets, map)
		packets[name] = #packets
	end
end

-- Slightly special, I guess.
add_struct("packet_type", "")

add_struct(
	"acquire_entities", [[
		uint64_t id;
		float position_x,     position_y,     position_z;
		float orientation_x,  orientation_y,  orientation_z,  orientation_w;
		float scale_x,        scale_y,        scale_z;
		uint64_t locked;
		unsigned char model_path[64];
	]], {
		"id",
		"position_x",     "position_y",     "position_z",
		"orientation_x",  "orientation_y",  "orientation_z",  "orientation_w",
		"scale_x",        "scale_y",        "scale_z",
		"locked",
		"model_path",
	}
)

add_struct(
	"spawn_entity", [[
		uint64_t id;
		float position_x,     position_y,     position_z;
		float orientation_x,  orientation_y,  orientation_z,  orientation_w;
		float scale_x,        scale_y,        scale_z;
		uint64_t locked;
		unsigned char model_path[64];
	]], {
		"id",
		"position_x",     "position_y",     "position_z",
		"orientation_x",  "orientation_y",  "orientation_z",  "orientation_w",
		"scale_x",        "scale_y",        "scale_z",
		"locked",
		"model_path",
	}
)

add_struct(
	"despawn_entity", [[
		uint64_t id;
	]], {
		"id",
	}
)

add_struct(
	"update_entity", [[
		uint64_t id;
		float position_x,     position_y,     position_z;
		float orientation_x,  orientation_y,  orientation_z,  orientation_w;
		float velocity_x,     velocity_y,     velocity_z;
		float rot_velocity_x, rot_velocity_y, rot_velocity_z, rot_velocity_w;
		float scale_x,        scale_y,        scale_z;
	]], {
		"id",
		"position_x",     "position_y",     "position_z",
		"orientation_x",  "orientation_y",  "orientation_z",  "orientation_w",
		"velocity_x",     "velocity_y",     "velocity_z",
		"rot_velocity_x", "rot_velocity_y", "rot_velocity_z", "rot_velocity_w",
		"scale_x",        "scale_y",        "scale_z",
	}
)

add_struct(
	"possess_entity", [[
		uint64_t id;
	]], {
		"id",
	}
)

add_struct(
	"client_whois", [[
		uint64_t id;
	]], {
		"id",
	}
)

add_struct(
	"client_action", [[
		uint64_t id;
		uint16_t action;
		uint64_t target;
	]], {
		"id",
		"action",
		"target",
	}
)

return { cdata=cdata, packets=packets }
