local fcgi = require( "fcgi" )
local json = require( "cjson.safe" )

local cookies = require( "flea.cookies" )
local template = require( "flea.template" )
local time = require( "flea.time" )

local _M = { }

local function request_noop_write( request )
	local function noop() end
	request.write = noop
	request.header = noop
end

local function request_add_methods( request )
	request.write = function( self, str )
		table.insert( self.body, str )
	end

	request.clear = function( self )
		self.body = { }
	end

	request.html = function( self, f )
		self:write( template.render( f ) )
	end

	request.set_cookie = function( self, name, value, expires_in, options )
		self:header( "Set-Cookie", cookies.make( name, value, os.time() + expires_in, options ) )
	end

	request.delete_cookie = function( self, name )
		self:set_cookie( name, "", -time.days( 365 ) )
	end

	request.header = function( self, header, value )
		if header:find( "[\r\n]" ) or value:find( "[\r\n]" ) then
			self:bad_request()
		else
			table.insert( self.new_headers, header .. ": " .. value )
		end
	end

	request.redirect = function( self, url )
		self:header( "Location", url )
		self:clear()
		self:write( "we moved bro" )

		request_noop_write( self )

		return { 302, "Found" }
	end

	request.bad_request = function( self )
		self:clear()
		self:write( "<h1>400 Bad Request</h1>" )

		request_noop_write( self )

		self.status = { 400, "Bad Request" }
	end

	request.not_authorized = function( self )
		self.status = { 401, "Not Authorized" }
	end

	request.forbidden = function( self )
		self:clear()
		self:write( "<h1>403 Forbidden</h1>" )

		request_noop_write( self )

		self.status = { 403, "Forbidden" }
	end

	request.not_found = function( self )
		self:clear()
		self:write( "<h1>404 Not Found</h1>" )

		request_noop_write( self )

		self.status = { 404, "Not Found" }
	end
end

local function parse_query( query )
	local vars = { }

	for assignment in query:gmatch( "([^&]+)" ) do
		local key, value = assignment:match( "^(.-)=(.-)$" )

		if key then
			vars[ key ] = value:url_decode()
		else
			vars[ assignment ] = true
		end
	end

	return vars
end

local function lazy_table( populate )
	local t = { }

	local mt = {
		__index = function( self, key )
			if not t.keys then
				t.keys = populate()
			end

			return t.keys[ key ]
		end,
	}

	return setmetatable( { }, mt )
end

local function request_add_tables( request )
	request.get = lazy_table( function()
		return parse_query( fcgi.getenv( "QUERY_STRING" ) or "" )
	end )

	request.post = lazy_table( function()
		local content_type = fcgi.getenv( "CONTENT_TYPE" )
		local post = fcgi.post()

		if content_type == "application/x-www-form-urlencoded" then
			return parse_query( post )
		elseif content_type == "application/json" then
			return json.parse( post ) or { } -- TODO: turn this into a 400 somehow
		else
			return { data = post }
		end
	end )

	request.cookies = lazy_table( function()
		return cookies.parse( fcgi.getenv( "HTTP_COOKIE" ) or "" )
	end )

	local headers_seen = { }
	local headers_mt = {
		__index = function( self, key )
			if headers_seen[ key ] then
				return nil
			end

			local header = fcgi.getenv( "HTTP_" .. key:upper():gsub( "%-", "_" ) )

			headers_seen[ key ] = true
			self[ key ] = header
			
			return header
		end,
	}

	request.headers = setmetatable( { }, headers_mt )
end

function _M.new( method )
	local request = {
		method = method,
		body = { },
		new_headers = { },
	}

	request_add_tables( request )
	request_add_methods( request )
	
	return request
end

return _M
