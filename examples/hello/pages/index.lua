return {
	get = function( request, name )
		local visits = request:setCookie( "counter", ( request.cookies.counter or 0 ) + 1, { expiresIn = 3600 } )
		request.session.visits = ( request.session.visits or 0 ) + 1

		request:render( "hello", name or "you", visits, request.session.visits )
	end,
}
