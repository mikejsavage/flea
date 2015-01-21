local arc4random = require( "arc4random" )

local file = io.open( config.secret_path )

if file then
	local secret = assert( file:read( "*all" ) )
	file:close()

	return secret
end

local buf = arc4random.buf( 32 )
io.writeFile( config.secret_path, buf )

return buf
