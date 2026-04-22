local Core = require("./core")
local RobloxAdapter = require("@self/RobloxAdapter")
local Types = require("./core/Types")

type PublicOptions = Types.PublicOptions
type Options = Types.Options
type Client = Types.Client
type RuntimeModule = Types.RuntimeModule

local PostHogRoblox: RuntimeModule = {} :: RuntimeModule

function PostHogRoblox.new(options: PublicOptions): Client
	local resolvedOptions: Options = {
		apiKey = options.apiKey,
		host = options.host,
		flushAt = options.flushAt,
		flushIntervalSeconds = options.flushIntervalSeconds,
		requestTimeoutSeconds = options.requestTimeoutSeconds,
		adapter = RobloxAdapter,
	}

	return Core.new(resolvedOptions)
end

return PostHogRoblox
