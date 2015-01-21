require( "flea.utils" )

local fcgi = require( "fcgi" )

local config = require( "flea.config" )
local request_builder = require( "flea.request" )
local routes = require( "flea.routes" )

local _M = { }

local defaults = {
	sqlite_db_path = "db.sq3",
	secret_path = "secret.bin",
}

_M.config = config.read( "flea.conf", defaults )

for k, v in pairs( routes.methods ) do
	_M[ k ] = v
end

local function print_headers( request )
	for _, header in ipairs( request.new_headers ) do
		fcgi.print( header .. "\r\n" )
	end
end

local function print_body( request )
	fcgi.print( table.concat( request.body ) )
end

function _M.run()
	while fcgi.accept() do
		local url = fcgi.getenv( "DOCUMENT_URI" )
		local route, args = routes.match( url )

		fcgi.print( "Content-Type: text/html; charset=utf-8\r\n" )

		if not route or not route.methods then
			fcgi.print( "Status: 404 Not Found\r\n" )
			fcgi.print( "\r\n" )
			fcgi.print( "<h1>404 Not Found</h1>" )
		else
			local request = request_builder.new()
			local method = fcgi.getenv( "REQUEST_METHOD" ):lower()

			request.url = url
			request.method = method

			local callback = route.methods[ method ]

			if not callback then
				fcgi.print( "Status: 405 Method Not Allowed\r\n" )
				fcgi.print( "Allow:" .. route.allow .. "\r\n" )
				fcgi.print( "\r\n" )
				fcgi.print( "<h1>405 Method Not Allowed</h1>" )
			else
				local ok, err = pcall( callback, request, table.unpack( args ) )

				if not ok then
					fcgi.print( "Status: 500 Internal Server Error\r\n" )
					fcgi.print( "\r\n" )
					fcgi.print( "<h1>500 Internal Server Error</h1>" )
					fcgi.print( "<pre>" .. err .. "</pre>" )
				else
					if request.status then
						request:header( "Status", request.status[ 1 ] .. " " .. request.status[ 2 ] )
					end

					print_headers( request )
					fcgi.print( "\r\n" )
					print_body( request )
				end
			end
		end
	end
end

return _M
