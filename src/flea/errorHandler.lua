-- sets the default error handler

local function errorHandler( request, error )
	request:clear()
	request:clearHeaders()

	request:addHeader( "Content-Type", "text/plain" )
	request:write( debug.traceback( error ) )
end

function flea.setErrorHandler( handler )
	enforce( handler, "handler", "function" )

	errorHandler = handler
end

return wrap( errorHandler )
