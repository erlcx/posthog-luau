local process = require("@std/process")
local env = require("@batteries/env")
env.config({
	path = "examples/.env",
})

local PostHogLute = require("@posthog-luau/lute")

local apiKey = process.env.POSTHOG_API_KEY
if apiKey == nil or apiKey == "" then
	error("Set POSTHOG_API_KEY in examples/.env before running this example")
end

local client = PostHogLute.new({
	apiKey = apiKey,
	host = process.env.POSTHOG_HOST,
})

client:identify("user_123", {
	email = "user123@example.com",
	name = "User 123",
})

client:capture("lute_example_ran", {
	source = "examples/luteClient.luau",
	runtime = "lute",
}, "user_123")

local flags = client:getFeatureFlags("user_123")

print("Feature flags:")
for flag, value in pairs(flags) do
	print(`- {flag}: {tostring(value)}`)
end

client:flush()
print("Flushed queued PostHog events")
