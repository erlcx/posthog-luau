local Types = require("./Types")

type RuntimeAdapter = Types.RuntimeAdapter
type Properties = Types.Properties
type Options = Types.Options
type EventMessage = Types.EventMessage
type FeatureFlagValue = Types.FeatureFlagValue
type ClientType = Types.Client
type Response = Types.Response
type ClientState = {
	_adapter: RuntimeAdapter,
	_apiKey: string,
	_host: string,
	_flushAt: number,
	_flushIntervalSeconds: number,
	_requestTimeoutSeconds: number,
	_queue: { EventMessage },
}
type ClientImpl = ClientType & ClientState

local DEFAULT_HOST = "https://us.i.posthog.com"
local DEFAULT_FLUSH_AT = 20
local DEFAULT_FLUSH_INTERVAL_SECONDS = 10
local DEFAULT_REQUEST_TIMEOUT_SECONDS = 15
local BATCH_ENDPOINT_PATH = "/batch/"
local FLAGS_ENDPOINT_PATH = "/flags/?v=2"

local Client = {}
Client.__index = Client

local function assertNonEmptyString(value: string?, fieldName: string): string
	assert(type(value) == "string" and value ~= "", fieldName .. " must be a non-empty string")
	return value :: string
end

local function toIsoTimestamp(unixTimestampSeconds: number): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ", unixTimestampSeconds)
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

local function resolveDistinctId(properties: Properties?, distinctId: string?): string
	if distinctId ~= nil then
		return assertNonEmptyString(distinctId, "distinctId")
	end

	if properties ~= nil then
		local propertyDistinctId = properties.distinct_id
		if propertyDistinctId ~= nil then
			return assertNonEmptyString(propertyDistinctId, "properties.distinct_id")
		end
	end

	error("distinctId is required")
end

local function cloneProperties(properties: Properties?): Properties
	if properties == nil then
		return {}
	end

	return table.clone(properties)
end

local function buildEventMessage(
	adapter: RuntimeAdapter,
	event: string,
	properties: Properties?,
	distinctId: string?
): EventMessage
	local resolvedDistinctId = resolveDistinctId(properties, distinctId)
	local resolvedProperties = cloneProperties(properties)
	resolvedProperties.distinct_id = resolvedDistinctId

	return {
		event = assertNonEmptyString(event, "event"),
		properties = resolvedProperties,
		distinctId = resolvedDistinctId,
		timestamp = toIsoTimestamp(adapter.now()),
	}
end

local function buildIdentifyEventMessage(
	adapter: RuntimeAdapter,
	distinctId: string,
	properties: Properties?
): EventMessage
	local resolvedDistinctId = assertNonEmptyString(distinctId, "distinctId")
	local personProperties = cloneProperties(properties)

	return {
		event = "$identify",
		properties = {
			distinct_id = resolvedDistinctId,
			["$set"] = personProperties,
		},
		distinctId = resolvedDistinctId,
		timestamp = toIsoTimestamp(adapter.now()),
	}
end

local function joinUrl(baseUrl: string, path: string): string
	if string.sub(baseUrl, -1) == "/" then
		return string.sub(baseUrl, 1, -2) .. path
	end

	return baseUrl .. path
end

