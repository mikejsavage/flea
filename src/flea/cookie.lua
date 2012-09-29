local function parseCookies( cookieString )
	if not cookieString then
		return { }
	end

	cookieString = cookieString .. ";"

	local cookies = { }

	for key, value in cookieString:gmatch( "%s*(.-)=(.-)%s*;" ) do
		cookies[ key ] = value
	end

	return cookies
end

local function setCookie( request, name, value, options )
	local cookie = "%s=%s" % { name, value }

	local function checkOption( option )
		if options[ option ] then
			cookie = cookie .. "; %s=%s" % { option, options[ option ] }
		end
	end

	local function checkOptionBool( option )
		if options[ option ] then
			cookie = cookie .. "; %s" % option
		end
	end

	if options then
		if options.expires then
			cookie = ( "%s; expires=%s" ):format(
				cookie,
				os.date( "!%a, %d-%b-%Y %H:%M:%S GMT", options.expires )
			)
		elseif options.expiresIn then
			cookie = ( "%s; expires=%s" ):format(
				cookie,
				os.date( "!%a, %d-%b-%Y %H:%M:%S GMT",
					os.time() + options.expiresIn
				)
			)
		end

		checkOption( "path" )
		checkOption( "domain" )

		checkOptionBool( "secure" )
		checkOptionBool( "httponly" )
	end

	request:addHeader( "Set-Cookie", cookie )

	return value
end

return {
	parse = parseCookies,
	set = setCookie,
}
