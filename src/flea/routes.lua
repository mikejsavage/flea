local _M = { methods = { } }

local routes = { fragments = { }, patterns = { }, methods = { }, allow = "" }

local function contains_captures( str )
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
local function escape_non_captures( str )
	str = str .. "()"

	str = str:gsub( "(.-)(%b())", function( text, capture )
		return text:gsub( "[.*+-?$^%%%[%]]", "%%%1" ) .. capture
	end )

	return str:sub( 1, -3 )
end

local function pattern_to_format_string( str )
	return str:gsub( "%b()", "%%s" )
end

local function add_route( method, url, callback )
	local route = routes

	for fragment in url:gmatch( "[^/]+" ) do
		if contains_captures( fragment ) then
			local pattern = "^" .. escape_non_captures( fragment ) .. "$"
			local found = false

			for _, existing in ipairs( route.patterns ) do
				if existing.pattern == pattern then
					route = existing
					found = true
				end
			end

			if not found then
				local child = {
					pattern = "^" .. escape_non_captures( fragment ) .. "$",
					fragments = { },
					patterns = { },
					allow = "",
				}

				table.insert( route.patterns, child )
				route = child
			end
		else
			fragment = fragment:gsub( "%%%(", "(" )

			if not route.fragments[ fragment ] then
				route.fragments[ fragment ] = {
					fragments = { },
					patterns = { },
					allow = "",
				}
			end

			route = route.fragments[ fragment ]
		end
	end

	if not route.methods then
		route.methods = { }
	end

	route.methods[ method ] = callback
	route.allow = route.allow .. " " .. method:upper()
end

function _M.match( url )
	local route = routes
	local args = { }

	for fragment in url:gmatch( "[^/]+" ) do
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
				return
			end
		end
	end

	return route, args
end

local methods = { "get", "post", "put", "delete" }
for _, method in ipairs( methods ) do
	_M.methods[ method ] = function( url, handler )
		add_route( method, url, handler )
	end
end

return _M
