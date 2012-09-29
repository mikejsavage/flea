return {
	get = function( request )
		request:wait( "click" )
		request:page()
	end,
}
