return {
	get = function( request, name )
		local visits

		if request.cookies.counter then
			visits = request:setCookie( "counter", request.cookies.counter + 1, { expiresIn = 3600 } )
		else
			visits = request:setCookie( "counter", 1, { expiresIn = 3600 } )
		end

		if request.session.visits then
			request.session.visits = request.session.visits + 1
		else
			request.session.visits = 1
		end

		request:render( "hello", name or "you", visits, request.session.visits )
	end,
}
