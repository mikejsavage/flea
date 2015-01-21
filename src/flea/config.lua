local _M = { }

function _M.read( path, defaults )
	local conf = setmetatable( defaults, { __index = { } } )
	local fn = assert( loadfile( path, "t", conf ) )

	if _VERSION == "Lua 5.1" then
		setfenv( fn, conf )
	end
	local ok, err = pcall( fn )

	if not ok then
		error( "couldn't read config: " .. err )
	end
	return conf
end

return _M

