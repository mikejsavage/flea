require( "sqlite3" )

local function newDB( file )
	local db = sqlite3.open( file )
	
	getmetatable( db ).__call = function( self, query, ... )
		local statement = assert( db:prepare( query ) )

		if ... then
			statement:bind( ... )
		end

		statement:cols()() -- it does not work without this line for whatever reason

		return statement:cols()
	end

	return db
end

return {
	new = newDB,
}
