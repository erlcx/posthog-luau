local Types = require("./Types")

type RuntimeAdapter = Types.RuntimeAdapter
type Properties = Types.Properties
type Options = Types.Options
type EventMessage = Types.EventMessage

local DEFAULT_HOST = "https://us.i.posthog.com"
local DEFAULT_FLUSH_AT = 20

export type Client = typeof(setmetatable(
	{} :: {
		_adapter: RuntimeAdapter,
		_apiKey: string,
		_host: string,
		_flushAt: number,
		_queue: { EventMessage },
	},
	{}
))

local Client = {}
Client.__index = Client

local function assertNonEmptyString(value: string?, fieldName: string): string
	assert(type(value) == "string" and value ~= "", fieldName .. " must be a non-empty string")
	return value
end

function Client.new(options: Options)
	local adapter = options.adapter
	assert(adapter ~= nil, "adapter is required")
	assert(type(adapter.request) == "function", "adapter.request is required")
	assert(type(adapter.now) == "function", "adapter.now is required")
	assert(type(adapter.spawn) == "function", "adapter.spawn is required")
	assert(type(adapter.encodeJson) == "function", "adapter.encodeJson is required")
	assert(type(adapter.decodeJson) == "function", "adapter.decodeJson is required")

	local self = setmetatable({
		_adapter = adapter,
		_apiKey = assertNonEmptyString(options.apiKey, "apiKey"),
		_host = options.host or DEFAULT_HOST,
		_flushAt = options.flushAt or DEFAULT_FLUSH_AT,
		_queue = {},
	}, Client)

	return self
end

function Client:capture(event: string, properties: Properties?, distinctId: string?)
	assertNonEmptyString(event, "event")

	table.insert(self._queue, {
		event = event,
		properties = properties,
		distinctId = distinctId,
		timestamp = self._adapter.now(),
	})

	if #self._queue >= self._flushAt then
		self:flush()
	end
end

function Client:identify(distinctId: string, properties: Properties?)
	assertNonEmptyString(distinctId, "distinctId")
	self:capture("$identify", properties, distinctId)
end

function Client:flush()
	error("flush is not implemented yet")
end

return Client
