return {
	get = function( request )
		local count = 0

		while true do
			count = count + 1

			request:render( "index", count )
			request = request:page()
		end
	end,
}
