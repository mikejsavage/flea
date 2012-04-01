require( "picky" )
require( "lfs" )
require( "flea.utils" )

local port = 8080
local production = false

for _, param in ipairs( arg ) do
	local numParam = tonumber( param )

	if numParam then
		port = numParam
	elseif param == "--production" then
		production = true
	else
		printf( "unrecognised arg: %s", param )
	end
end

for path in ( package.cpath .. ";" ):gmatch( "[^;]+" ) do
	local lib = path:gsub( "%?", "libflea" )
	local loader = package.loadlib( lib, "luaopen_libflea" )

	if loader then
		setHandler = loader( port )

		break
	end
end

assert( setHandler, "couldn't find libflea" )

flea.production = production

printf( "http://0.0.0.0:%d/ [%s]",
	port,
	production and "production" or "testing"
)

require( "flea.handler" )
require( "flea.errorHandler" )
