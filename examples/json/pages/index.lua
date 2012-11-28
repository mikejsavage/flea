return {
	json = function( request )
		request:write( flea.encode( request.data ) )
	end,
}
