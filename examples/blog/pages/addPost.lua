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

			DB( "INSERT INTO posts ( title, body, postedAt ) VALUES ( ?, ?, ? )", form.title, form.body, form.postedAt )()

			return request:redirect( "/%d" % DB:last_insert_rowid() )
		end
	end,
}
