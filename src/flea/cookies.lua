local symmetric = require( "symmetric" )

local secret = require( "flea.secret" )

local _M = { }

function _M.make( name, value, expires, options )
	local cookie = name .. "=" .. symmetric.encrypt( value, secret ):tohex()

	local function check_option( option )
		if options[ option ] then
			cookie = cookie .. "; %s=%s" % { option, options[ option ] }
		end
	end

	local function check_option_bool( option )
		if options[ option ] then
			cookie = cookie .. "; " .. option
		end
	end

	local expires_date = os.date( "!%a, %d-%b-%Y %H:%M:%S GMT", expires )
	cookie = cookie .. "; expires=" .. expires_date

	if options then
		if options.httponly == nil then
			options.httponly = true
		end

		check_option( "path" )
		check_option( "domain" )

		check_option_bool( "secure" )
		check_option_bool( "httponly" )
	end

	return cookie
end

function _M.parse( str )
	local cookies = { }

	for k, v in ( ( str or "" ) .. ";" ):gmatch( "%s*(.-)=(.-)%s*;" ) do
		local raw = v:fromhex()

		if raw then
			cookies[ k ] = symmetric.decrypt( raw, secret )
		end
	end

	return cookies
end

return _M
