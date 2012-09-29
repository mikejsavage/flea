local HandlersDir = "pages"
local AllMethods = {
	get = true,
	head = true,
	post = true,
	put = true,
	delete = true,
}

local Routes = { fragments = { }, patterns = { } }
local NamedRoutes = { }

local function containsCaptures( str )
	for pos in str:gmatch( "()%(" ) do
		if str:sub( pos - 1, pos - 1 ) ~= "%" then
			return true
		end
	end

	return false
end

-- escapes special characters outside captures
-- eg escapeNonCaptures( "+(%a+)" ) = "%+(%a+)"
-- this is likely to break if the captures contain %)
local function escapeNonCaptures( str )
	str = str .. "()"

	str = str:gsub( "(.-)(%b())", function( text, capture )
		return text:gsub( "[.*+-?$^%%%[%]]", "%%%1" ) .. capture
	end )

	return str:sub( 1, -3 )
end

local function patternToFormat( str )
	return str:gsub( "%b()", "%%s" )
end

local function addRoute( uri, methods, options )
	options = options or { }

	local route = Routes

	for fragment in uri:gmatch( "[^/]+" ) do
		if containsCaptures( fragment ) then
			table.insert( route.patterns, {
				pattern = "^%s$" % escapeNonCaptures( fragment ),
				fragments = { },
				patterns = { },
			} )

			route = route.patterns[ #route.patterns ]
		else
			fragment = fragment:gsub( "%%%(", "(" )

			if not route.fragments[ fragment ] then
				route.fragments[ fragment ] = {
					fragments = { },
					patterns = { },
				}
			end

			route = route.fragments[ fragment ]
		end
	end

	route.uri = uri
	route.methods = methods
	route.pre = options.pre
	route.post = options.post
	route.stateful = options.stateful

	if options.stateful then
		route.states = { }

		for method in pairs( flea.production and methods or AllMethods ) do
			route.states[ method ] = { }
		end
	end

	if options.name then
		assert( not NamedRoutes[ options.name ], "already a route named `%s'" % options.name )

		NamedRoutes[ options.name ] = patternToFormat( uri )
	end
end

local function matchRoute( uri )
	local route = Routes
	local args = { }

	for fragment in uri:gmatch( "[^/]+" ) do
		if route.fragments[ fragment ] then
			route = route.fragments[ fragment ]
		else
			local found = false

			for _, pattern in ipairs( route.patterns ) do
				local matches = { fragment:match( pattern.pattern ) }

				if matches[ 1 ] then
					route = pattern
					found = true

					for _, match in ipairs( matches ) do
						table.insert( args, match )
					end

					break
				end
			end

			if not found then
				return nil
			end
		end
	end

	return route, args
end

function flea.route( uri, handler, options )
	enforce( uri, "uri", "string" )
	enforce( handler, "handler", "string" )
	enforce( options, "options", "table", "nil" )

	if options then
		enforce( options.name, "options.name", "string", "nil" )
		enforce( options.pre, "options.pre", "function", "nil" )
		enforce( options.post, "options.post", "function", "nil" )
		enforce( options.stateful, "options.stateful", "boolean", "nil" )
	end

	local handlerPath = "%s/%s.lua" % { HandlersDir, handler }

	if flea.production then
		addRoute( uri, assert( dofile( handlerPath ) ), options )
	else
		addRoute( uri, setmetatable( { }, {
			__index = function( self, method )
				local script = assert( dofile( handlerPath ) )

				if script[ method ] then
					return function( ... )
						return script[ method ]( ... )
					end
				else
					return nil
				end
			end,
		} ), options )
	end
end

function flea.routes( routes, options )
	enforce( routes, "routes", "table" )
	enforce( options, "options", "table" )

	if options then
		enforce( options.pre, "options.pre", "function", "nil" )
		enforce( options.post, "options.post", "function", "nil" )
		enforce( options.stateful, "options.stateful", "boolean", "nil" )
	end

	for _, route in ipairs( routes ) do
		local routeOptions = setmetatable( route, { __index = options } )

		flea.route( route.uri, route.handler, routeOptions )
	end
end

function flea.url( route, ... )
	enforce( route, "route", "string" )

	assert( NamedRoutes[ route ], "no route named `%s'" % route )

	return NamedRoutes[ name ]:format( ... )
end

return {
	match = matchRoute,
}
