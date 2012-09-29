local serialize = require( "flea.serialize" )

local SessionIDBytes = 16 -- 64bit session keys

local function sessionPath( id )
	return "/tmp/flea_%s" % id
end

local function idInUse( id )
	return io.readable( sessionPath( id ) )
end

local function genSessionID()
	return flea.randomBytes( SessionIDBytes ):gsub( ".", function( byte )
		return "%x" % byte:byte( 1, 1 )
	end )
end

local function newSessionID()
	local id

	repeat
		id = genSessionID()
	until not idInUse( id )

	return id
end

local function loadSession( id )
	if not id then
		return nil
	end

	local fn = loadfile( sessionPath( id ) )

	if not fn then
		return nil
	end
	
	setfenv( fn, { } )

	local session = fn()

	return type( session ) == "table" and session or nil
end

local function getSession( request )
	local id = request.cookies.sessionID

	if not id then
		local newID = newSessionID()

		request:setCookie( "sessionID", newID, { httponly = true } )

		return { }, newID
	end

	return ( loadSession( id ) or { } ), id
end

local EmptySession = serialize( { } )
local function saveSession( request )
	local session, id = request.session()

	if not id then
		return
	end

	local serialized = assert( serialize( session ) )
	local path = sessionPath( id )

	if serialized == EmptySession then
		os.remove( path )
	else
		local file = assert( io.open( path, "w" ) )

		file:write( serialized )
		file:close()
	end
end

function flea.setSessionIDGenerator( generator )
	assert( type( generator ) == "function", "argument `generator' must be a function" )
	
	genSessionID = generator
end

function flea.setSessionLoader( loader )
	assert( type( store ) == "function", "argument `loader' must be a function" )

	loadSession = loader
end

function flea.setSessionInUse( inUse )
	assert( type( inUse ) == "function", "argument `inUse' must be a function" )

	idInUse = inUse
end

function flea.setSessionStore( store )
	assert( type( store ) == "function", "argument `store' must be a function" )

	saveSession = store
end

return {
	get = wrap( getSession ),
	save = wrap( saveSession ),
}
