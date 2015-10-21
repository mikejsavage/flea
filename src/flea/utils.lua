getmetatable( "" ).__mod = function( self, form )
	if type( form ) == "table" then
		return self:format( table.unpack( form ) )
	end

	return self:format( form )
end

function io.readFile( path )
	local file = assert( io.open( path, "r" ) )
	local contents = assert( file:read( "*a" ) )

	assert( file:close() )

	return contents
end

function io.writeFile( path, contents )
	local file = assert( io.open( path, "w" ) )
	assert( file:write( contents ) )
	assert( file:close() )
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

function string.trim( self )
	return self:match( "^%s*(.-)%s*$" )
end

function string.tohex( self )
	return ( self:gsub( "(.)", function( c )
		return ( "%02x" ):format( c:byte() )
	end ) )
end

function string.fromhex( self )
	if self:match( "^%x*$" ) and self:len() % 2 == 0 then
		return self:gsub( "(%x%x)", function( hex )
			return string.char( tonumber( hex, 16 ) )
		end )
	end
end

function string.html_escape( self )
	return ( self:gsub( "&", "&amp;" ):gsub( "<", "&lt;" ):gsub( ">", "&gt;" ) )
end

function string.url_escape( self )
	return ( self:gsub( "\"", "%%22" ) )
end

function string.url_encode( self )
	return ( self:gsub( "([^%w%-%_%.])", function( char )
		return ( "%%%02X" ):format( string.byte( char ) )
	end ) )
end

function string.url_decode( self )
	return ( self:gsub( "%+", " " ):gsub( "%%(%x%x)", function( hex )
		return string.char( tonumber( hex, 16 ) )
	end ) )
end

function string.commas( num )
	num = tonumber( num )

	local out = ""

	while num > 1000 do
		out = ( ",%03d%s" ):format( num % 1000, out )

		num = math.floor( num / 1000 )
	end

	return tostring( num ) .. out
end

function math.round( num )
	return math.floor( num + 0.5 )
end

function os.utctime()
	return os.time( os.date( "!*t" ) )
end

table.unpack = table.unpack or unpack
