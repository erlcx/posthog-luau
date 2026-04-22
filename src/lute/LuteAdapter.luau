local LuteAdapter = {}

function LuteAdapter.request(_request)
	error("LuteAdapter.request is not implemented yet")
end

function LuteAdapter.now()
	return os.clock()
end

function LuteAdapter.spawn(callback)
	callback()
end

function LuteAdapter.encodeJson(_value)
	error("LuteAdapter.encodeJson is not implemented yet")
end

function LuteAdapter.decodeJson(_value)
	error("LuteAdapter.decodeJson is not implemented yet")
end

return LuteAdapter
