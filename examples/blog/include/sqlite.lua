require( "lsqlite3" )

local StatementCache = { }

local function newDB( file )
	local db = sqlite3.open( file )

	getmetatable( db ).__call = function( self, query, ... )
		if not StatementCache[ query ] then
			StatementCache[ query ] = assert( ( db:prepare( query ) ), db:errmsg() )
		end

		local statement = StatementCache[ query ]

		if ... then
			statement:bind_values( ... )
		end

		local iter = statement:urows()

		return function()
			return iter( statement )
		end
	end

	return db
end

return {
	new = newDB,
}
