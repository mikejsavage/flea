function printf( form, ... )
	print( form:format( ... ) )
end

getmetatable( "" ).__mod = function( self, form )
	if type( form ) == "table" then
		return self:format( unpack( form ) )
	end

	return self:format( form )
end

function string.plural( count, plur, sing )
	return count == 1 and ( sing or "" ) or ( plur or "s" )
end

function string.htmlEscape( self )
	return self:gsub( "&", "&amp;" ):gsub( "<", "&lt;" ):gsub( ">", "&gt;" )
end

function string.htmlDecode( self )
	return self:gsub( "%+", " " ):gsub( "%%(%x%x)", function( charCode )
		return string.char( tonumber( charCode, 16 ) )
	end ):gsub( "\r\n", "\n" )
end

function string.trim( self )
	return self:match( "^%s*(.-)%s*$" )
end

function math.commas( num )
	num = tonumber( num )

	local out = ""

	while num > 1000 do
		out = ( ",%03d%s" ):format( num % 1000, out )

		num = math.floor( num / 1000 )
	end

	return tostring( num ) .. out
end

function io.readable( path )
	local file, err = io.open( path, "r" )

	if not file then
		return false, err
	end

	io.close( file )

	return true
end

function io.contents( path )
	local file, err = io.open( path, "r" )

	if not file then
		return nil, err
	end

	local content = file:read( "*all" )

	file:close()

	return content
end

function os.utctime()
	return os.time( os.date( "!*t" ) )
end

function math.round( num )
	return math.floor( num + 0.5 )
end

-- essentially returns a function pointer to f
function wrap( f )
	return function( ... )
		return f( ... )
	end
end

function enforce( var, name, ... )
	local acceptable = { ... }
	local ok = false

	for _, accept in ipairs( acceptable ) do
		if type( var ) == accept then
			ok = true

			break
		end
	end

	if not ok then
		error( "argument `%s' to %s should be of type %s (got %s)" % { name, debug.getinfo( 2, "n" ).name, table.concat( acceptable, " or " ), type( var ) }, 3 )
	end
end
