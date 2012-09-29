require( "lfs" )
require( "flea.utils" )

local port = 8080
local production = false

local setHandlers

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
		setHandlers = loader( port )

		break
	end
end

assert( setHandlers, "couldn't find libflea" )

flea.production = production

local handlers = require( "flea.handler" )
local errorHandler = require( "flea.errorHandler" )

local function handleRequest( request, uri )
	local requestOk, requestErr = handlers.request( request, uri )

	if not requestOk then
		errorHandler( request, requestErr )

		request:send( 500, "Internal Server Error" )
	end
end

setHandlers( handleRequest, handlers.close )

printf( "http://0.0.0.0:%d/ [%s]",
	port,
	production and "production" or "testing"
)