local function buildBatchPayload(apiKey: string, queue: { EventMessage }): { [string]: any }
	local batch = table.create(#queue)

	for index, message in queue do
		batch[index] = {
			event = message.event,
			properties = table.clone(message.properties),
			timestamp = message.timestamp,
		}
	end

	return {
		api_key = apiKey,
		historical_migration = false,
		batch = batch,
	}
end

local function assertSuccessfulResponse(response: Types.Response)
	assert(type(response) == "table", "adapter.request must return a response table")
	assert(type(response.statusCode) == "number", "adapter.request must return response.statusCode")

	if response.statusCode < 200 or response.statusCode >= 300 then
		error("PostHog batch request failed with status " .. tostring(response.statusCode))
	end
end

local function assertSuccessfulFlagsResponse(response: Types.Response)
	assert(type(response) == "table", "adapter.request must return a response table")
	assert(type(response.statusCode) == "number", "adapter.request must return response.statusCode")

	if response.statusCode < 200 or response.statusCode >= 300 then
		error("PostHog flags request failed with status " .. tostring(response.statusCode))
	end
end

local function buildFlagsRequestPayload(apiKey: string, distinctId: string, properties: Properties?): { [string]: any }
	local payload = {
		token = apiKey,
		distinct_id = distinctId,
	}

	if properties ~= nil and next(properties) ~= nil then
		payload.person_properties = table.clone(properties)
	end

	return payload
end

local function resolveFlagValue(flagEntry: any): FeatureFlagValue?
	if type(flagEntry) ~= "table" then
		if type(flagEntry) == "boolean" or type(flagEntry) == "string" or type(flagEntry) == "number" then
			return flagEntry
		end

		return nil
	end

	local variant = flagEntry.variant
	if type(variant) == "boolean" or type(variant) == "string" or type(variant) == "number" then
		return variant
	end

	local enabled = flagEntry.enabled
	if type(enabled) == "boolean" then
		return enabled
	end

	return nil
end

local function normalizeFlagsResponse(decodedBody: any): { [string]: FeatureFlagValue }
	if type(decodedBody) ~= "table" then
		error("PostHog flags response body must decode to a table")
	end

	local rawFlags = decodedBody.flags
	if rawFlags == nil then
		return {}
	end

	assert(type(rawFlags) == "table", "PostHog flags response must contain a table in flags")

	local normalizedFlags: { [string]: FeatureFlagValue } = {}

	for flagKey, flagEntry in rawFlags do
		if type(flagKey) == "string" then
			local resolvedValue = resolveFlagValue(flagEntry)
			if resolvedValue ~= nil then
				normalizedFlags[flagKey] = resolvedValue
			end
		end
	end

	return normalizedFlags
end

local function requestFlags(client, distinctId: string, properties: Properties?): { [string]: FeatureFlagValue }
	local requestBody = client._adapter.encodeJson(buildFlagsRequestPayload(client._apiKey, distinctId, properties))

	local ok, responseOrError = pcall(client._adapter.request, {
		method = "POST",
		url = joinUrl(client._host, FLAGS_ENDPOINT_PATH),
		headers = {
			["Content-Type"] = "application/json",
		},
		body = requestBody,
		timeoutSeconds = client._requestTimeoutSeconds,
	})

	if not ok then
		error(responseOrError)
	end

	local response: Response = responseOrError :: Response
	assertSuccessfulFlagsResponse(response)

	local decodedBody = client._adapter.decodeJson(response.body)
	return normalizeFlagsResponse(decodedBody)
end

function Client.new(options: Options): ClientType
	local normalizedOptions = normalizeOptions(options)

	local self: ClientImpl = setmetatable(
		{
			_adapter = normalizedOptions.adapter,
			_apiKey = normalizedOptions.apiKey,
			_host = normalizedOptions.host,
			_flushAt = normalizedOptions.flushAt,
			_flushIntervalSeconds = normalizedOptions.flushIntervalSeconds,
			_requestTimeoutSeconds = normalizedOptions.requestTimeoutSeconds,
			_queue = {},
		} :: ClientState,
		Client
	) :: any

	return self :: ClientType
end

function Client.capture(self: ClientImpl, event: string, properties: Properties?, distinctId: string?)
	table.insert(self._queue, buildEventMessage(self._adapter, event, properties, distinctId))

	if #self._queue >= self._flushAt then
		self:flush()
	end
end

function Client.identify(self: ClientImpl, distinctId: string, properties: Properties?)
	table.insert(self._queue, buildIdentifyEventMessage(self._adapter, distinctId, properties))

	if #self._queue >= self._flushAt then
		self:flush()
	end
end

function Client.flush(self: ClientImpl)
	if #self._queue == 0 then
		return
	end

	local queuedMessages = table.clone(self._queue)
	local requestBody = self._adapter.encodeJson(buildBatchPayload(self._apiKey, queuedMessages))

	local ok, responseOrError = pcall(self._adapter.request, {
		method = "POST",
		url = joinUrl(self._host, BATCH_ENDPOINT_PATH),
		headers = {
			["Content-Type"] = "application/json",
		},
		body = requestBody,
		timeoutSeconds = self._requestTimeoutSeconds,
	})

	if not ok then
		error(responseOrError)
	end

	local response: Response = responseOrError :: Response
	assertSuccessfulResponse(response)
	table.clear(self._queue)
end

function Client.getFeatureFlag(
	self: ClientImpl,
	key: string,
	distinctId: string?,
	properties: Properties?
): FeatureFlagValue?
	local resolvedKey = assertNonEmptyString(key, "key")
	local resolvedDistinctId = resolveDistinctId(properties, distinctId)
	local flags = requestFlags(self, resolvedDistinctId, properties)

	return flags[resolvedKey]
end

function Client.getFeatureFlags(
	self: ClientImpl,
	distinctId: string?,
	properties: Properties?
): { [string]: FeatureFlagValue }
	local resolvedDistinctId = resolveDistinctId(properties, distinctId)
	return requestFlags(self, resolvedDistinctId, properties)
end

return Client
