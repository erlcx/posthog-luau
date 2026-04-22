local Core = require("./core")
local LuteAdapter = require("@self/LuteAdapter")
local Types = require("./core/Types")

type PublicOptions = Types.PublicOptions
type Options = Types.Options
type Client = Types.Client
type RuntimeModule = Types.RuntimeModule

local PostHogLute: RuntimeModule = {} :: RuntimeModule

function PostHogLute.new(options: PublicOptions): Client
	local resolvedOptions: Options = {
		apiKey = options.apiKey,
		host = options.host,
		flushAt = options.flushAt,
		flushIntervalSeconds = options.flushIntervalSeconds,
		requestTimeoutSeconds = options.requestTimeoutSeconds,
		adapter = LuteAdapter,
	}

	return Core.new(resolvedOptions)
end

return PostHogLute
