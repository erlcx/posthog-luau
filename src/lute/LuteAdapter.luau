local Types = require("../core/Types")
local json = require("@std/json")
local task = require("@std/task")
local net = require("@lute/net")

type Request = Types.Request
type Response = Types.Response

local LuteAdapter = {}

function LuteAdapter.request(request: Request): Response
	local response = net.client.request(request.url, {
		method = request.method,
		headers = request.headers,
		body = request.body,
	})

	return {
		statusCode = response.status,
		body = response.body,
		headers = response.headers,
	}
end

function LuteAdapter.now(): number
	return os.time()
end

function LuteAdapter.spawn(callback: () -> ())
	task.spawn(callback)
end

function LuteAdapter.encodeJson(value: any): string
	return json.serialize(value)
end

function LuteAdapter.decodeJson(value: string): any
	local decoded = json.deserialize(value)
	if decoded == nil then
		error("Failed to decode JSON response")
	end

	return decoded
end

return LuteAdapter
