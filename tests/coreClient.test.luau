local test = require("@std/test")
local json = require("@std/json")
local PostHogCore = require("@posthog-luau/core")
local Types = require("@posthog-luau/core/Types")

type Request = Types.Request
type Response = Types.Response
type RuntimeAdapter = Types.RuntimeAdapter
type FlagsRequestBody = {
	distinct_id: string,
}

local function createFakeAdapter(): (RuntimeAdapter, { Request })
	local requests: { Request } = {}
	local nowValue = 1_700_000_000

	local adapter: RuntimeAdapter = {} :: RuntimeAdapter

	function adapter.request(request: Request): Response
		table.insert(requests, request)

		return {
			statusCode = 200,
			body = '{"flags":{"example-flag":true}}',
			headers = {
				["Content-Type"] = "application/json",
			},
		}
	end

	function adapter.now(): number
		return nowValue
	end

	function adapter.spawn(callback: () -> ())
		callback()
	end

	function adapter.encodeJson(value: any): string
		return json.serialize(value)
	end

	function adapter.decodeJson(value: string): any
		local decoded = json.deserialize(value)
		if decoded == nil then
			error("failed to decode json")
		end

		return decoded
	end

	return adapter, requests
end

test.suite("CoreClientDistinctIdBehavior", function(suite)
	suite:case("captureUsesExplicitDistinctId", function(asserts)
		local adapter = createFakeAdapter()
		local client = PostHogCore.new({
			apiKey = "test-api-key",
			adapter = adapter,
		}) :: any

		client:capture("explicit_event", nil, "user_123")

		asserts.eq(1, #client._queue)
		asserts.eq("user_123", client._queue[1].distinctId)
		asserts.eq("user_123", client._queue[1].properties.distinct_id)
		asserts.eq("posthog-luau", client._queue[1].properties["$lib"])
	end)

	suite:case("captureUsesPropertiesDistinctIdWhenProvided", function(asserts)
		local adapter = createFakeAdapter()
		local client = PostHogCore.new({
			apiKey = "test-api-key",
			adapter = adapter,
		}) :: any

		client:capture("property_event", {
			distinct_id = "user_123",
		})

		asserts.eq(1, #client._queue)
		asserts.eq("user_123", client._queue[1].distinctId)
		asserts.eq("user_123", client._queue[1].properties.distinct_id)
		asserts.eq("posthog-luau", client._queue[1].properties["$lib"])
	end)

	suite:case("captureErrorsWithoutDistinctId", function(asserts)
		local adapter = createFakeAdapter()
		local client = PostHogCore.new({
			apiKey = "test-api-key",
			adapter = adapter,
		}) :: any

		asserts.throws(function()
			client:capture("missing_distinct_id")
		end)
	end)

	suite:case("identifyQueuesIdentifyEvent", function(asserts)
		local adapter = createFakeAdapter()
		local client = PostHogCore.new({
			apiKey = "test-api-key",
			adapter = adapter,
		}) :: any

		client:identify("user_123", {
			email = "user123@example.com",
		})

		asserts.eq(1, #client._queue)
		asserts.eq("$identify", client._queue[1].event)
		asserts.eq("user_123", client._queue[1].properties.distinct_id)
		asserts.eq("posthog-luau", client._queue[1].properties["$lib"])
		asserts.eq("user123@example.com", client._queue[1].properties["$set"].email)
	end)

	suite:case("getFeatureFlagsUsesExplicitDistinctId", function(asserts)
		local adapter, requests = createFakeAdapter()
		local client = PostHogCore.new({
			apiKey = "test-api-key",
			adapter = adapter,
		}) :: any

		local flags = client:getFeatureFlags("user_123")
		local requestBodyJson = requests[#requests].body :: string
		local requestBody = json.deserialize(requestBodyJson) :: FlagsRequestBody

		asserts.eq(true, flags["example-flag"])
		asserts.eq("user_123", requestBody.distinct_id)
	end)
end)
