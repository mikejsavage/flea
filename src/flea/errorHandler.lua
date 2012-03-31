-- sets the default error handler

flea.setErrorHandler( function( request, error )
	request:clear()
	request:clearHeaders()

	request:addHeader( "Content-Type", "text/plain" )
	request:write( debug.traceback( error ) )
end )
