return {
	get = function( request )
		for id, title, body, postedAt in DB( "SELECT id, title, body, postedAt FROM posts ORDER BY postedAt DESC" ) do
			request:render( "post", id, title, body, postedAt )
		end
	end,
}
