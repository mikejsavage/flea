-- a bit like strict.lua but prints warnings instead of killing the program

local mt = getmetatable( _G )

if not mt then
	mt = { }
	
	setmetatable( _G, mt )
end

mt.__index = function( self, key )
	print( "accessing undefined variable: " .. key )
end

mt.__newindex = function( self, key, value )
	print( "setting undefined variable: " .. key )

	rawset( self, key, value )
end
