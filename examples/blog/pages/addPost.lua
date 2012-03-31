return {
	get = function( request )
		request:render( "newPost" )
	end,

	post = function( request )
		if request.post.submitPost then
			local form = {
				title = request.post.title:htmlDecode(),
				body = request.post.body:htmlDecode(),
				postedAt = os.time(),
			}

			DB( "INSERT INTO posts ( title, body, postedAt ) VALUES ( ?, ?, ? )", form.title, form.body, form.postedAt )

			local id = DB( "SELECT id FROM posts WHERE title = ? AND body = ? AND postedAt = ?", form.title, form.body, form.postedAt )()

			return request:redirect( "/%d" % id )
		end
	end,
}
