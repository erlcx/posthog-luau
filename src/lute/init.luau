local Core = require("../core")
local LuteAdapter = require("./LuteAdapter")

local PostHogLute = {}

function PostHogLute.new(options)
	local resolvedOptions = table.clone(options)

	resolvedOptions.adapter = LuteAdapter

	return Core.new(resolvedOptions)
end

return PostHogLute
