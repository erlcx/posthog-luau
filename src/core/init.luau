local Client = require("./Client")

local PostHogCore = {}

function PostHogCore.new(options)
	return Client.new(options)
end

return PostHogCore
