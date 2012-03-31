#! /usr/bin/lua

-- this parses nginx's mime.types into a lua table

local file = io.open( "mime.types", "r" )
local mime = { }

for line in file:lines() do
	local type, exts = line:match( "(%S+)%s*(.+);" )

	if type then
		for ext in exts:gmatch( "%S+" ) do
			table.insert( mime, { ext, type } )
		end
	end
end

print( "local MimeTypes = {" )

for _, m in ipairs( mime ) do
	print( ( "\t[ %q ] = %q," ):format( unpack( m ) ) )
end

print( "}" )
