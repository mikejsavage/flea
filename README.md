flea
====

A minimal web framework for a minimal language.


Hello world!
-----------

Mandatory hello world example:

app.lua

	require( "flea" )

	flea.route( "(.*)", "index" )
	flea.run()

pages/index.lua

	return {
		get = function( request, name )
			if name == "" then
				name = "world"
			end

			request:write( "Hello %s! % name )
		end,
	}


Requirements
------------

lua 5.1
libevent 2
