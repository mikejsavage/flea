local print = print
local getmetatable = getmetatable
local getinfo = debug.getinfo
local traceback = debug.traceback
local write = io.write

local function hook( t, k )
	local oldT = t[ k ]

	t[ k ] = setmetatable( { }, {
		__index = function( self, key )
			local value = oldT[ key ]

			if type( value ) ~= "table" or not getmetatable( value ).__index then
				local info = getinfo( 2, "nS" )

				write( "global access: " .. k .. "." .. key )
				print( traceback( "", 2 ) )
			end

			return oldT[ key ]
		end,

		__newindex = function( self, key, value )
			oldT[ key ] = value
		end,
	} ) 
end

hook( _G, "os" )
hook( _G, "io" )
hook( _G, "math" )
hook( _G, "table" )
hook( _G, "string" )
hook( _G, "coroutine" )
hook( _G, "_G" )
