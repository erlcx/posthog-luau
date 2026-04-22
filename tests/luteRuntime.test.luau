local test = require("@std/test")
local PostHogLute = require("@posthog-luau/lute")
local LuteAdapter = require("@posthog-luau/lute/LuteAdapter")

local function assertIsoTimestamp(value: any)
	if type(value) ~= "string" then
		error("expected timestamp to be a string")
	end

	if string.match(value, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$") == nil then
		error(`expected an ISO-8601 UTC timestamp, got {value}`)
	end
end

test.suite("LuteRuntimePostHog", function(suite)
	suite:case("newUsesLuteDefaults", function(asserts)
		local client = PostHogLute.new({
			apiKey = "test-api-key",
		}) :: any

		asserts.eq("test-api-key", client._apiKey)
		asserts.eq("https://us.i.posthog.com", client._host)
		asserts.eq(20, client._flushAt)
		asserts.eq(10, client._flushIntervalSeconds)
		asserts.eq(15, client._requestTimeoutSeconds)

		if client._adapter ~= LuteAdapter then
			error("expected Lute runtime client to use LuteAdapter")
		end
	end)

	suite:case("newUsesProvidedOverrides", function(asserts)
		local client = PostHogLute.new({
			apiKey = "test-api-key",
			host = "https://eu.i.posthog.com",
			flushAt = 3,
			flushIntervalSeconds = 1.5,
			requestTimeoutSeconds = 7.25,
		}) :: any

		asserts.eq("https://eu.i.posthog.com", client._host)
		asserts.eq(3, client._flushAt)
		asserts.eq(1.5, client._flushIntervalSeconds)
		asserts.eq(7.25, client._requestTimeoutSeconds)
	end)

	suite:case("captureQueuesEventsThroughLuteEntrypoint", function(asserts)
		local client = PostHogLute.new({
			apiKey = "test-api-key",
			flushAt = 2,
		}) :: any

		client:capture("Button Clicked", {
			button = "signup",
		}, "user-123")

		asserts.eq(1, #client._queue)

		local queuedEvent = client._queue[1]
		asserts.eq("Button Clicked", queuedEvent.event)
		asserts.eq("user-123", queuedEvent.distinctId)
		asserts.eq("signup", queuedEvent.properties.button)
		asserts.eq("user-123", queuedEvent.properties.distinct_id)
		asserts.eq("posthog-luau", queuedEvent.properties["$lib"])
		assertIsoTimestamp(queuedEvent.timestamp)
	end)

	suite:case("identifyQueuesPostHogIdentifyEvent", function(asserts)
		local client = PostHogLute.new({
			apiKey = "test-api-key",
			flushAt = 2,
		}) :: any

		client:identify("user-123", {
			plan = "pro",
		})

		asserts.eq(1, #client._queue)

		local queuedEvent = client._queue[1]
		asserts.eq("$identify", queuedEvent.event)
		asserts.eq("user-123", queuedEvent.distinctId)
		asserts.eq("user-123", queuedEvent.properties.distinct_id)
		asserts.eq("posthog-luau", queuedEvent.properties["$lib"])
		asserts.eq("pro", queuedEvent.properties["$set"].plan)
		assertIsoTimestamp(queuedEvent.timestamp)
	end)

	suite:case("adapterJsonRoundTripsValues", function(asserts)
		local decoded = LuteAdapter.decodeJson(LuteAdapter.encodeJson({
			flag = true,
			count = 3,
			name = "test",
		}))

		asserts.eq(true, decoded.flag)
		asserts.eq(3, decoded.count)
		asserts.eq("test", decoded.name)
	end)

	suite:case("adapterDecodeErrorsOnInvalidJson", function(asserts)
		asserts.throws(function()
			LuteAdapter.decodeJson("{")
		end)
	end)

	suite:case("rootEntrypointRequiresRuntimePath", function(asserts)
		asserts.throws(function()
			require("@posthog-luau")
		end)
	end)
end)
