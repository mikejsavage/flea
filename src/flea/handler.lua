local templates = require( "flea.template" )
local routes = require( "flea.routes" )
local mime = require( "flea.mime" )
local cookie = require( "flea.cookie" )
local session = require( "flea.session" )

local function lazyTable( init, arr )
	return setmetatable( { }, {
		__index = function( _, key )
			if not arr.keys then
				arr.keys = init()
			end

			return arr.keys[ key ]
		end,

		__call = function()
			if not arr.keys then
				arr.keys = init()
			end

			return pairs( arr.keys )
		end,
	} )
end

local function requestAddMethods( request, uri )
	local mt = getmetatable( request )

	local get = { }
	local post = { }
	local cookies = { }
	local sess = { }

	local function initGet()
		return uri.query and flea.parseQuery( uri.query ) or { }
	end

	local function initPost()
		return flea.parseQuery( request:postData() )
	end

	local function initCookies()
		return cookie.parse( request:getHeader( "Cookie" ) )
	end

	local function checkSession()
		if not sess.keys then
			local keys, id = session.get( request )

			sess.keys = keys
			sess.id = id
		end
	end

	mt.get = lazyTable( initGet, get )
	mt.post = lazyTable( initPost, post )
	mt.cookies = lazyTable( initCookies, cookies )

	mt.session = setmetatable( { }, {
		__index = function( _, key )
			checkSession()

			return sess.keys[ key ]
		end,

		__newindex = function( _, key, value )
			checkSession()

			sess.keys[ key ] = value
		end,

		__call = function()
			return sess.keys, sess.id
		end,
	} )

	mt.headers = setmetatable( { }, {
		__index = function( self, key )
			local header = request:getHeader( key ) or false

			self[ key ] = header

			return header
		end,
	} )

	mt.render = function( self, template, ... )
		local fn = templates[ template ]
		local env = setmetatable( { request = self }, {
			__index = _G,
			__newindex = _G,
		} )

		setfenv( fn, env )

		fn( ... )
	end

	mt.redirect = function( self, uri )
		self:addHeader( "Location", uri )

		return 302, "Found"
	end

	mt.setCookie = cookie.set

	if request.method == "head" then
		mt.method = "get"
		mt.write = function() end
	end
end

local function handleRequest( request, uri )
	-- try to serve static file first
	local staticPath = uri.path:match( "^/(static/.*)" )

	if staticPath then
		local file = io.open( staticPath )

		if file then
			request:addHeader( "Content-Type", mime.type( staticPath ) )
			request:sendFile( file )

			return 200, "OK"
		end

		return 404, "Not Found"
	end

	requestAddMethods( request, uri )

	local handler, args = routes.match( uri.path, request.method )
	local code, reason = 404, "Not Found"
	local doRespond = true

	if handler then
		local newCode, newReason = handler( request, unpack( args ) )

		if newCode then
			assert( newReason, "specified response code but not reason" )

			code, reason = newCode, reason
		else
			code, reason = 200, "OK"
		end

		session.save( request )
	end

	if doRespond then
		request:send( code, reason )
	end

	return true
end

return {
	request = handleRequest,
	close = handleClose,
}
