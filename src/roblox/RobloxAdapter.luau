local Types = require("../core/Types")

type Request = Types.Request
type Response = Types.Response

local RobloxAdapter = {}

function RobloxAdapter.request(request: Request): Response
	local httpService = game:GetService("HttpService")

	local requestOptions = {
		Url = request.url,
		Method = request.method,
		Headers = request.headers or {},
		Compress = Enum.HttpCompression.None,
	} :: any

	if request.body ~= nil then
		requestOptions.Body = request.body
	end

	if request.timeoutSeconds ~= nil then
		requestOptions.Timeout = math.max(1, math.ceil(request.timeoutSeconds))
	end

	local ok, responseOrError = pcall(function()
		return httpService:RequestAsync(requestOptions)
	end)

	if not ok then
		error("Roblox HttpService request failed: " .. tostring(responseOrError))
	end

	local response = responseOrError :: any
	local headers: { [string]: string }? = nil

	if type(response.Headers) == "table" then
		headers = response.Headers
	end

	local body: string
	if type(response.Body) == "string" then
		body = response.Body
	else
		body = ""
	end

	return {
		statusCode = response.StatusCode,
		body = body,
		headers = headers,
	} :: Response
end

function RobloxAdapter.now(): number
	return os.time()
end

function RobloxAdapter.spawn(callback: () -> ())
	task.spawn(callback)
end

function RobloxAdapter.encodeJson(value: any): string
	return game:GetService("HttpService"):JSONEncode(value)
end

function RobloxAdapter.decodeJson(value: string): any
	local httpService = game:GetService("HttpService")
	local ok, decodedOrError = pcall(function()
		return httpService:JSONDecode(value)
	end)

	if not ok then
		error("Failed to decode JSON response: " .. tostring(decodedOrError))
	end

	return decodedOrError
end

return RobloxAdapter
