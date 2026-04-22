local Types = require("./Types")

type RuntimeAdapter = Types.RuntimeAdapter
type Properties = Types.Properties
type Options = Types.Options
type EventMessage = Types.EventMessage
type FeatureFlagValue = Types.FeatureFlagValue

local DEFAULT_HOST = "https://us.i.posthog.com"
local DEFAULT_FLUSH_AT = 20
local DEFAULT_FLUSH_INTERVAL_SECONDS = 10
local DEFAULT_REQUEST_TIMEOUT_SECONDS = 15

export type Client = typeof(setmetatable(
	{} :: {
		_adapter: RuntimeAdapter,
		_apiKey: string,
		_host: string,
		_flushAt: number,
		_flushIntervalSeconds: number,
		_requestTimeoutSeconds: number,
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

local function assertPositiveInteger(value: number?, fieldName: string): number
	assert(type(value) == "number", fieldName .. " must be a number")
	assert(value > 0, fieldName .. " must be greater than 0")
	assert(value % 1 == 0, fieldName .. " must be an integer")
	return value
end

local function assertPositiveNumber(value: number?, fieldName: string): number
	assert(type(value) == "number", fieldName .. " must be a number")
	assert(value > 0, fieldName .. " must be greater than 0")
	return value
end

local function validateAdapter(adapter: RuntimeAdapter)
	assert(adapter ~= nil, "adapter is required")
	assert(type(adapter.request) == "function", "adapter.request is required")
	assert(type(adapter.now) == "function", "adapter.now is required")
	assert(type(adapter.spawn) == "function", "adapter.spawn is required")
	assert(type(adapter.encodeJson) == "function", "adapter.encodeJson is required")
	assert(type(adapter.decodeJson) == "function", "adapter.decodeJson is required")
end

local function normalizeOptions(options: Options)
	assert(type(options) == "table", "options must be a table")
	validateAdapter(options.adapter)

	local host = options.host
	if host ~= nil then
		host = assertNonEmptyString(host, "host")
	end

	local flushAt = options.flushAt
	if flushAt == nil then
		flushAt = DEFAULT_FLUSH_AT
	else
		flushAt = assertPositiveInteger(flushAt, "flushAt")
	end

	local flushIntervalSeconds = options.flushIntervalSeconds
	if flushIntervalSeconds == nil then
		flushIntervalSeconds = DEFAULT_FLUSH_INTERVAL_SECONDS
	else
		flushIntervalSeconds = assertPositiveNumber(flushIntervalSeconds, "flushIntervalSeconds")
	end

	local requestTimeoutSeconds = options.requestTimeoutSeconds
	if requestTimeoutSeconds == nil then
		requestTimeoutSeconds = DEFAULT_REQUEST_TIMEOUT_SECONDS
	else
		requestTimeoutSeconds = assertPositiveNumber(requestTimeoutSeconds, "requestTimeoutSeconds")
	end

	return {
		adapter = options.adapter,
		apiKey = assertNonEmptyString(options.apiKey, "apiKey"),
		host = host or DEFAULT_HOST,
		flushAt = flushAt,
		flushIntervalSeconds = flushIntervalSeconds,
		requestTimeoutSeconds = requestTimeoutSeconds,
	}
end

local function buildEventMessage(
	adapter: RuntimeAdapter,
	event: string,
	properties: Properties?,
	distinctId: string?
): EventMessage
	return {
		event = assertNonEmptyString(event, "event"),
		properties = properties,
		distinctId = distinctId,
		timestamp = adapter.now(),
	}
end

function Client.new(options: Options)
	local normalizedOptions = normalizeOptions(options)

	local self = setmetatable({
		_adapter = normalizedOptions.adapter,
		_apiKey = normalizedOptions.apiKey,
		_host = normalizedOptions.host,
		_flushAt = normalizedOptions.flushAt,
		_flushIntervalSeconds = normalizedOptions.flushIntervalSeconds,
		_requestTimeoutSeconds = normalizedOptions.requestTimeoutSeconds,
		_queue = {},
	}, Client)

	return self
end

function Client:capture(event: string, properties: Properties?, distinctId: string?)
	table.insert(self._queue, buildEventMessage(self._adapter, event, properties, distinctId))

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

function Client:getFeatureFlag(_key: string, _distinctId: string?, _properties: Properties?): FeatureFlagValue?
	error("getFeatureFlag is not implemented yet")
end

function Client:getFeatureFlags(_distinctId: string?, _properties: Properties?): { [string]: FeatureFlagValue }
	error("getFeatureFlags is not implemented yet")
end

return Client
