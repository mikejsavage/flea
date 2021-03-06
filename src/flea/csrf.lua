local arc4 = require( "arc4random" )

local time = require( "flea.time" )

local _M = { }

function _M.token_raw( request )
	local token = request.cookies.csrf or arc4.buf( 16 ):tohex()
	request:set_cookie( "csrf", token, time.hours( 2 ), { path = "/" } )

	return token
end

function _M.token( request, html )
	local token = _M.token_raw( request )

	return html.input( { name = "csrf", type = "hidden", value = token } )
end

function _M.validate( request )
	if request.post.csrf and request.post.csrf == request.cookies.csrf then
		return true
	end

	request:forbidden()
	return false
end

return _M
