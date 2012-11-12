local cjson = require( "cjson.safe" ).new()

function flea.encode( data )
	enforce( data, "data", "table" )

	return cjson.encode( data )
end

function flea.decode( data )
	enforce( data, "data", "string" )

	return cjson.decode( data )
end

return {
	encode = cjson.encode,
	decode = cjson.decode,
}
