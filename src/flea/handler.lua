local templates = require( "flea.template" )
local routes = require( "flea.routes" )
local mime = require( "flea.mime" )
local cookie = require( "flea.cookie" )
local session = require( "flea.session" )
local events = require( "flea.events" )
local json = require( "flea.json" )

local function lazyTable( init, arr )
	return setmetatable( { }, {
		__index = function( self, key )
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

local function requestAddMethods( request, uri, stateful )
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
		__index = function( self, key )
			checkSession()

			return sess.keys[ key ]
		end,

		__newindex = function( self, key, value )
			checkSession()

			sess.keys[ key ] = value
		end,

		__call = function()
			return sess.keys
		end,
	} )

	mt.getSessionID = function()
		checkSession()

		return sess.id
	end

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

	mt.page = function()
		error( "Can't call :page in a stateless handler" )
	end

	mt.page = function()
		error( "Can't call :wait in a stateless handler" )
	end

	if request.method == "head" then
		mt.method = "get"
		mt.write = function() end
	elseif request.method == "post" and mt.headers[ "Content-Type" ] == "application/json" then
		mt.method = "json"

		local err
		mt.data, err = json.decode( request:postData() )

		if not mt.data then
			return false, err
		end
	end

	return true
end

local function requestAddStateful( request, states, id )
	local mt = getmetatable( request )

	mt.page = function( self, code, reason )
		self:send( code or 200, reason or "OK" )

		return coroutine.yield()
	end

	mt.wait = function( self, event )
		events.listen( event, states, id )

		return coroutine.yield()
	end
end

local function handleRequest( request, uri )
	-- try to serve static file first
	local staticPath = uri.path:match( "^/(static/.+)" )

	if staticPath then
		local file = io.open( staticPath )

		if file then
			request:addHeader( "Content-Type", mime.type( staticPath ) )
			request:sendFile( file )

			request:send( 200, "OK" )

			return true
		end

		request:send( 404, "Not Found" )

		return true
	end

	local route, args = routes.match( uri.path )
	local code, reason = 404, "Not Found"
	local doRespond = true

	if route then
		local newCode
		local newReason

		local ok, err = requestAddMethods( request, uri, route.stateful )

		if not ok then
			return false, err
		end

		if route.methods[ request.method ] then
			if route.stateful then
				local id = request.getSessionID()
				local states = route.states[ request.method ]

				if not states[ id ] then
					states[ id ] = coroutine.create( route.methods[ request.method ] )
				end

				requestAddStateful( request, states, id )

				local ok
				ok, newCode, newReason = coroutine.resume( states[ id ], request, unpack( args ) )

				if not ok then
					states[ id ] = nil

					return false, err
				end

				if coroutine.status( states[ id ] ) == "dead" then
					states[ id ] = nil
				else
					doRespond = false
				end
			else
				-- newCode, newReason = route.methods[ request.method ]( request, unpack( args ) )
				local ok, err
				ok, err, newCode, newReason = pcall( route.methods[ request.method ], request, unpack( args ) )

				if not ok then
					return false, err
				end
			end
		end

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

local function handleClose()
end

return {
	request = handleRequest,
	close = handleClose,
}
