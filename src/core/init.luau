local Client = require("@self/Client")
local Types = require("@self/Types")

type Options = Types.Options
type ClientType = Types.Client

local PostHogCore = {}

function PostHogCore.new(options: Options): ClientType
	return Client.new(options)
end

return PostHogCore
