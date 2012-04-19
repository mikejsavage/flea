-- addRoute( "hello", f )
-- addRoute( "hello/(%s+)", g )
--
-- will produce a routes table like
--
-- Routes = {
-- 	fragments = {
-- 		hello = {
-- 			handler = f
-- 			fragments = { }
-- 			patterns = {
-- 				{
-- 					pattern = "(%s+)"
-- 					handler = g
-- 					fragments = { }
-- 					patterns = { }
-- 				}
-- 			}
-- 		}
-- 	}
-- 	patterns = { }
-- }
--
-- this may be overengineered but it does make handler lookups SILLY fast

local HandlersDir = "pages"

local Routes = { fragments = { }, patterns = { } }

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

local function addRoute( uri, handler )
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

	route.handler = handler
end

local function matchRoute( uri, method )
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

	return route.handler[ method ], args
end

function flea.route( uri, handler )
	assert( type( "uri" ) == "string", "first argument `uri' must be a string" )
	assert( type( "handler" ) == "string", "second argument `handler' must be a string" )

	local handlerPath = "%s/%s.lua" % { HandlersDir, handler }

	if flea.production then
		addRoute( uri, assert( dofile( handlerPath ) ) )
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
		} ) )
	end
end

return {
	match = matchRoute,
}
