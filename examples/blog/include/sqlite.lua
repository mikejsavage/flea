require( "lsqlite3" )

local function newDB( file )
	local db = sqlite3.open( file )
	local statementCache = { }

	getmetatable( db ).__call = function( self, query, ... )
		if not statementCache[ query ] then
			statementCache[ query ] = assert( ( db:prepare( query ) ), db:errmsg() )
		end

		local statement = statementCache[ query ]

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
