local actions = {}

local function define(name, id)
	-- reverse lookups for all the things!
	actions[name] = id
	actions[id] = name
end

define("lock", 1)
define("unlock", 2)

return actions
