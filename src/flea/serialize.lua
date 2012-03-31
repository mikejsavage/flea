-- can't handle cycles, only works on strings/numbers/bools/tables

local function formatKey( key )
	if type( key ) == "string" then
		return "[ %q ]" % key
	end

	return "[ %s ]" % tostring( key )
end

local function serializeObject( obj )
	local t = type( obj )

	if t == "number" or t == "boolean" then
		return tostring( obj )
	end

	if t == "string" then
		return "%q" % obj
	end

	if t == "table" then
		local output = "{ "

		for k, v in pairs( obj ) do
			output = output .. "%s = %s, " % { formatKey( k ), serializeObject( v ) }
		end

		return output .. "}"
	end

	error( "I don't know how to serialize type " .. t )
end

local function serialize( obj )
	if not obj then
		return "return { }"
	end

	return "return " .. serializeObject( obj )
end

return serialize
