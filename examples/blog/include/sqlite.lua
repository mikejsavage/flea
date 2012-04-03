require( "sqlite3" )

local StatementCache = { }

local function newDB( file )
	local db = sqlite3.open( file )

	getmetatable( db ).__call = function( self, query, ... )
		if not StatementCache[ query ] then
			StatementCache[ query ] = assert( db:prepare( query ) )
		end

		local statement = StatementCache[ query ]

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
