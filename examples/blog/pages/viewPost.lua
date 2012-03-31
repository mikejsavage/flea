return {
	get = function( request, id )
		local title, body, postedAt = DB( "SELECT title, body, postedAt FROM posts WHERE id = ?", id )()

		if title then
			request:render( "post", id, title, body, postedAt )
		else
			return request:redirect( "/" )
		end
	end,
}
